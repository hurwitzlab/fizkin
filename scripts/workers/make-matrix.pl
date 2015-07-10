#!/rsgrps/bhurwitz/hurwitzlab/bin/perl

$| = 1;

use common::sense;
use autodie;
use File::Basename qw(dirname basename);
use File::Find::Rule;
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

    my @files = File::Find::Rule->file()->name('*')->in($dir);
    printf STDERR "Found %s files in '%s.'\n", scalar @files, $dir;

    unless (@files) {
        pod2usage("Cannot find anything to work on.");
    }

    process(\@files);

    say "Done.";
}

# --------------------------------------------------
sub process {
    my $files   = shift;
    my $n_files = scalar @$files or return;
    my $i       = 0;
    my %matrix;
    my $size = 0;
    for my $file (@$files) {
#        printf STDERR "%s / %s\n", ++$i , $n_files;
        $i++;
        if ($i % 100 == 0) {
            printf STDERR "%-70s\r", sprintf("%3d%%", int($i*100/$n_files));
        }

        my $sample1 = basename(dirname($file));
        my $sample2 = basename($file);

        chomp(my $n = `cat $file`);

#        open my $fh, '<', $file;
#        local $/;
#        my $n = <$fh>;
#        close $fh;

        $n ||= 0;

        $matrix{ $sample1 }{ $sample2 } = sprintf('%.2f', $n>0 ? log($n) : $n);
    }
    print STDERR "\n";

    my @keys     = keys %matrix;
    my @all_keys = sort(uniq(@keys, map { keys %{ $matrix{ $_ } } } @keys));

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

make-matrix.pl - reduce pair-wise mode values to a tab-delimited matrix

=head1 SYNOPSIS

  make-matrix.pl -d /path/to/modes > matrix

Options:

  -d|--dir  Directory containing the modes
  --help    Show brief help and exit
  --man     Show full documentation

=head1 DESCRIPTION

After calculating the pair-wise read modes, run this script to reduce 
them to a matrix for feeding to R.

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
