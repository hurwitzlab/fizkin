#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;
use feature 'say';
use autodie;
use Cwd 'cwd';
use File::Basename qw'basename fileparse';
use File::Find::Rule;
use File::Path 'mkpath';
use File::Spec::Functions;
use File::Temp 'tempfile';
use Getopt::Long 'GetOptions';
use Hurwitz::Utils qw'commify timer_calc take';
use List::MoreUtils 'uniq';
use Pod::Usage;
use Statistics::Descriptive::Discrete;

my $kmer_size  = 20;
my $suffix_dir = '';
my $out_dir    = '';
my $verbose    = 0;
my $jellyfish  = '/usr/local/bin/jellyfish';
my $tmp_dir    = cwd();
my ($help, $man_page);
GetOptions(
    'o|out=s'        => \$out_dir,
    's|suffix_dir=s' => \$suffix_dir,
    'j|jellyfish:s'  => \$jellyfish,
    'k|kmer:i'       => \$kmer_size,
    'v|verbose'      => \$verbose,
    't|tmp_dir:s'    => \$tmp_dir,
    'help'           => \$help,
    'man'            => \$man_page,
) or pod2usage(2);

if ($help || $man_page) {
    pod2usage({
        -exitval => 0,
        -verbose => $man_page ? 2 : 1
    });
};

my @files = @ARGV or pod2usage('No input files');

if (!-d $suffix_dir) {
    pod2usage("Bad suffix dir ($suffix_dir)");
}

unless (-e $jellyfish && -x _) {
    pod2usage("Bad Jellyfish binary ($jellyfish)");
}

if ($out_dir) {
    $out_dir = catdir($out_dir, basename($suffix_dir));
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
my $timer    = timer_calc();
my $file_num = 0;
for my $kmer_file (@files) {
    my ($basename, $path, $suffix) = fileparse($kmer_file, qr/\.[^.]+/);
    printf STDERR "%4d: Processing kmer file '%s'\n", ++$file_num, $basename;

    my $loc_file = catfile($path, $basename . '.loc');

    if (!-e $loc_file) {
        die "Can't find kmer location file ($loc_file)\n";
    }

    my ($tmp_fh, $tmp_file) = tempfile(DIR => $tmp_dir);
    close $tmp_fh;

    #
    # jellyfish query output looks like this
    # AGCAGGTGGAAGGTGAAGGA 5
    # 
    # so split it and take the 2nd field
    #
    system(
        $jellyfish, "query", "-s", "$kmer_file", 
        "-o", "$tmp_file", "$suffix_file"
    ) == 0 
        or die "Couldn't $jellyfish failed: $?";

    # 
    # location file tells us read_id and number of kmers, e.g.:
    # GJFGUPM01AMOBV    163
    # 
    open my $jf_fh,  '<', $tmp_file;
    open my $loc_fh, '<', $loc_file;
    open my $out_fh, '>', catfile($out_dir, $basename . '.mode');

    while (my $loc = <$loc_fh>) {
        chomp($loc);
        my ($read_id, $n_kmers) = split /\t/, $loc;

        my @counts;
        for my $val (take($n_kmers, $jf_fh)) {
            next if !$val;
            my ($kmer, $count) = split /\s+/, $val;
            push @counts, $count if defined $count && $count =~ /^\d+$/;
        }

        if (my $mode = mode(@counts)) {
            print $out_fh join("\t", $read_id, $mode), "\n";
        }
    }

    close $loc_fh;
    close $out_fh;
    close $jf_fh;
    unlink $tmp_file;
}

print STDERR "\n" if $verbose;

printf STDERR "Done, queried %s kmer file%s to suffix '%s' in %s.\n", 
    commify($file_num), 
    $file_num == 1 ? '' : 's', 
    basename($suffix_file),
    $timer->();
exit 0;

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

            if (my $mean = int($stats->mean())) {
                my $two_stds = 2 * (int $stats->standard_deviation());
                my $min      = $mean - $two_stds;
                my $max      = $mean + $two_stds;

                if (my @filtered = grep { $_ >= $min && $_ <= $max } @vals) {
                    my $stats2 = Statistics::Descriptive::Discrete->new;
                    $stats2->add_data(@filtered);
                    $mode = int($stats2->mode());
                }
            }
            else {
                return 0;
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
    -t|--tmp_dir    Directory to write temp file (default cwd)
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
