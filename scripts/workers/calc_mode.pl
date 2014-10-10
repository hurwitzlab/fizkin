#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use feature 'say';
use File::Basename 'basename';
use File::Find::Rule;
use File::Spec::Functions 'canonpath';
use Getopt::Long;
use List::MoreUtils 'uniq';
use Pod::Usage;
use Readonly;
use Statistics::Descriptive::Discrete;

my $in_dir = '';
my ($help, $man_page);
GetOptions(
    'd|dir:s' => \$in_dir,
    'help'    => \$help,
    'man'     => \$man_page,
) or pod2usage(2);

if ($help || $man_page) {
    pod2usage({
        -exitval => 0,
        -verbose => $man_page ? 2 : 1
    });
}; 

my @files;
if ($in_dir) {
    if (-d $in_dir) {
        @files = File::Find::Rule->file()->in($in_dir);
    }
    else {
        die "Bad directory ($in_dir)";
    }
}
else {
    @files = @ARGV;
}

for my $file (@files) {
    my $mode      = mode(parse($file));
    my $read_name = basename($file, '.count');
    print join("\t", $mode, $read_name, canonpath($file)), "\n";
}

exit 0;

# ----------------------------------------------------
sub report {
    my $mode = shift;

    if (defined $mode) {
        say $mode;
    }
    else {
        say "Unable to calculate mode";
    }
}

# ----------------------------------------------------
sub mode {
    my $vals = shift;

    if (ref $vals eq 'ARRAY' && scalar @$vals > 0) {
        my $stats = Statistics::Descriptive::Discrete->new;
        $stats->add_data(@$vals);
        return int $stats->mode();

        my $mean     = int $stats->mean();
        my $two_stds = 2 * (int $stats->standard_deviation());
        my $min      = $mean - $two_stds;
        my $max      = $mean + $two_stds;

        if (my @filtered = grep { $_ >= $min && $_ <= $max } @$vals) {
            my $stats2 = Statistics::Descriptive::Discrete->new;
            $stats2->add_data(@filtered);
            return int $stats2->mode();
        }
    }
}

# ----------------------------------------------------
sub parse {
    my $file = shift or return;

    return unless $file && -e $file;

    #print STDERR "Parsing input '$file'";

    open my $fh, '<', $file;
    my @vals;
    while (my $line = <$fh>) {
        chomp $line;
        if ($line) {
            my @data = split /\s+/, $line;
            if (scalar @data == 3) {
                push @vals, $data[-1];
            }
        }
    }
    close $fh;

    if (@vals) {
#        my @uniq = uniq(@vals);
#
#        if (scalar @uniq == 1 && $uniq[0] == 1) {
#            printf STDERR "File %s: All ones.\n", basename($file);
#        }
        return \@vals;
    }
    else {
        printf STDERR "No usable data in input %s\n", basename($file);
    }

#    return \@vals;
}

__END__

# ----------------------------------------------------

=pod

=head1 NAME

calc_mode.pl - calculate mode of k-mer count file

=head1 SYNOPSIS

  calc_mode.pl file.txt

Options:

  --help   Show brief help and exit
  --man    Show full documentation

=head1 DESCRIPTION

Input file looks like this:

 $ head query.9.repeats
 0   +0  323
 0   -0  179
 0   +1  323
 0   -1  178
 0   +2  11
 0   -2  7
 0   +3  9
 0   -3  7
 0   +4  8
 0   -4  6

Take the 3rd column, chop off outliers, find the number in the middle.

=head1 SEE ALSO

perl.

=head1 AUTHOR

Charles Kenneth Youensclark E<lt>kyclark@cshl.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2014 Charles Kenneth Youensclark

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
