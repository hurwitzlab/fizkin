#!/usr/bin/perl

use common::sense;
use autodie;
use Getopt::Long;
use File::Basename 'fileparse';
use File::Path 'make_path';
use File::Copy 'copy';
use File::Spec::Functions 'catdir';
use Pod::Usage;
use Readonly;

Readonly my $BYTES_TO_MB => 1_000_000;

main();

# --------------------------------------------------
sub main {
    my $max_size  = 100; # MB
    my $file_list = '';
    my $out_dir   = '';
    my ($help, $man_page);
    GetOptions(
        'files=s'   => \$file_list,
        'out-dir=s' => \$out_dir,
        'max:i'     => \$max_size,
        'help'      => \$help,
        'man'       => \$man_page,
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }; 

    my @files = split /\s*,\s*/, $file_list;

    unless (@files) {
        pod2usage('No input files');
    }

    unless ($out_dir) {
        pod2usage('No out directory');
    }

    unless (-d $out_dir) {
        make_path($out_dir);
    }

    my @results = map { split_file($_, $out_dir, $max_size) } @files;
}

# --------------------------------------------------
sub split_file {
    my ($file, $out_dir, $max_size) = @_;

    unless (-e $file) {
        warn "Bad file ($file)\n";
        return;
    }

    if (-s $file < $max_size * $BYTES_TO_MB) {
        warn "File ($file) is OK\n";
        copy($file, $out_dir); 
        return;
    }

    my $file_num    = 1;
    my $last_header = '';
    my $buffer      = '';
    my $acc_len     = 0;

    open my $in_fh, '<', $file;
    while (my $line = <$in_fh>) {
        chomp $line;

        if ($line =~ /^>/) {
            $last_header = $line;
        }

        $buffer .= $line;

        if (length($buffer) > $max_size) {
            write_out(
                $out_dir,
                $file,
                $file_num++,
                substr($buffer, 0, $max_size - 1) . "\n"
            );

            $buffer = substr($buffer, $max_size);

            unless ($buffer =~ /^>/) {
                $buffer = join("\n", $last_header . '-2', $buffer);
            }
        }
    }

    if ($buffer) {
        write_out($out_dir, $file, $file_num, $buffer);
    }

    close $in_fh;
}

# --------------------------------------------------
sub write_out {
    my ($dir, $file, $num, $contents) = @_;

    my ($basename, $path, $suffix) = fileparse($file);

    my $out_name = join('-', $basename, $num, $suffix);

    open my $out_fh, '>', catdir($dir, $out_name);

    print $out_fh $contents;

    close $out_fh;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

fasta-split.pl - a script

=head1 SYNOPSIS

  fasta-split.pl 

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
