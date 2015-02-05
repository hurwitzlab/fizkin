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
use File::Find::Rule;
use File::Temp 'tempfile';
use Getopt::Long 'GetOptions';
use Hurwitz::Utils qw'commify timer_calc take';
use List::MoreUtils 'uniq';
use Pod::Usage;
use Statistics::Descriptive::Discrete;
use Readonly;

Readonly my $MIN_KMER =>  0;
Readonly my $MAX_KMER => 32;
Readonly my %DEFAULT => (
    kmer_size => 20,
    jellyfish => '/usr/local/bin/jellyfish',
    verbose   => 0,
);

main();

# --------------------------------------------------
sub main {
    my $kmer_size  = $DEFAULT{'kmer_size'};
    my $jellyfish  = $DEFAULT{'jellyfish'};
    my $verbose    = $DEFAULT{'verbose'};
    my $suffix_dir = '';
    my $out_dir    = '';
    my $query_file = '';
    my ($help, $man_page);
    GetOptions(
        'q|query=s'      => \$query_file,
        'o|out=s'        => \$out_dir,
        's|suffix_dir=s' => \$suffix_dir,
        'j|jellyfish:s'  => \$jellyfish,
        'k|kmer:i'       => \$kmer_size,
        'v|verbose'      => \$verbose,
        'help'           => \$help,
        'man'            => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    };

    unless ($query_file && -e $query_file) {
        pod2usage('Missing or bad query file');
    }

    if (!-d $suffix_dir) {
        pod2usage("Bad suffix dir ($suffix_dir)");
    }

    my @suffix_files = File::Find::Rule->file()->name('*.jf')->in($suffix_dir)
        or pod2usage("No Jellyfish (.jf) files in suffix dir '$suffix_dir'");

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

    unless ($kmer_size > $MIN_KMER && $kmer_size < $MAX_KMER) {
        pod2usage(sprintf(
            "Kmer size (%s) must be between %s and %s",
            $kmer_size, $MIN_KMER, $MAX_KMER
        ));
    }

    my $report = sub { say @_ if $verbose };

    # ----------------------------------------------------
    #
    # Set up is done, here's the meat
    #
    my ($basename, $path, $suffix) = fileparse($query_file, qr/\.[^.]+/);
    my $loc_file = catfile($path, $basename . '.loc');

    if (!-e $loc_file) {
        die "Can't find expected kmer location file ($loc_file)\n";
    }

    $report->("Processing query file '$basename'");

    my $timer    = timer_calc();
    my $file_num = 0;

    SUFFIX:
    for my $suffix_file (@suffix_files) {
        $report->(sprintf "%4d: Processing suffix '%s'\n", 
            ++$file_num, basename($suffix_file)
        );

        my $write_dir = catdir($out_dir, basename($suffix_file, '.jf'));

        if (!-d $write_dir) {
            mkpath $write_dir;
        }

        my ($tmp_fh, $tmp_file) = tempfile(DIR => $write_dir);
        close $tmp_fh;

        my @cmd = ($jellyfish, 'query', '-s', $query_file, 
            '-o', $tmp_file, $suffix_file);

        #$report->(join ' ', @cmd);

        my $result = system(@cmd);

        if ($result != 0) {
            unlink $tmp_file;
            print STDERR "jellyfish query of $suffix_file failed: ", $?;
            next SUFFIX;
        }

        #
        # jellyfish query output looks like this
        # AGCAGGTGGAAGGTGAAGGA 5
        # 
        # location file tells us read_id and number of kmers, e.g.:
        # GJFGUPM01AMOBV    163
        # 
        open my $jf_fh,  '<', $tmp_file;
        open my $loc_fh, '<', $loc_file;

        if (!-d $write_dir) {
            mkpath $write_dir;
        }

        #$report->("Writing to ", catfile($write_dir, $basename . '.mode'));
        open my $out_fh, '>', catfile($write_dir, $basename . '.mode');

        while (my $loc = <$loc_fh>) {
            chomp($loc);
            my ($read_id, $n_kmers) = split /\t/, $loc;

            my @counts;
            for my $val (take($n_kmers, $jf_fh)) {
                next if !$val;
                my ($kmer_seq, $count) = split /\s+/, $val;
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

    printf "Done, queried %s suffix file%s to %s in %s.\n", 
        commify($file_num), 
        $file_num == 1 ? '' : 's', 
        $query_file,
        $timer->();
}

# --------------------------------------------------
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
            return $stats->mode();

#            if (my $mean = int($stats->mean())) {
#                my $two_stds = 2 * (int $stats->standard_deviation());
#                my $min      = $mean - $two_stds;
#                my $max      = $mean + $two_stds;
#
#                if (my @filtered = grep { $_ >= $min && $_ <= $max } @vals) {
#                    my $stats2 = Statistics::Descriptive::Discrete->new;
#                    $stats2->add_data(@filtered);
#                    $mode = int($stats2->mode());
#                }
#            }
#            else {
#                return 0;
#            }
        }
    }

    return $mode;
}

# ----------------------------------------------------

=pod

=head1 NAME

jellyfish-query.pl

=head1 SYNOPSIS

  jellyfish-query.pl -s /path/to/suffixes -o /path/to/output -q kmer.file

  Required Arguments:

    -q|--query      The kmer/query file to run against the suffixes
    -s|--suffix     The Jellyfish suffix directory
    -o|--out        Directory to write the output

  Options:

    -j|--jellyfish  Path to "jellyfish" binary (default "/usr/local/bin")
    -k|--kmer       Size of the kmers (default "20")
    -v|--verbose    Show progress while processing sequences
    --help          Show brief help and exit
    --man           Show full documentation

=head1 DESCRIPTION

Query the k-mer file to each suffix array (Jellyfish index) and write out 
each sequence/read's mode to the "out" directory.

=head1 SEE ALSO

Jellyfish

=head1 AUTHOR

Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2014 Hurwitz Lab

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
