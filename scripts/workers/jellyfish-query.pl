#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;
use feature 'say';
use autodie;
use File::Basename 'basename';
use File::Find::Rule;
use File::Path 'mkpath';
use File::Spec::Functions;
use Getopt::Long 'GetOptions';
use List::MoreUtils 'uniq';
use Number::Format;
use Pod::Usage;
use Readonly;
use Statistics::Descriptive::Discrete;
use Time::HiRes qw(gettimeofday tv_interval);
use Time::Interval 'parseInterval';
use File::Temp 'tempfile';

my $in_file     = '';
my $kmer_size   = 20;
my $suffix_file = '';
my $out_dir     = '';
my $verbose     = 0;
my $jellyfish   = '/usr/local/bin/jellyfish';
my ($help, $man_page);
GetOptions(
    'i|in=s'        => \$in_file,
    'o|out=s'       => \$out_dir,
    'j|jellyfish:s' => \$jellyfish,
    'k|kmer:i'      => \$kmer_size,
    's|suffix=s'    => \$suffix_file,
    'v|verbose'     => \$verbose,
    'help'          => \$help,
    'man'           => \$man_page,
) or pod2usage(2);

if ($help || $man_page) {
    pod2usage({
        -exitval => 0,
        -verbose => $man_page ? 2 : 1
    });
};

unless (-e $in_file && -s _) {
    pod2usage("Bad input file ($in_file)");
}

unless (-e $suffix_file && -s _) {
    pod2usage("Bad suffix file ($suffix_file)");
}

unless (-e $jellyfish && -x _) {
    pod2usage("Bad Jellyfish binary ($jellyfish)");
}

my ($min_kmer, $max_kmer) = (0, 32);
unless ($kmer_size > $min_kmer && $kmer_size < $max_kmer) {
    pod2usage("Kmer size ($kmer_size) must be between $min_kmer and $max_kmer");
}

my $t0 = [gettimeofday];

printf STDERR "Processing %s -> %s\n", 
    basename($in_file), basename($suffix_file);

my $base_dir = catdir($out_dir, basename($in_file, '.fa'));

if (!-d $base_dir) {
    mkpath $base_dir;
}

my $out_file = catfile($base_dir, basename($suffix_file, '.jf') . '.mode');

local $/ = '>';
open my $in,  '<', $in_file;
open my $out, '>', $out_file;

my $seq_num = 0;
my @files;
while (my $stanza = <$in>) {
    chomp $stanza;
    next unless $stanza;

    $seq_num++;
    my ($header, @lines) = split "\n", $stanza;

    if ($verbose) {
        printf STDERR "%-70s\r", sprintf("%12d: %s", $seq_num, $header);
    }

    my $seq       = join '', @lines;
    my $kmer_file = kmers($seq, $kmer_size);
    my $jf        = `$jellyfish query -s $kmer_file $suffix_file`;

    my @counts;
    for my $line (split("\n", $jf)) {
        my ($id, $count) = split /\s+/, $line;
        push @counts, $count if $count > 0;
    }
    unlink $kmer_file;

    if (my $mode = mode(\@counts)) {
        print $out join("\t", $header, $mode), "\n";
    }
}

close $in;
close $out;

print STDERR "\n" if $verbose;

my $seconds = int(tv_interval($t0, [gettimeofday]));
my $time    = $seconds > 60
    ? parseInterval(seconds => $seconds, Small => 1)
    : sprintf("%s second%s", $seconds, $seconds == 1 ? '' : 's')
;

my $fmt = Number::Format->new;
printf STDERR "Done, processed %s sequence%s in %s.\n", 
    $fmt->format_number($seq_num), 
    $seq_num == 1 ? '' : 's', 
    $time;
exit 0;

# ----------------------------------------------------
sub kmers {
    my $seq       = shift or return;
    my $kmer_size = shift or return;
    my $len       = length $seq;

    my @kmers; 
    for (my $i = 0; $i + $kmer_size <= $len; $i++) {
        #push @kmers, substr($seq, $i, $kmer_size);
        push @kmers, join("\n", ">$i", substr($seq, $i, $kmer_size));
    }

    #return \@kmers;

    my ($tmp_fh, $tmp_filename) = tempfile();
    print $tmp_fh join "\n", @kmers, '';
    close $tmp_fh;

    return $tmp_filename;
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

=pod

=head1 NAME

jellyfish-query.pl

=head1 SYNOPSIS

  jellyfish-query.pl -i input.fasta -s /path/to/suffix -o /path/to/output 

  Required Arguments:

    -i|--in         The input file in FASTA format
    -s|--suffix     The Jellyfish suffix file
    -o|--out        Directory to write the output

  Options:

    -j|--jellyfish  Path to "jellyfish" binary (default "/usr/local/bin")
    -k|--kmer       Size of the kmers (default "20")
    -v|--verbose    Show progress while processing sequences
    --help          Show brief help and exit
    --man           Show full documentation

=head1 DESCRIPTION

For read in each FASTA input file, run "jellyfish query" to all indexes in 
the "suffix" dir and write each sequence/read's mode to the "out" directory.

=head1 SEE ALSO

Jellyfish

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@cshl.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2014 Ken Youens-Clark

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
