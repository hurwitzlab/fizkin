#!/usr/bin/perl

use common::sense;
use autodie;
use Bio::SeqIO;
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use Getopt::Long;
use Pod::Usage;
use Readonly;
use Statistics::Descriptive::Discrete;

Readonly my $MAX_READ_LEN => 50;

main();

# --------------------------------------------------
sub main {
    my ($fastq, $out_dir, $help, $man_page);
    GetOptions(
        'f|fastq=s'   => \$fastq,
        'o|out_dir=s' => \$out_dir,
        'help'        => \$help,
        'man'         => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }; 

    if (!$fastq) {
        pod2usage('Missing FASTQ');
    }

    if ($out_dir) {
        mkpath($out_dir) unless -d $out_dir;
    }
    else {
        pod2usage('Missing output directory name');
    }

    process($fastq, $out_dir);
}

# --------------------------------------------------
sub process {
    my ($fastq, $out_dir) = @_;

    my $in = Bio::SeqIO->new(
        '-file'   => $fastq,
        '-format' => 'fastq'
    );

    (my $basename = basename($fastq)) =~ s/\.fastq/.fa/;
    my $outfa = catfile($out_dir, $basename);
    open my $FA, '>', $outfa;

    my @seqs;
    while (my $seq = $in->next_seq()) {
        my $sequence = $seq->seq();

        # get the average quality score for the read
        my $stats = Statistics::Descriptive::Discrete->new;
        $stats->add_data( map {int($_)} @{$seq->qual()} );

        push @seqs, {
            id       => $seq->id(),
            sequence => $sequence,
            read_len => length $sequence,
            avg_qual => int($stats->mean),
            has_n    => $sequence =~ /[nN]/,
        };
    }

    # now we need to find the average seq length for the set
    # and the standard dev

    # get stats on the mean sequence length for the whole set
    my @read_lengths = map { $_->{'read_len'} } @seqs;
    my ($min_length, $max_length) = get_min_max(\@read_lengths);

    # remove outliers and redo max and min length
    my @no_outliers;
    for my $len (@read_lengths) {
        if (($len <= $max_length) && ($len >= $min_length)) {
            push @no_outliers, $len;
        }
    }

    my ($new_min_length, $new_max_length) = get_min_max(\@no_outliers);

    # get stats on the mean avg quality score for each read
    my $stats = Statistics::Descriptive::Discrete->new;
    $stats->add_data(map { $_->{'avg_qual'} } @seqs);
    my $mean_avg_qual = int($stats->mean());
    my $min_avg_qual  = $mean_avg_qual - (2 * int($stats->standard_deviation));

    for my $seq (@seqs) {
        next if 
            # rule 1: seq cannot contain Ns
            $seq->{'has_n'}

            # rule 2: remove seqs whose average quality score is less than
            # 1 std dev from the mean
            || ($seq->{'avg_qual'} < $min_avg_qual)

            # rule 3: remove sequences whose length is > or <  1 std dev from
            # the mean
            || (
                ($seq->{'read_len'} > $max_length) 
                || 
                ($seq->{'read_len'} < $min_length)
            )

            # rule 4: make sure the sequences are at least 50 bp
            || ($seq->{'read_len'} < $MAX_READ_LEN) 
        ;

        print $FA join "\n", '>' . $seq->{'id'}, $seq->{'sequence'}, '';
    }
}

# --------------------------------------------------
sub get_min_max {
    my $values = shift;
    my $stats  = Statistics::Descriptive::Discrete->new;
    $stats->add_data(@$values);

    my $mean = int($stats->mean());
    my $sd2  = 2 * int($stats->standard_deviation());

    # return min/max
    return $mean - $sd2, $mean + $sd2;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

quality-filter-454.pl

=head1 SYNOPSIS

  quality-filter-454.pl -f /path/to/in.fq -o /path/to/out/dir

Options:

 -f|--fastq    Input FASTA file 
 -o|--out_dir  Where to write the FASTA file with seqs that passed
 --help        Show brief help and exit
  --man        Show full documentation

=head1 DESCRIPTION

Removes sequences with:

=over 4

=item * 

N's anywhere in the sequence

=item * 

sequences whose length is > or < 1 std dev from the mean

=item * 

sequences whose avg quality score is <  1 std dev from the mean

=item * 

sequences that are less than 50bp 

=back

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

