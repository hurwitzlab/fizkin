#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;
use feature 'say';
use autodie;
use Cwd 'cwd';
use File::Basename qw(basename fileparse dirname);
use File::Path qw(make_path);
use File::Spec::Functions;
use Getopt::Long;
use Pod::Usage;

main();

# --------------------------------------------------
sub main {
    my $in        = '';
    my $out       = '-';
    my $loc_out   = '';
    my $kmer_size = 20;
    my $clobber   = 0;
    my $quiet     = 0;
    my ($help, $man_page);

    GetOptions(
        'i|in=s'    => \$in,
        'o|out:s'   => \$out,
        'l|loc:s'   => \$loc_out,
        'k|kmer:i'  => \$kmer_size,
        'q|quiet'   => \$quiet,
        'c|clobber' => \$clobber,
        'help'      => \$help,
        'man'       => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }

    unless ($in) {
        pod2usage('No input files');
    }

    unless (-s $in) {
        pod2usage("Bad input file ($in)");
    }

    my $report   = sub { say @_ unless $quiet };
    my $file_num = 0;

    my $kmer_fh;
    if ($out eq '-') {
       $kmer_fh = \*STDOUT;
    } 
    else {
        if ((-e $out && -s _) && !$clobber) {
            $report->(
                sprintf "Out file (%s) exists, no-clobber is on, exiting.\n",
                basename($out)
            );
            exit 0;
        }

        my $dir = dirname($out);
        if (!-d $dir) {
            make_path($dir);
        }

        open $kmer_fh, '>', $out;
    }

    my $locate_fh;
    if ($loc_out) {
        open $locate_fh, '>', $loc_out;
    }

    open my $fasta_fh, '<', $in;
    local $/ = '>';

    my $i = 0;
    while (my $fasta = <$fasta_fh>) {
        chomp $fasta;
        next unless $fasta;

        my ($id, @seq) = split /\n/, $fasta;
        my $seq        = join '', @seq;
        my $num_kmers  = length($seq) + 1 - $kmer_size;

        next unless $num_kmers > 0;

        for my $pos (0 .. $num_kmers - 1) {
            say $kmer_fh substr($seq, $pos, $kmer_size);
        }

        if ($locate_fh) {
            print $locate_fh join("\t", $id, $num_kmers), "\n"; 
        }
    }

    close $fasta_fh;
    close $kmer_fh;
    close $locate_fh if $locate_fh;
}

# --------------------------------------------------

=pod

=head1 NAME

kmerizer.pl

=head1 SYNOPSIS

  kmerizer.pl -o kmer-out -l location-out -i input.fasta 

  Required Arguments:

    -i             Input FASTA file

  Options:

    -o|--out       Where to write the k-mers (default "-"/STDOUT)
    -l|--loc       Where to write the locations 
                   (default nothing, so no output)
    -k|--kmer      Size of the kmers (default "20")
    -q|--quiet     Don't progress while processing sequences (default verbose)
    -c|--clobber   Overwrite existing kmers/locs files (default no)
    --help         Show brief help and exit
    --man          Show full documentation

=head1 DESCRIPTION

For read in each FASTA input file, run "jellyfish query" to all indexes in 
the "suffix" dir and write each sequence/read's mode to the "out" directory.

=head1 SEE ALSO

Jellyfish

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@gmail.comE<gt>.

=head1 COPYRIGHT

Copyright (c) 2014 Hurwitz Lab

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
