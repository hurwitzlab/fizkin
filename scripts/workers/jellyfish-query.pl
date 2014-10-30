#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;
use feature 'say';
use autodie;
use File::Basename qw(basename fileparse);
use File::Find::Rule;
use File::Path 'mkpath';
use File::Spec::Functions;
use File::Temp 'tempfile';
use Getopt::Long 'GetOptions';
use List::Util 'max';
use List::MoreUtils 'uniq';
use Number::Format;
use Pod::Usage;
use Readonly;
use Statistics::Descriptive::Discrete;
use Time::HiRes qw(gettimeofday tv_interval);
use Time::Interval 'parseInterval';

my $kmer_size   = 20;
my $suffix_file = '';
my $out_dir     = '';
my $verbose     = 0;
my $jellyfish   = '/usr/local/bin/jellyfish';
my $cut         = '/usr/bin/cut';
my ($help, $man_page);
GetOptions(
    'o|out=s'       => \$out_dir,
    's|suffix=s'    => \$suffix_file,
    'j|jellyfish:s' => \$jellyfish,
    'k|kmer:i'      => \$kmer_size,
    'v|verbose'     => \$verbose,
    'cut:s'         => \$cut,
    'help'          => \$help,
    'man'           => \$man_page,
) or pod2usage(2);

if ($help || $man_page) {
    pod2usage({
        -exitval => 0,
        -verbose => $man_page ? 2 : 1
    });
};

my @files = @ARGV or pod2usage('No input files');

unless (-e $suffix_file && -s _) {
    pod2usage("Bad suffix file ($suffix_file)");
}

unless (-e $jellyfish && -x _) {
    pod2usage("Bad Jellyfish binary ($jellyfish)");
}

if ($out_dir) {
    (my $suffix_dir = basename($suffix_file)) =~ s/\.[^.]+$//;
    $out_dir = catdir($out_dir, $suffix_dir);
}
else {
    pod2usage('No output directory');
}

if (!-d $out_dir) {
    mkpath $out_dir;
}

my ($min_kmer, $max_kmer) = (0, 32);
unless ($kmer_size > $min_kmer && $kmer_size < $max_kmer) {
    pod2usage("Kmer size ($kmer_size) must be between $min_kmer and $max_kmer");
}

# ----------------------------------------------------
#
# Set up is done, here's the meat
#
my $t0       = [gettimeofday];
my $file_num = 0;
for my $kmer_file (@files) {
    my ($basename, $path, $suffix) = fileparse($kmer_file, qr/\.[^.]+/);
    printf STDERR "%4d: Processing %s\n", ++$file_num, $basename;

    my $loc_file = catfile($path, $basename . '.loc');

    if (!-e $loc_file) {
        die "Can't find kmer location file ($loc_file)\n";
    }

    my ($tmp_fh, $tmp_file) = tempfile();
    close $tmp_fh;

    #
    # jellyfish query output looks like this
    # AGCAGGTGGAAGGTGAAGGA 5
    # 
    # so split it and take the 2nd field
    #
    `jellyfish query -s $kmer_file $suffix_file|$cut -d ' ' -f 2 > $tmp_file`;

    # 
    # location file tells us read_id and number of kmers, e.g.:
    # GJFGUPM01AMOBV    163
    # 
    open my $jf_fh,  '<', $tmp_file;
    open my $loc_fh, '<', $loc_file;
    open my $out_fh, '>', catfile($out_dir, $basename . '.mode');

    while (my $loc = <$loc_fh>) {
        my ($read_id, $n_kmers) = split /\t/, $loc;
        if (my $mode = mode(take($n_kmers, $jf_fh))) {
            print $out_fh join("\t", $read_id, $mode), "\n";
        }
    }

    close $loc_fh;
    close $out_fh;
    close $jf_fh;
    unlink $tmp_file;
}

print STDERR "\n" if $verbose;

my $seconds = int(tv_interval($t0, [gettimeofday]));
my $time    = $seconds > 60
    ? parseInterval(seconds => $seconds, Small => 1)
    : sprintf("%s second%s", $seconds, $seconds == 1 ? '' : 's')
;

my $fmt = Number::Format->new;
printf STDERR "Done, queried %s kmer file%s to suffix '%s' %s.\n", 
    $fmt->format_number($file_num), 
    $file_num == 1 ? '' : 's', 
    basename($suffix_file),
    $time;
exit 0;

# ----------------------------------------------------
sub take {
    my ($n, $fh) = @_;
    my @return;
    for (my $i = 0; $i < $n; $i++) {
        chomp(my $line = <$fh>);
        push @return, $line;
    }
    @return;
}

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
    my @vals = @_ or return;

    my $mode = 0;
    if (scalar @vals == 1) {
        $mode = shift @vals;
    }
    else {
        my @distinct = uniq(@vals);

        if (scalar @distinct == 1) {
            $mode = shift @distinct;
        }
        else {
            my $stats = Statistics::Descriptive::Discrete->new;
            $stats->add_data(@vals);

            my $mean     = int($stats->mean());
            my $two_stds = 2 * (int $stats->standard_deviation());
            my $min      = $mean - $two_stds;
            my $max      = $mean + $two_stds;

            if (my @filtered = grep { $_ >= $min && $_ <= $max } @vals) {
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

  jellyfish-query.pl -s /path/to/suffix -o /path/to/output kmer.files ...

  Required Arguments:

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
