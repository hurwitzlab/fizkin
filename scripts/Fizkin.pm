package Fizkin;

=pod

=head1 NAME

Fizkin

=head1 SYNOPSIS

  use Fizkin;

=head1 DESCRIPTION

Runs a pairwise k-mer analysis on the input files.

=cut

use strict;
use warnings;
use feature 'say';
use autodie;
use Algorithm::Numerical::Sample 'sample';
use Bio::SeqIO;
use Cwd 'realpath';
use Data::Dump 'dump';
use File::Basename qw'dirname basename';
use File::Copy;
use File::Find::Rule;
use File::Path 'make_path';
use File::Spec::Functions qw'catfile catdir file_name_is_absolute';
use File::Temp qw'tempdir tempfile';
use File::Which 'which';
use Getopt::Long;
use List::MoreUtils qw'uniq';
use List::Util qw'max sum';
use Math::Combinatorics 'combine';
use Pod::Usage;
use Readonly;
use Statistics::Descriptive::Discrete;
use Text::RecordParser::Tab;
use Time::HiRes qw( gettimeofday tv_interval );
use Time::Interval qw( parseInterval );

our $DEBUG = 0;
our $META_PCT_UNIQ = 80;
Readonly my %DEFAULT => (
    hash_size   => '100M',
    kmer_size   => 20,
    gbme_iter   => 100_000,
    max_samples => 15,
    max_seqs    => 300_000,
    mode_min    => 1,    
    num_threads => 12,
);

# --------------------------------------------------
sub run {
    my $args = shift;
    
    if ($args->{'metadata'} && ! -s $args->{'metadata'}) {
        die "Bad metadata file ($args->{'metadata'})\n";
    }

    unless ($args->{'in_dir'}) {
        die "No input directory\n";
    }

    unless ($args->{'out_dir'}) {
        die "No output directory\n";
    }

    unless (-d $args->{'in_dir'}) {
        die "Bad input dir ($args->{'in_dir'})";
    }

    unless ($args->{'scripts_dir'}) {
        die "No scripts_dir";
    }

    unless (-d $args->{'scripts_dir'}) {
        die "Bad scripts dir ($args->{'scripts_dir'})";
    }

    unless (-d $args->{'out_dir'}) {
        make_path($args->{'out_dir'});    
    }

    if ($args->{'debug'}) {
        $DEBUG = 1;
    }

    $args->{'out_dir'} = realpath($args->{'out_dir'});

    while (my ($key, $val) = each %DEFAULT) {
        $args->{ $key } ||= $val;
    }

    say "Subsetting";
    subset_files($args);

    say "Indexing";
    jellyfish_index($args);

    say "Kmerize";
    kmerize($args);

    say "Pairwise comp";
    pairwise_cmp($args);

    say "Matrix";
    make_matrix($args);

    say "Metadata";
    make_metadata_dir($args);

    say "SNA";
    sna($args);

    printf "Done, see '%s' for output.\n", $args->{'sna_dir'};
}

# --------------------------------------------------
sub debug {
    if ($DEBUG && @_) {
        say @_;
    }
}

# --------------------------------------------------
sub sys_exec {
    my @args = @_;

    debug("exec = ", join(' ', @args));

    unless (system(@args) == 0) {
        die sprintf("Failed to execute %s", join(' ', @args));
    }

    return 1;
}

# --------------------------------------------------
sub jellyfish_index {
    my $args       = shift;
    my @file_names = @{ $args->{'file_names'} } or die "No file names.\n";
    my $mer_size   = $args->{'kmer_size'};
    my $hash_size  = $args->{'hash_size'};
    my $threads    = $args->{'num_threads'};
    my $subset_dir = catdir($args->{'out_dir'}, 'subset');
    my $jf_idx_dir = catdir($args->{'out_dir'}, 'jf');

    unless (-d $subset_dir) {
        die "Bad subset dir ($subset_dir)\n";
    }

    unless (-d $jf_idx_dir) {
        make_path($jf_idx_dir);
    }

    my $longest = $args->{'longest_file_name'};
    my $file_num = 0;
    for my $file_name (@file_names) {
        printf "%5d: %-${longest}s ", ++$file_num, $file_name;

        my $jf_file = catfile($jf_idx_dir, $file_name);

        if (-e $jf_file) {
            say "index exists";
        }
        else {
            my $fasta_file = catfile($subset_dir, $file_name);
            die "Bad FASTA file ($fasta_file)\n" unless -e $fasta_file;
            print "indexing, ";
            my $timer = timer_calc();
            sys_exec('jellyfish', 'count', 
                '-m', $mer_size, 
                '-s', $hash_size,
                '-t', $threads,
                '-o', $jf_file,
                $fasta_file
            );
            say "finished in ", $timer->();
        }
    }
}

