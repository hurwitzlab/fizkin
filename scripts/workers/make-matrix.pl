#!/usr/bin/perl

use common::sense;
use autodie;
use Data::Dump qw(dump);
use File::Basename qw(dirname basename);
use File::Find::Rule;
use File::CountLines qw(count_lines);
use Getopt::Long;
use List::MoreUtils qw(uniq);
use Pod::Usage;
use Readonly;

main();

# --------------------------------------------------
sub main {
    my $dir = '';
    my ($help, $man_page);
    GetOptions(
        'd|dir=s' => \$dir,
        'help'    => \$help,
        'man'     => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }; 

    unless ($dir) {
        pod2usage('No directory');
    }

    unless (-d $dir) {
        pod2usage("Bad directory ($dir)");
    }

    my @files = File::Find::Rule->file()->in($dir);

    unless (@files) {
        pod2usage("Found no regular files in dir '$dir'");
    }

    printf "Processing %s files.\n", scalar @files;

    process(\@files);
}

# --------------------------------------------------
sub process {
    my $files = shift;

    my $i;
    my %matrix;
    for my $file (@$files) {
        my $sample1 = basename(dirname($file));
        my $sample2 = basename($file);
        my $lc      = count_lines($file);
        $matrix{ $sample1 }{ $sample2 } = $lc;
        last if $i++ > 20;
    }

    my @keys = keys %matrix;
    my @all_keys = sort(uniq(@keys, map { keys %{ $matrix{ $_ } } } @keys ));

    #say dump(\%matrix);

    say join "\t", '', @all_keys;
    for my $sample1 (@all_keys) {
        say join "\t", 
            $sample1, 
            map { $matrix{ $sample1 }{ $_ } || 0 } @all_keys,
        ;
    }
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

make-matrix.pl - a script

=head1 SYNOPSIS

  make-matrix.pl 

Options:

  --help   Show brief help and exit
  --man    Show full documentation

=head1 DESCRIPTION

Describe what the script does, what input it expects, what output it
creates, etc.

=head1 SEE ALSO

perl.

=head1 AUTHOR

Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2015 Hurwitz Lab

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
