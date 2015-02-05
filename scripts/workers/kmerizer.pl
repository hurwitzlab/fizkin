#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;
use feature 'say';
use autodie;
use Cwd 'cwd';
use File::Basename qw(basename fileparse);
use File::Path;
use File::Spec::Functions;
use Getopt::Long;
use Pod::Usage;

main();

# --------------------------------------------------
sub main {
    my $out_dir     = cwd();
    my $kmer_size   = 20;
    my $verbose     = 0;
    my ($help, $man_page);

    GetOptions(
        'o|out=s'       => \$out_dir,
        'k|kmer:i'      => \$kmer_size,
        'v|verbose'     => \$verbose,
        'help'          => \$help,
        'man'           => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }

    if (!@ARGV) {
        pod2usage('No input files');
    }

    if (!-d $out_dir) {
        mkpath $out_dir;
    }

    my $report = sub { say @_ if $verbose };
    $report->(sprintf(
        "files (%s), kmer (%s) out (%s)", scalar @ARGV, $kmer_size, $out_dir
    ));

    my $file_num = 0;
    for my $file (@ARGV) {
        my $basename    = basename($file);
        my $kmer_file   = catfile($out_dir, $basename . '.kmers');
        my $locate_file = catfile($out_dir, $basename . '.loc');

        $report->(sprintf("%4d: %s\n", ++$file_num, $basename));

        open my $fasta_fh , '<', $file;
        open my $kmer_fh  , '>', $kmer_file;
        open my $locate_fh, '>', $locate_file;

        local $/ = '>';

        my $i = 0;
        while (my $fasta = <$fasta_fh>) {
            chomp $fasta;
            next unless $fasta;

            my ($header, @seq) = split /\n/, $fasta;
            my $seq = join '', @seq;
            my $len = length $seq;

            my $pos;
            for ($pos = 0; $pos + $kmer_size <= $len; $pos++) {
                print $kmer_fh 
                    join("\n", '>' . $i++, substr($seq, $pos, $kmer_size), '');
            }

            if ($pos > 0) {
                print $locate_fh join("\t", $header, $pos), "\n"; 
            }
        }

        close $fasta_fh;
        close $kmer_fh;
        close $locate_fh;
    }

    printf "Done, processed %s file%s into %s.\n",
        $file_num, $file_num == 1 ? '' : 's', canonpath($out_dir);
}

# --------------------------------------------------

=pod

=head1 NAME

kmerizer.pl

=head1 SYNOPSIS

  kmerizer.pl -o /path/to/output input.fasta [...]

  Required Arguments:

    -o|--out        Directory to write the output

  Options:

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

Ken Youens-Clark E<lt>kclark@gmail.comE<gt>.

=head1 COPYRIGHT

Copyright (c) 2014 Hurwitz Lab

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
