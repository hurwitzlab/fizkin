#!/usr/bin/env perl

use common::sense;
use autodie;
use Getopt::Long;
use Cwd qw(cwd);
use File::Basename qw(basename dirname);
use File::Spec::Functions qw(catfile);
use File::Path qw(make_path);
use Pod::Usage;
use Readonly;

main();

# --------------------------------------------------
sub main {
    my $out_dir     = cwd();
    my $host_file   = '';
    my $reject_file = '';
    my ($help, $man_page);
    GetOptions(
        'h|host=s'   => \$host_file,
        'o|out:s'    => \$out_dir,
        'r|reject:s' => \$reject_file,
        'help'       => \$help,
        'man'        => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    };

    unless ($host_file) {
        pod2usage('Missing host file');
    }

    unless (-s $host_file) {
        pod2usage("Bad host file ($host_file)");
    }

    unless (-d $out_dir) {
        make_path($out_dir);
    }

    my @files    = @ARGV or pod2usage('No input files');
    my $host_id  = get_host_ids($host_file);
    my $file_num = 0;
    my $seen     = 0;
    my $removed  = 0;

    printf "Using %s host ids from '%s'\n",
        scalar keys %$host_id, basename($host_file);

    my $reject_fh;
    if ($reject_file) {
        my $dir = dirname($reject_file);
        unless (-d $dir) {
            make_path($dir);
        }

        open $reject_fh, '>', $reject_file;
    }

    for my $file (@files) {
        printf "%5d: %s\n", ++$file_num, basename($file);

        local $/ = '>';
        open my $in , '<', $file;
        open my $out, '>', catfile($out_dir, basename($file));

        while (my $rec = <$in>) {
            chomp $rec;
            next unless $rec;

            $seen++;

            my ($id, @seq) = split /\n/, $rec;

            if ($host_id->{ $id }) {
                $removed++;
                if ($reject_fh) {
                    print $reject_fh ">$rec";
                }
            }
            else {
                print $out ">$rec";
            }
        }

        close $in;
        close $out;
    }

    printf "Done, processed %s file%s, removed %s%% (%s of %s)\n",
        $file_num,
        $file_num == 1 ? '' : 's',
        int($removed/$seen * 100),
        $removed,
        $seen,
    ;
}

# --------------------------------------------------
sub get_host_ids {
    my $file = shift or return;

    open my $fh, '<', $file;
    my %id;
    while (my $id = <$fh>) {
        chomp $id;
        $id{ $id } = 1;
    }
    close $fh;
    return \%id;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

screen-host.pl - screen host sequences from FASTA files

=head1 SYNOPSIS

  screen-host.pl -h /path/to/host/ids file1.fa [file2.fa ...]

Options:

  -o|--out     Where to write output file (default '.')
  -r|--reject  Where to write rejected sequences
  --help       Show brief help and exit
  --man        Show full documentation

=head1 DESCRIPTION

Reads a "host" file of read IDs, filters these from the FASTA files,
writes to the "out" directory.

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
