#!/usr/bin/env perl

use common::sense;
use autodie;
use feature 'say';
use Algorithm::Knapsack;
use Data::Dump 'dump';
use Getopt::Long 'GetOptions';
use Getopt::Long;
use List::Util qw'sum max';
use Math::Round 'round';
use Number::Bytes::Human 'format_bytes';
use Pod::Usage;
use Readonly;

Readonly my $MAX_WEIGHTS => 20;

main();

# --------------------------------------------------
sub main {
    my ($debug, $help, $man_page);
    GetOptions(
        'debug' => \$debug,
        'help'  => \$help,
        'man'   => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }; 

    @ARGV || pod2usage("No input");

    my $report = sub { $debug && say STDERR @_};
    for my $file (@ARGV) {
        process($file, $report);
    }

    say STDERR "Done.";
}

# --------------------------------------------------
sub process {
    my ($file, $report) = @_;
    
    open my $fh, '<', $file;

    my @files      = map { chomp; [ split /\s+/ ] } <$fh>;
    my @weights    = map { $_->[0] } @files;
    my $num_files  = scalar @weights;
    my $sum        = sum(@weights);
    my $avg        = round($sum / $num_files);
    my $median     = median(@weights);
    my $largest    = (sort { $a <=> $b } @weights)[-1];
    my $part_size  = max($median, $avg, $largest);

    $report->("num_files $num_files");
    $report->("sum ", format_bytes($sum));
    $report->("average ", format_bytes($avg));
    $report->("median ", format_bytes($median));
    $report->("largest ", format_bytes($largest));
    $report->("part_size ", format_bytes($part_size));

    my $pass = 0;
    my @groups;
    while (1) {
        $report->("PASS ", ++$pass);

        my $result = partition(
            target => $part_size,
            values => \@weights,
        );

        $report->("result = ", dump($result));

        if (@$result == 0) {
            $result = [0..$#weights];
        }

        my @sizes = map { $weights[$_] } @$result;
        my @names = map { $files[$_]->[1] } @$result;
        push @groups, { 
            sum   => format_bytes(sum(@sizes)),
            files => {
                map { $files[$_]->[1], format_bytes($files[$_]->[0]) } 
                @$result 
            } 
        };

        my %skip = map { $_, 1 } @$result;
        @files   = map { $files[$_] } grep { !$skip{ $_ } } 0 .. $#files;
        @weights = map { $_->[0] } @files;
        last unless @weights;
    }

    $report->("Groups = ", dump(\@groups));
    $report->("Num Groups = ", scalar(@groups));

    my $i = 1;
    for my $group (@groups) {
        my @files = keys %{ $group->{'files'} || {} } or next;
        map { say join("\t", $i, $_) } @files;
        $i++;
    }
}

# --------------------------------------------------
sub partition {
    my %args   = @_;
    my $target = $args{'target'} or return;
    my @values = @{ $args{'values'} || [] } or return;

    if (my @big = grep { $values[$_] >= $target } 0..$#values) {
        return [shift @big];
    }

    if (scalar(@values) > $MAX_WEIGHTS) {
        @values = splice(@values, 0, $MAX_WEIGHTS);
    }

    my $knapsack = Algorithm::Knapsack->new(
        capacity => $target,
        weights  => \@values,
    );

    $knapsack->compute();

    if (my @solutions = $knapsack->solutions) {
        return shift @solutions;
    }
    else {
        return [];
    }
}

# --------------------------------------------------
sub median {
    my @vals   = (sort { $a <=> $b } @_) or return;
    my $n      = scalar(@vals);
    my $middle = int($n / 2);

    if ($middle > 0 && $n % 2 == 0) {
        return round(sum($vals[$middle-1], $vals[$middle])/2);
    }
    else {
        return $vals[$middle];
    }
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

distributor.pl - group files into bins of similar capacity

=head1 SYNOPSIS

  distributor.pl file.txt

Options:

  -d|--debug  Show debugging info
  --help      Show brief help and exit
  --man       Show full documentation

=head1 DESCRIPTION

Given an input file of file sizes (in bytes) and file names, e.g.:

    10 foo
    20 bar
    50 baz
    60 blip

This script will place files into groups that have similar sizes, e.g.:

    1   baz
    1   foo
    2   blip
    3   bar

This is useful for distributing data sets to compute nodes so that each node
gets a similar load and therefore all jobs will complete in relatively the
same amount of time (all other things being equal, of course).

Run with "-d" debug flag, if you're curious.

=head1 AUTHOR

Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2015 Ken Youens-Clark

=cut
