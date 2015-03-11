#!/usr/bin/perl

use common::sense;
use autodie;
use DBI;
use Getopt::Long;
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use File::Find::Rule;
use Pod::Usage;
use Readonly;

Readonly my @SCHEMA => (
    'DROP TABLE IF EXISTS read',
    'CREATE TABLE read (read_id INTEGER PRIMARY KEY ASC, read_name text)',
    'CREATE UNIQUE INDEX read_name on read (read_name)'
);

main();

# --------------------------------------------------
sub main {
    my $dir     = '';
    my $db_path = '';
    my ($help, $man_page);
    GetOptions(
        'd|dir=s' => \$dir,
        'db:s'    => \$db_path,
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
        pod2usage('Missing dir');
    }

    unless (-d $dir) {
        pod2usage("Bad dir option ($dir)");
    }

    my @files = File::Find::Rule->file()->in($dir)
        or pod2usage("No files found in '$dir'");

    $db_path //= catfile($dir, 'sum.db');

    my $num_files = @files;
    printf "Found %s file%s in '%s', db = '%s'\n",
        $num_files, $num_files == 1 ? '' : 's', $dir, $db_path;

    my $db = DBI->connect("dbi:SQLite:db=$db_path", '', '');
    say "Recreating schema";
    for my $cmd (@SCHEMA) {
        $db->do($cmd);
    }

    my ($files, $reads) = (0, 0);
    for my $file (@files) {
        printf "%5d: %s\n", ++$files, basename($file);

        open my $fh, '<', $file;
        while (my $read = <$fh>) {
            $reads++;
            chomp $read;
            my $exists = $db->selectrow_array(
                'select read_id from read where read_name=?', {}, $read
            );

            unless ($exists) {
                $db->do('insert into read (read_name) values (?)', {}, $read);
            }
        }

        close $fh;
    }

    printf "Done, processed %s read%s in %s file%s.\n",
        $reads, $reads == 1 ? '' : 's',
        $files, $files == 1 ? '' : 's',
    ;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

sum-host-hits.pl - summarize host hits into SQLite db

=head1 SYNOPSIS

  sum-host-hits.pl -d /path/to/counts 

Required Arguments:

  -d|--dir  Path to counts

Options:

  --db      Path to SQLite db (default "-d" "dir/sum.db")
  --help    Show brief help and exit
  --man     Show full documentation

=head1 DESCRIPTION

Reads all the count files in the specified directory, inserts them
into an SQLite db to unique them and prep for filtering.

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
