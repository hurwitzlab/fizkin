#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use autodie;
use Cwd 'cwd';
use FindBin '$Bin';
use Fizkin;
use Getopt::Long;
use File::Spec::Functions 'catdir';
use Pod::Usage;

$| = 1;

my $DEBUG = 0;

main();

# --------------------------------------------------
sub main {
    my %args = get_args();

    if ($args{'help'} || $args{'man_page'}) {
        pod2usage({
            -exitval => 0,
            -verbose => $args{'man_page'} ? 2 : 1
        });
    }

    #unless ($args{'metadata'}) {
    #    pod2usage('No metadata file');
    #}

    if ($args{'metadata'} && ! -s $args{'metadata'}) {
        pod2usage("Bad metadata file ($args{'metadata'})");
    }

    unless ($args{'in_dir'}) {
        pod2usage('No input directory');
    }

    unless ($args{'out_dir'}) {
        pod2usage('No output directory');
    }

    unless (-d $args{'in_dir'}) {
        pod2usage("Bad input dir ($args{'in_dir'})");
    }

    Fizkin::run(\%args);

    say "Done.";
}

# --------------------------------------------------
sub get_args {
    my %args = (
        debug       => 0,
        files       => '',
        hash_size   => '100M',
        kmer_size   => 20,
        max_samples => 25,
        max_seqs    => 300_000,
        mode_min    => 1,    
        num_threads => 12,
        metadata    => '',
        scripts_dir => $Bin,
        out_dir     => catdir(cwd(), "out"),
    );

    GetOptions(
        \%args,
        'in_dir|i=s',
        'out_dir|o=s',
        'debug',
        'files|f:s',
        'hash_size:s',
        'kmer_size|k:i',
        'max_samples:i',
        'max_seqs:i',
        'metadata:s',
        'mode_min:i',
        'num_threads:i',
        'eucdistper:s',
        'sampledist:s',
        'help',
        'man',
    ) or pod2usage(2);

    return %args;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

run-fizkin - run fizkin

=head1 SYNOPSIS

  run-fizkin -i in_dir -o out_dir

Required arguments:

  --in_dir       Input directory (FASTA)
  --out_dir      Output directory (FASTA)
  --metadata     Meta-data file

Options (defaults in parentheses):
 
  --kmer_size    Kmer size (20)
  --mode_min     Minimum mode to take a sequence (1)
  --num_threads  Number of threads to use for Jellyfish (12)
  --hash_size    Size of hash for Jellyfish (100M)
  --max_seqs     Maximum number of sequences per input file (300,000)
  --max_samples  Maximum number of samples (15)
  --files        Comma-separated list of input files
                 (random subset of --max_samples from --input_dir)
  --scripts_dir  The directory to find the other (R) scripts

  --debug        Print extra things
  --help         Show brief help and exit
  --man          Show full documentation

=head1 DESCRIPTION

Runs a pairwise k-mer analysis on the input files.

=head1 METADATA

The metadata file should look like this:

    +---------------+----------------------+---------+---------+
    | name          | lat_long.ll          | biome.d | depth.c |
    +---------------+----------------------+---------+---------+
    | GD.Spr.C.8m   | -17.92522,146.14295  | G       | 8       |
    | GF.Spr.C.9m   | -16.9207,145.9965833 | G       | 9       |
    | L.Spr.C.1000m | 48.6495,-126.66434   | L       | 1000    |
    +---------------+----------------------+---------+---------+

=head1 SEE ALSO

Fizkin.

=head1 AUTHORS

Bonnie Hurwitz E<lt>bhurwitz@email.arizona.eduE<gt>,
Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2015 Hurwitz Lab

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
