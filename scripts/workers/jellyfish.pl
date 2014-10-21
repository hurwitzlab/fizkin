#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use autodie;
use Data::Dump 'dump';
use File::Basename 'basename';
use File::Find::Rule;
use File::Path 'mkpath';
use File::Spec::Functions;
use List::MoreUtils 'uniq';
use Readonly;
use Statistics::Descriptive::Discrete;
use Time::HiRes qw(gettimeofday tv_interval);
use Time::Interval 'parseInterval';

Readonly my $KMER_SIZE  => 20;
Readonly my $JF         => '/usr/local/bin/jellyfish';
Readonly my $BASE_DIR   => '/Users/kclark/work/pov';
Readonly my $SUFFIX_DIR => catdir($BASE_DIR, 'suffix');
Readonly my $COUNT_DIR  => catdir($BASE_DIR, 'counts');

my @files = @ARGV or die "No input FASTA files\n";
my @suffixes = File::Find::Rule->file()->name('*.jf')->in($SUFFIX_DIR);
printf "Processing %s sequences files against %s suffix files\n", 
    scalar @files, scalar @suffixes;

if (!-d $COUNT_DIR) {
    mkpath $COUNT_DIR;
}

my $t0         = [gettimeofday];
my $total_seqs = 0;
my $num_files  = 0;
for my $file (@files) {
    $num_files++;
    printf "Processing %s\n", basename($file);

    local $/ = '>';
    open my $fh, '<', $file;

    my @times;
    my $seq_num = 0;
    while (my $stanza = <$fh>) {
        chomp $stanza;
        next unless $stanza;

        my ($header, @lines) = split "\n", $stanza;
        my $seq   = join '', @lines;
        my @kmers = kmers($seq) or next;

        printf "%-70s\r", 
            sprintf("%10d: %s (%s kmers)", ++$seq_num, $header, scalar @kmers);

        for my $suffix (@suffixes) {
            my @kmer_copy = @kmers;
            my @counts;
            while (my @group = splice(@kmer_copy, 0, 250)) {
                my $list = join(' ', @group);
                (my $out = `$JF query $suffix $list`) =~ s/\n$//;
                for my $line (split("\n", $out)) {
                    my ($id, $count) = split /\s+/, $line;
                    push @counts, $count if $count > 0;
                }
            }

            next unless @counts;

            if (my $mode = mode(\@counts)) {
                my $out_dir = catdir($COUNT_DIR, basename($file, '.fa'));
                if (!-d $out_dir) {
                    mkpath $out_dir;
                }

                my $out_file = catfile(
                    $out_dir, basename($suffix, '.jf') . '.mode'
                );
                open my $out, '>>', $out_file;
                print $out join("\t", $header, $mode), "\n";

                close $out;
            }
        }
    }

    $total_seqs += $seq_num;

    close $fh;
    print "\n";
    last;
}

my $seconds = int(tv_interval($t0, [gettimeofday]));
my $time    = $seconds > 60
    ? parseInterval(seconds => $seconds, Small => 1)
    : sprintf("%s second%s", $seconds, $seconds == 1 ? '' : 's')
;

printf "Done, processed %s sequences in %s files in %s.\n", 
    $total_seqs, $num_files, $time;

# ----------------------------------------------------
sub kmers {
    my $seq = shift or return;
    my $len = length $seq;

    my @kmers;
    for (my $i = 0; $i + $KMER_SIZE <= $len; $i++) {
        push @kmers, substr($seq, $i, $KMER_SIZE);
    }

    return @kmers;
}

# ----------------------------------------------------
sub mode {
    my $vals = shift;

    return unless ref $vals eq 'ARRAY' && scalar @$vals > 0;

    my $mode = 0;
    if (scalar @$vals == 1) {
        $mode = $vals->[0];
    }
    else {
        my @distinct = uniq(@$vals);

        if (scalar @distinct == 1) {
            $mode = $distinct[0];
        }
        else {
            my $stats = Statistics::Descriptive::Discrete->new;
            $stats->add_data(@$vals);

            my $mean     = int($stats->mean());
            my $two_stds = 2 * (int $stats->standard_deviation());
            my $min      = $mean - $two_stds;
            my $max      = $mean + $two_stds;

            if (my @filtered = grep { $_ >= $min && $_ <= $max } @$vals) {
                my $stats2 = Statistics::Descriptive::Discrete->new;
                $stats2->add_data(@filtered);
                $mode = int($stats2->mode());
            }
        }
    }

    return $mode;
}

# ----------------------------------------------------