# --------------------------------------------------
sub kmerize {
    my $args       = shift;
    my @file_names = @{ $args->{'file_names'} } or die "No file names.\n";
    my $mer_size   = $args->{'kmer_size'};
    my $subset_dir = catdir($args->{'out_dir'}, 'subset');
    my $kmer_dir   = catdir($args->{'out_dir'}, 'kmer');

    unless (-d $kmer_dir) {
        make_path($kmer_dir);
    }

    my $longest = $args->{'longest_file_name'};
    my $file_num = 0;
    FILE:
    for my $file_name (@file_names) {
        printf "%5d: %-${longest}s ", ++$file_num, $file_name;

        my $fasta_file = catfile($subset_dir, $file_name);
        my $kmer_file  = catfile($kmer_dir,   $file_name . '.kmer');
        my $loc_file   = catfile($kmer_dir,   $file_name . '.loc');

        if (-e $kmer_file && -e $loc_file) {
            say "kmer/loc files exist";
            next FILE;
        }

        say "kmerizing";

        unless (-e $fasta_file) {
            die "Cannot find FASTA file '$fasta_file'\n";
        }

        my $fa = Bio::SeqIO->new(
            -file   => $fasta_file,
            -format => 'Fasta',
        );

        open my $kmer_fh, '>', $kmer_file;
        open my $loc_fh,  '>', $loc_file;
        
        my $i = 0;
        while (my $seq = $fa->next_seq) {
            my $sequence = $seq->seq;
            my $num_kmers = length($sequence) + 1 - $mer_size;

            if ($num_kmers > 0) {
                for my $pos (0 .. $num_kmers - 1) {
                    say $kmer_fh join("\n",
                        '>' . $i++,
                        substr($sequence, $pos, $mer_size)
                    );
                }
            }

            print $loc_fh join("\t", $seq->id, $num_kmers), "\n"; 
        }
    }
}

