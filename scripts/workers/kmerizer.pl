#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;
use feature 'say';
use autodie;
use File::Basename 'basename';
use Pod::Usage;
use Getopt::Long;

my $in_file     = '';
my $kmer_size   = 20;
my $out_dir     = '';
my $verbose     = 0;
my ($help, $man_page);
GetOptions(
    'i|in=s'        => \$in_file,
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

my $mer = 20;
my $n   = 0;

for my $file (@ARGV) {
    print STDERR "$file\n";

    my $locate = basename($file) . '.kmer_location';
    open my $locate_fh, '>', $locate;

    local $/ = '>';
    open my $fasta_fh, '<', $file;
    while (my $fasta = <$fasta_fh>) {
        chomp $fasta;
        next unless $fasta;

        my ($header, @seq) = split /\n/, $fasta;
        my $seq = join '', @seq;
        my $len = length $seq;

        my $i;
        for ($i = 0; $i + $mer <= $len; $i++) {
            print join "\n", '>' . $n++, substr($seq, $i, $mer), '';
        }

        if ($i > 0) {
            print $locate_fh join("\t", $header, $i), "\n"; 
        }
    }

    close $fasta_fh;
    close $locate_fh;
}

print STDERR "Done.\n";

# ----------------------------------------------------

=pod

=head1 NAME

kmerizer.pl

=head1 SYNOPSIS

  kmerizer.pl -i input.fasta -o /path/to/output 

  Required Arguments:

    -i|--in         The input file in FASTA format
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

Ken Youens-Clark E<lt>kclark@cshl.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2014 Ken Youens-Clark

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