# --------------------------------------------------
sub make_matrix {
    my $args       = shift;
    my @combos     = @{ $args->{'mode_combos'} } 
                     or die "No mode combination names.\n";
    my $mode_dir   = catdir($args->{'out_dir'}, 'mode');
    my $matrix_dir = catdir($args->{'out_dir'}, 'matrix');

    unless (-d $mode_dir) {
        die "Bad mode dir ($mode_dir)";
    }

    unless (-d $matrix_dir) {
        make_path($matrix_dir);
    }

    my (%matrix, %seen);
    for my $pair (@combos) {
        my ($s1, $s2) = sort @$pair;

        next if $seen{ $s1 }{ $s2 }++;

        my $f1   = catfile($mode_dir, $s1, $s2);
        my $f2   = catfile($mode_dir, $s2, $s1);
        my $read = sub {
            my $file = shift;
            open my $fh, '<', $file;
            chomp(my $n = <$fh> // 0);
            close $fh;
            return $n;
        };

        my $n1  = $read->($f1);
        my $n2  = $read->($f2);
        my $avg = ($n1 + $n2)/2;
        my $log = $avg > 0 ? sprintf('%0.2f', log($avg)) : 0;

        #$matrix{ $s1 }{ $s2 } = $log;
        #$matrix{ $s2 }{ $s1 } = $log;

        $matrix{ $s1 }{ $s2 } = $n1;
        $matrix{ $s2 }{ $s1 } = $n2;

        #my $sample1 = basename(dirname($file));
        #my $sample2 = basename($file);
        #
        #for ($sample1, $sample2) {
        #    $_ =~ s/\.\w+$//; # remove file extension
        #}
        #
        #$matrix{ $sample1 }{ $sample2 } += $n || 0;
    }


    #    my $num_samples = scalar(keys %matrix);
    #    for my $sample (keys %matrix) {
    #        if ($num_samples != values $matrix{ $sample }) {
    #            say "Deleting $sample";
    #            delete $matrix{ $sample };
    #        }
    #    }

    my @keys     = keys %matrix;
    my @all_keys = sort(uniq(@keys, map { keys %{ $matrix{ $_ } } } @keys));

    debug("matrix = ", dump(\%matrix));

    my $matrix_file = catfile($matrix_dir, 'matrix.tab');
    open my $fh, '>', $matrix_file;

    say $fh join "\t", '', @all_keys;
    for my $sample1 (@all_keys) {
        my @vals = map { $matrix{ $sample1 }{ $_ } || 0 } @all_keys;

        say $fh join "\t", $sample1, @vals;
    }

    $args->{'matrix_file'} = $matrix_file;

    return 1;
}

# --------------------------------------------------
sub make_metadata_dir {
    my $args      = shift;
    my $in_file   = $args->{'metadata'}      or return;
    my $out_dir   = $args->{'out_dir'}       or die "No outdir\n";
    my @filenames = @{$args->{'file_names'}} or die "No file names\n";
    my %names     = map { $_, 1 } @filenames;
    my $meta_dir  = catdir($out_dir, 'metadata');

    unless (-e $in_file) {
        die "Bad metadata file ($in_file)\n";
    }

    if (-d $meta_dir) {
        if (
            my @previous = 
              File::Find::Rule->file()->name(qr/\.(d|c|ll)$/)->in($meta_dir)
        ) {
            my $n = scalar(@previous);
            debug(sprintf("Removing %s previous metadata file%s", 
                $n, $n == 1 ? '' : 's'
            ));
            unlink @previous;
        }
    }
    else {
        make_path($meta_dir);
    }

    debug("metadata file ($in_file)");
    debug("metadata_dir ($meta_dir)");

    my $p    = Text::RecordParser::Tab->new($in_file);
    my @flds = grep { /\.(c|d|ll)$/ } $p->field_list;

    debug("metadata fields = ", join(', ', @flds));

    my %fhs;
    for my $fld (@flds) {
        open $fhs{ $fld }, '>', catfile($meta_dir, $fld);
        (my $base = $fld) =~ s/\..+$//; # remove suffix
        say { $fhs{ $fld } } join "\t", 'Sample', split(/_/, $base);
    }

    #
    # Need to ensure every sample has metadata
    #
    my %meta_check;

    REC:
    while (my $rec = $p->fetchrow_hashref) {
        my $sample_name = $rec->{'name'} or next;
        if (%names && !$names{ $sample_name }) {
            next REC;
        }

        for my $fld (@flds) {
            $meta_check{ $sample_name }{ $fld }++;

            say {$fhs{$fld}}
                join "\t", $sample_name, split(/\s*,\s*/, $rec->{ $fld });
        }
    }

    my @errors;
    for my $file (@filenames) {
        if (my @missing = grep { ! $meta_check{ $file }{ $_ } } @flds) {
            push @errors, "$file missing meta: ", join(', ', @missing);
        }
    } 

    if (@errors) {
        die join "\n", "Metadata errors: ", @errors, '';
    }

    $args->{'metadata_dir'} = $meta_dir;

    return 1;
}

# --------------------------------------------------
sub pairwise_cmp {
    my $args          = shift;
    my @file_names    = @{ $args->{'file_names'} } or die "No file names.\n";
    my $mode_min      = $args->{'mode_min'};
    my $jf_idx_dir    = catdir($args->{'out_dir'}, 'jf');
    my $kmer_dir      = catdir($args->{'out_dir'}, 'kmer');
    my $read_mode_dir = catdir($args->{'out_dir'}, 'read_mode');
    my $mode_dir      = catdir($args->{'out_dir'}, 'mode');
    my $tmp_dir       = catdir($args->{'out_dir'}, 'tmp');

    unless (-d $jf_idx_dir) {
        die "Bad Jellyfish index dir ($jf_idx_dir)";
    }

    unless (-d $kmer_dir) {
        die "Bad kmer dir ($kmer_dir)";
    }

    for my $dir ($tmp_dir, $mode_dir, $read_mode_dir) {
        make_path($dir) unless -d $dir;
    }

    if (scalar(@file_names) < 1) {
        say "Not enough files to perform pairwise comparison.";
        return;
    }

    my @combos = map { [$_, $_] } @file_names;
    for my $pair (combine(2, @file_names)) {
        my ($s1, $s2) = @$pair;
        push @combos, [$s1, $s2], [$s2, $s1];
    }

    $args->{'mode_combos'} = \@combos;

    printf "Will perform %s comparisons\n", scalar(@combos);

    my $combo_num = 0;
    COMBO:
    for my $pair (@combos) {
        my ($base_jf_file, $base_kmer_file) = @$pair;

        my $jf_index        = catfile($jf_idx_dir, $base_jf_file);
        my $kmer_file       = catfile($kmer_dir, $base_kmer_file . '.kmer');
        my $loc_file        = catfile($kmer_dir, $base_kmer_file . '.loc');
        my $sample_mode_dir = catdir($mode_dir, $base_jf_file);
        my $sample_read_dir = catdir($read_mode_dir, $base_jf_file);
        my $mode_file       = catfile($sample_mode_dir, $base_kmer_file);
        my $read_mode_file  = catfile($sample_read_dir, $base_kmer_file);

        for my $dir ($sample_mode_dir, $sample_read_dir) {
            make_path($dir) unless -d $dir;
        }

        my $longest = $args->{'longest_file_name'};
        printf "%5d: %-${longest}s -> %-${longest}s ", 
            ++$combo_num, $base_kmer_file, $base_jf_file;

        if (-s $mode_file) {
            say "mode file exists";
            next COMBO;
        }

        my ($tmp_fh, $jf_query_out_file) = tempfile(DIR => $tmp_dir);
        close $tmp_fh;

        my $timer = timer_calc();

        sys_exec('jellyfish', 'query', '-s', $kmer_file, 
            '-o', $jf_query_out_file, $jf_index);

        open my $loc_fh ,      '<', $loc_file;
        open my $mode_fh,      '>', $mode_file;
        open my $read_mode_fh, '>', $read_mode_file;
        open my $jf_fh,        '<', $jf_query_out_file;

        my $mode_count = 0;
        while (my $loc = <$loc_fh>) {
            chomp($loc);
            my ($read_id, $n_kmers) = split /\t/, $loc;

            my @counts;
            for my $val (take($n_kmers, $jf_fh)) {
                next if !$val;
                my ($kmer_seq, $count) = split /\s+/, $val;
                push @counts, $count if defined $count && $count =~ /^\d+$/;
            }

            my $mode = mode(@counts) // 0;
            if ($mode >= $mode_min) {
                print $read_mode_fh join("\t", $read_id, $mode), "\n";
                $mode_count++;
            }
        }

        say $mode_fh $mode_count;

        say "finished in ", $timer->();

        unlink $jf_query_out_file;
    }
}

# --------------------------------------------------
sub subset_files {
    my $args        = shift;
    my $max_seqs    = $args->{'max_seqs'};
    my $max_samples = $args->{'max_samples'};
    my $in_dir      = $args->{'in_dir'};

    my @files;
    if (my $files_arg = $args->{'files'}) {
        my @names = split(/\s*,\s*/, $files_arg);

        if (my @bad = grep { !-e catfile($in_dir, $_) } @names) {
            die sprintf("Bad input files (%s)\n", join(', ', @bad));
        }
        else {
            @files = @names;
        }
    }
    else {
        @files = map { basename($_) } File::Find::Rule->file()->in($in_dir);
    }

    debug( 
        join("\n", "files = ", map { $_ + 1 . ": " . $files[$_] } 0..$#files)
    );

    my $n_files = scalar(@files);

    unless ($n_files > 1) {
        die "Need more than one file to compare.\n";
    }

    printf "Found %s files in dir '%s'\n", $n_files, $args->{'in_dir'};

    if ($n_files > $max_samples) {
        say "Subsetting to $max_samples files";
        @files = sample(-set => \@files, -sample_size => $max_samples);
    }

    $args->{'file_names'}        = [ sort @files ];
    $args->{'longest_file_name'} = max(map { length($_) } @files);

    my $subset_dir = catdir($args->{'out_dir'}, 'subset');

    unless (-d $subset_dir) {
        make_path($subset_dir);
    }

    my $longest = $args->{'longest_file_name'};
    my $file_num = 0;
    FILE:
    for my $file (@files) {
        my $basename    = basename($file);
        my $file_path   = catfile($in_dir, $file);
        my $subset_file = catfile($subset_dir, $basename);
        my $exists      = -e $subset_file;

        printf "%5d: %-${longest}s: %s\n", 
            ++$file_num, $basename, $exists ? 'skipping' : 'sampling';

        unless ($exists) {
            my ($tmp_fh, $tmp_filename) = tempfile();
            my $fa = Bio::SeqIO->new(
                -file   => $file_path,
                -format => 'Fasta',
            );

            my $out = Bio::SeqIO->new( 
                -file => ">$subset_file",
                -format => 'Fasta', 
            );

            my $taken = 0;
            while (my $seq = $fa->next_seq) {
                $out->write_seq($seq); 
                last if ++$taken > $max_seqs;
            }
        }
    }

    return 1;
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
sub take {
    my ($n, $fh) = @_;

    my @return;
    for (my $i = 0; $i < $n; $i++) {
        my $line = <$fh>;
        last if !defined $line;
        chomp($line);
        push @return, $line;
    }

    @return;
}

# --------------------------------------------------
sub timer_calc {
    my $start = shift || [ gettimeofday() ];

    return sub {
        my %args    = ( scalar @_ > 1 ) ? @_ : ( end => shift(@_) );
        my $end     = $args{'end'}    || [ gettimeofday() ];
        my $format  = $args{'format'} || 'pretty';
        my $seconds = tv_interval( $start, $end );

        if ( $format eq 'seconds' ) {
            return $seconds;
        }
        else {
            return $seconds > 60
                ? parseInterval(
                    seconds => int($seconds),
                    Small   => 1,
                )
                : sprintf("%s second%s", $seconds, $seconds == 1 ? '' : 's')
            ;
        }
    }
}

# --------------------------------------------------
sub sna {
    my $args         = shift;
    my $scripts_dir  = $args->{'scripts_dir'}  or die "No scripts_dir\n";
    my $out_dir      = $args->{'out_dir'}      or die "No out_dir\n";
    my $seq_matrix   = $args->{'matrix_file'}  or die "No matrix\n";
    my $euc_dist_per = $args->{'ecudistper'}   || 0.10;
    my $r_bin        = $args->{'r_bin'}        || which('Rscript');
    my $metadir      = $args->{'metadata_dir'} || '';
    my $iters        = $args->{'gbme_iter'};
    my $max_sample_distance = $args->{'sampledist'} || 1000;

    my @metafiles;
    if ($metadir && -d $metadir) {
        @metafiles = 
            File::Find::Rule->file()->name(qr/\.(d|c|ll)$/)->in($metadir)
            or die "Found no d/c/ll files in ($metadir)\n";
    }

    $out_dir = catdir(realpath($out_dir), 'sna');

    $args->{'sna_dir'} = $out_dir;

    unless (-d $out_dir) {
        make_path($out_dir);
    }

    unless (-e $seq_matrix) {
        die "Bad matrix file ($seq_matrix)\n";
    }

    # step 1 create the metadata tables for the analysis
    # the input is in the format -> id<tab>metadata_value (with a header)
    # input file either need to be:
    # (1) ".ll" for lat_lon
    # (2) ".c" for continous data
    # (3) ".d" for decrete
    # this is how we tell which subroutine to use for creating the
    # metadata matrix files for input into SNA

    # first we need to get a list of the sample ids
    my @samples;
    open my $SM, '<', $seq_matrix;
    while (<$SM>) {
        chomp $_;
        my @fields = split(/\t/, $_);
        my $sample = shift @fields;
        push @samples, $sample;
    }

    shift @samples; # remove the first line with no sample name

    my @meta = ();
    for my $file (@metafiles) {
        say "metafile ($file)";
        my $matrix_file = '';

        if ($file =~ /\.d$/) {
            $matrix_file = discrete_metadata_matrix($file, $out_dir);
        }
        elsif ($file =~ /\.c$/) {
            $matrix_file = continuous_metadata_matrix(
                $file, $euc_dist_per, $out_dir
            );
        }
        elsif ($file =~ /\.ll$/) {
            $matrix_file = distance_metadata_matrix(
                $file, $max_sample_distance, $out_dir
            );
        }

        push @meta, $matrix_file if $matrix_file;
    }

    my $sna_r = catfile($scripts_dir, 'sna.r');
    if (-e $sna_r) {
        sys_exec("$r_bin $sna_r -f $seq_matrix -o $out_dir -n $iters");
    }
    else {
        print "Can't find '$sna_r' script. Maybe set --scripts_dir?";
    }
}

# --------------------------------------------------
sub distance_metadata_matrix {
    #
    # This routine creates the metadata distance matrix based on lat/lon 
    #
    # in_file contains sample, latitude, and longitude in K (Kilometers)
    # similarity distance is equal to the max distances in K for samples to be
    # considered "close", default = 1000
    my ($in_file, $similarity_distance, $out_dir) = @_;
    open my $IN, '<', $in_file;
    my @meta               = ();
    my %sample_to_metadata = ();
    my @samples;
    my $pi = atan2(1, 1) * 4;

    # a test and expected degrees
    #print distance(32.9697, -96.80322, 29.46786, -98.53506, "M") . " Miles\n";
    #print distance(32.9697, -96.80322, 29.46786, -98.53506, "K") . " Kilometers\n";
    #print distance(32.9697, -96.80322, 29.46786, -98.53506, "N") . " Nautical Miles\n";

    my $i = 0;
    while (<$IN>) {
        $i++;
        chomp $_;

        if ($i == 1) {
            @meta = split(/\t/, $_);
            shift @meta;    # remove id
        }
        else {
            my ($id, @values) = split(/\t/, $_);
            push @samples, $id;
            for my $m (@meta) {
                my $v = shift @values;
                $sample_to_metadata{$id}{$m} = $v;
            }
        }
    }

    # create a file that calculates the distance between two geographic points
    # for each pairwise combination of samples
    my $basename = basename($in_file);
    my $out_file = catfile($out_dir, "${basename}.meta");
    open my $OUT, '>', $out_file;
    say $OUT join "\t", '', @samples;

    # approximate radius of earth in km
    #my $r = 6373.0;

    my %check;
    for my $id (sort @samples) {
        my @dist = ();
        for my $s (@samples) {
            my @a = ();    #metavalues for A lat/lon
            my @b = ();    #metavalues for B lat/lon
            for my $m (@meta) {
                my $s1 = $sample_to_metadata{$id}{$m};
                my $s2 = $sample_to_metadata{$s}{$m};
                if (($s1 eq 'NA') || ($s2 eq 'NA')) {
                    $s1 = 0;
                    $s2 = 0;
                }
                push(@a, $s1);
                push(@b, $s2);
            }

            #pairwise dist in km between A and B
            my $lat1 = $a[0];
            my $lat2 = $b[0];
            my $lon1 = $a[1];
            my $lon2 = $b[1];
            my $unit = 'K';
            my $d    = 0;
            if (($lat1 != $lat2) && ($lon1 != $lon2)) {
                $d = distance($lat1, $lon1, $lat2, $lon2, $unit);
            }

            # close = 1
            # far = 0
            my $closeness = 0;
            if ($d < $similarity_distance) {
                $closeness = 1;
            }
            push @dist, $closeness;

        }

        my $tmp = join('', @dist);
        $check{ $tmp }++;
        say $OUT join "\t", $id, @dist;
    }

    if (meta_dist_ok(\%check)) {
        return $out_file;
    }
    else {
        debug("EXCLUDE");
        return undef;
    }
}

# --------------------------------------------------
sub meta_dist_ok {
    my $dist = shift;

    debug("dist = ", dump($dist));
    return unless ref($dist) eq 'HASH';

    my @keys      = keys(%$dist) or return;
    my $n_keys    = scalar(@keys);
    my $n_samples = sum(values(%$dist));
    my @dists     = map { sprintf('%.02f', ($dist->{$_} / $n_samples) * 100) }
                    @keys;

    debug("dists = ", join(', ', @dists));

    my @not_ok = grep { $_ >= $META_PCT_UNIQ } @dists;

    return @not_ok == 0;
}

# --------------------------------------------------
sub distance {
    #
    # This routine calculates the distance between two points (given the     
    # latitude/longitude of those points). It is being used to calculate     
    # the distance between two locations                                     
    #                                                                        
    # Definitions:                                                           
    #   South latitudes are negative, east longitudes are positive           
    #                                                                        
    # Passed to function:                                                    
    #   lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  
    #   lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  
    #   unit = the unit you desire for results                               
    #          where: 'M' is statute miles (default)                         
    #                 'K' is kilometers                                      
    #                 'N' is nautical miles                                  
    #
    my ($lat1, $lon1, $lat2, $lon2, $unit) = @_;

    my $theta = $lon1 - $lon2;
    my $dist =
      sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +
      cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
    $dist = acos($dist);
    $dist = rad2deg($dist);
    $dist = $dist * 60 * 1.1515;
    if ($unit eq "K") {
        $dist = $dist * 1.609344;
    }
    elsif ($unit eq "N") {
        $dist = $dist * 0.8684;
    }
    return ($dist);
}
 
# --------------------------------------------------
sub acos {
    #
    # This function get the arccos function using arctan function
    #
    my ($rad) = @_;
    my $ret = atan2(sqrt(1 - $rad**2), $rad);
    return $ret;
}
 
# --------------------------------------------------
sub deg2rad {
    #
    # This function converts decimal degrees to radians
    #
    my ($deg) = @_;
    my $pi = atan2(1,1) * 4;
    return ($deg * $pi / 180);
}
 
# --------------------------------------------------
sub rad2deg {
    #
    # This function converts radians to decimal degrees 
    #
    my ($rad) = @_;
    my $pi = atan2(1,1) * 4;
    return ($rad * 180 / $pi);
}

# --------------------------------------------------
sub continuous_metadata_matrix {
    # 
    # This routine creates the metadata matrix based on continuous
    # data values in_file contains sample, metadata (continous values)
    # e.g. temperature euclidean distance percentage = the bottom X
    # percent when sorted low to high considered "close", default =
    # bottom 10 percent
    #

    my ($in_file, $eucl_dist_per, $out_dir) = @_;
    open my $IN, '<', $in_file;

    my (@meta, %sample_to_metadata, @samples);

    my $i = 0;
    while (<$IN>) {
        $i++;
        chomp $_;

        if ($i == 1) {
            @meta = split(/\t/, $_);
            shift @meta;    # remove id
        }
        else {
            my @values = split(/\t/, $_);
            my $id = shift @values;
            push(@samples, $id);
            for my $m (@meta) {
                my $v = shift @values;
                $sample_to_metadata{$id}{$m} = $v;
            }
        }
    }

    unless (%sample_to_metadata) {
        die "Failed to get any metadata from file '$in_file'\n";
    }

    # create a file that calculates the euclidean distance for each value in
    # the metadata file for each pairwise combination of samples where the
    # value gives the euclidean distance for example "nutrients" might be
    # comprised of nitrite, phosphate, silica
    my $basename = basename($in_file);
    my $out_file = catfile($out_dir, "${basename}.meta");
    open my $OUT, '>', $out_file;
    say $OUT join "\t", '', @samples;

    # get all euc distances to determine what is reasonably "close"
    my @all_euclidean = ();
    for my $id (@samples) {
        my @pw_dist = ();
        for my $s (@samples) {
            my (@a, @b); 
            for my $m (@meta) {
                push @a, $sample_to_metadata{$id}{$m};
                push @b, $sample_to_metadata{$s}{$m};
            }

            #pairwise euc dist between A and B
            my $ct  = scalar(@a) - 1;
            my $sum = 0;
            for my $i (0 .. $ct) {
                if (($a[$i] ne 'NA') && ($b[$i] ne 'NA')) {
                    $sum += ($a[$i] - $b[$i])**2;
                }
            }

            # we have a sample that is different s1 ne s2
            # there are no 'NA' values
            if ($sum > 0) {
                my $euc_dist = sqrt($sum);
                push @all_euclidean, $euc_dist;
            }
        }
    }

    unless (@all_euclidean) {
        die "Failed to get Euclidean distances.\n";
    }

    my @sorted     = sort { $a <=> $b } @all_euclidean;
    my $count      = scalar(@sorted);
    my $bottom_per = $count - int($eucl_dist_per * $count);
    my $max_value  = $bottom_per < $count ? $sorted[$bottom_per] : $sorted[-1];
    my $min_value  = $sorted[0];
    debug(join(', ',
        "sorted (" . join(', ', @sorted) . ")",
        "eucl_dist_per ($eucl_dist_per)",
        "bottom_per ($bottom_per)", 
        "max_value ($max_value)", 
        "min_value ($min_value)"
    ));

    unless ($max_value > 0) {
        die "Failed to get valid max value from list ", join(', ', @sorted);
    }

    my %check;
    for my $id (sort @samples) {
        my (@pw_dist, @euclidean_dist);

        for my $s (@samples) {
            my (@a, @b);

            for my $m (@meta) {
                push @a, $sample_to_metadata{$id}{$m};
                push @b, $sample_to_metadata{$s}{$m};
            }

            my $ct  = scalar(@a) - 1;
            my $sum = 0;

            #pairwise euc dist between A and B
            for my $i (0 .. $ct) {
                if (($a[$i] ne 'NA') && ($b[$i] ne 'NA')) {
                    my $value = ($a[$i] - $b[$i])**2;
                    $sum = $sum + $value;
                }
            }

            if ($sum > 0) {
                my $euc_dist = sqrt($sum);
                push @euclidean_dist, $euc_dist;
            }
            else {
                if ($id eq $s) {
                    push @euclidean_dist, $min_value;
                }
                else {
                    #push @euclidean_dist, 'NA';
                    push @euclidean_dist, 0;
                }
            }
        }

        # close = 1
        # far = 0
        for my $euc_dist (@euclidean_dist) {
            my $val = ($euc_dist < $max_value) && ($euc_dist > 0) ? 1 : 0;
            push @pw_dist, $val;
        }

        my $tmp = join('', @pw_dist);
        $check{ $tmp }++;
        say $OUT join "\t", $id, @pw_dist;
    }

    if (meta_dist_ok(\%check)) {
        return $out_file;
    }
    else {
        debug("EXCLUDE");
        return undef;
    }
}

# --------------------------------------------------
sub discrete_metadata_matrix {
    #
    # This routine creates the metadata matrix based on discrete data values 
    #
    # in_file contains sample, metadata (discrete values) 
    # e.g. longhurst province
    # where 0 = different, and 1 = the same

    my ($in_file, $out_dir) = @_;
    my @meta               = ();
    my %sample_to_metadata = ();
    my @samples;

    open my $IN, '<', $in_file;

    my $i = 0;
    while (<$IN>) {
        $i++;
        chomp $_;

        # header line
        if ($i == 1) {
            @meta = split(/\t/, $_);
            shift @meta;    # remove id for sample
        }
        else {
            my @values = split(/\t/, $_);
            my $id = shift @values;
            push @samples, $id;
            for my $m (@meta) {
                my $v = shift @values;
                $sample_to_metadata{$id}{$m} = $v;
            }
        }
    }

    # create a file that calculates the whether each value in the metadata file
    # is the same or different
    # for each pairwise combination of samples
    # where 0 = different, and 1 = the same
    my $basename = basename($in_file);
    my $out_file = catfile($out_dir, "${basename}.meta");
    open my $OUT, ">", $out_file;
    say $OUT join "\t", '', @samples;

    my %check;
    for my $id (sort @samples) {
        my @same_diff = ();
        for my $s (@samples) {
            my @a = ();    #metavalues for A
            my @b = ();    #metavalues for B
            for my $m (@meta) {
                my $s1 = $sample_to_metadata{$id}{$m};
                my $s2 = $sample_to_metadata{$s}{$m};
                push(@a, $s1);
                push(@b, $s2);
            }

            # count for samples
            my $ct = @a;
            $ct = $ct - 1;

            #pairwise samenesscheck between A and B
            for my $i (0 .. $ct) {
                if (($a[$i] ne 'NA') && ($b[$i] ne 'NA')) {
                    if ($a[$i] eq $b[$i]) {
                        push @same_diff, 1;
                    }
                    else {
                        push @same_diff, 0;
                    }
                }
                else {
                    push @same_diff, 0;
                }
            }
        }

        my $tmp = join '', @same_diff;
        $check{ $tmp }++;
        say $OUT join "\t", $id, @same_diff;
    }

    close $OUT;

    if (meta_dist_ok(\%check)) {
        return $out_file;
    }
    else {
        debug("EXCLUDE");
        return undef;
    }
}

# --------------------------------------------------

=pod

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

1;
