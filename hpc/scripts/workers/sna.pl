#!/usr/bin/env perl

$| = 1;

use common::sense;
use autodie;
use Cwd 'cwd';
use feature 'say';
use File::Basename qw(basename fileparse);
use File::Path;
use File::Spec::Functions;
use Getopt::Long;
use Pod::Usage;
use Readonly;
use Template;

main();

# --------------------------------------------------
sub main {
    my $out_dir    = cwd();
    my $metadir    = '';
    my $euc_dist_per = 0.10;
    my $max_sample_distance = 1000;
    my $seq_matrix = '';
    my $verbose    = 0;
    my ($help, $man_page);

    GetOptions(
        'o|out-dir=s'    => \$out_dir,
        'm|metadir=s'    => \$metadir,
        'e|eucdistper=s' => \$euc_dist_per,
        'd|sampledist=s' => \$max_sample_distance,
        's|seq-matrix=s' => \$seq_matrix,
        'v|verbose'      => \$verbose,
        'help'           => \$help,
        'man'            => \$man_page
    ) or pod2usage(2);

    if ($help || $man_page) {
        pod2usage({
            -exitval => 0,
            -verbose => $man_page ? 2 : 1
        });
    }

    unless ($seq_matrix) {
        pod2usage('No sequence matrix');
    }

    unless ($metadir) {
        pod2usage('No metadata directory specified');
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
    my @samples = ();
    open (SM, "$seq_matrix") || die "Cannot open $seq_matrix\n";
    while (<SM>) {
       chomp $_;
       my @fields = split(/\t/, $_);
       my $sample = shift @fields;
       push @samples, $sample;
    }
    shift @samples; # remove the first line with no sample name

    opendir(my $dh, $metadir) || die "no metadata directory specified\n";
    my @meta = ();
    while(readdir $dh) {
       my $file = $_;
       if($file eq "." || $file eq ".."){ next;}
       my $matrix_file = '';
       if ($_ =~ /\.d$/) {
          $matrix_file = discrete_metadata_matrix($file,$metadir,$out_dir);
          push @meta, $matrix_file;
       } 
       if ($_ =~ /\.c$/) {
          $matrix_file = continuous_metadata_matrix($file, $euc_dist_per, $metadir, $out_dir);
          push @meta, $matrix_file;
          #print "$matrix_file matrix\n";
       }
       if ($_ =~ /\.ll$/) {
          $matrix_file = distance_metadata_matrix($file, $max_sample_distance, $metadir, $out_dir );
          push @meta, $matrix_file;
       } 
    }
    closedir $dh;

    # now we need to run the SNA analysis
    # be sure that `module load R` has already been run in the
    # shell script that runs this perl script on the 
    # compute node
    my $t         = Template->new;
    my $sna_tmpl  = template_sna();
    my $plot_tmpl = template_plot();

    $t->process(
        \$sna_tmpl, 
        { 
            out_dir    => $out_dir,
            seq_matrix => $seq_matrix,
            meta       => \@meta,
        }, 
        'sna.R'
    ) or die $t->error;

    $t->process(
        \$plot_tmpl, 
        { 
            out_dir => $out_dir,
            samples => \@samples,
        }, 
        'plot.R'
    ) or die $t->error;

    # make sure you load R if you run this on the HPC
    my $cmd1 = `R CMD BATCH --slave sna.R`;
    my $cmd2 = `R CMD BATCH --slave plot.R`;
}

# --------------------------------------------------
sub template_sna {
    return <<EOF
setwd("[% out_dir %]")
library(xtable)
NS <- 100000
odens <- 10
source("gbme.r")
Y <- as.matrix(read.table("[% seq_matrix %]", header = TRUE))
n <- nrow(Y)
k <- [% meta.size %]
Xss<-array(NA, dim=c(n,n,k))
[% SET counter = 0 -%]
[% FOREACH m IN meta -%]
   [% SET counter=counter + 1 -%]
   [% m %] <- as.matrix(read.table("[% m %]", header = TRUE))
   Xss[,, [% counter%] ] <- [% m %]
[% END -%]
[% SET counter=counter + 1 -%]
gbme(Y=Y, Xss, fam="gaussian", k=2, direct=F, NS=NS, odens=odens)

x.names <- c("[% meta.join('", "')%]", "intercept")

OUT <- read.table("OUT", header=T)
full.model <- t(apply(OUT, 2, quantile, c(0.5, 0.025, 0.975)))
rownames(full.model)[1:[% counter %]] <- x.names
table1 <- xtable(full.model[1:[% counter %]], align="c|c||cc")
print ( xtable (table1), type= "latex" , file= "table1.tex" )
EOF
}

# --------------------------------------------------
sub template_plot {
    return <<EOF
setwd("[% out_dir %]")
source("gbme.r")
OUT<-read.table("OUT",header=T)
#examine marginal mixing
par(mfrow=c(3,4))      
pdf("plot1.pdf", width=6, height=6)
for(i in 3:dim(OUT)[2]) { plot(OUT[,i],type="l") }
dev.off()
# posterior samples, dropping
# the first half of the chain
# to allow for burn in
PS<-OUT[OUT\$scan>round(max(OUT\$scan)/2),-(1:3)]

#gives mean, std dev, and .025,.5,.975 quantiles
M.SD.Q<-rbind( apply(PS,2,mean),apply(PS,2,sd),apply(PS,2,quantile,probs=c(.025,.5,.975)) )

print(M.SD.Q)

#plots of posterior densities
pdf("plot2.pdf", width=6, height=6)
par(mfrow=c(3,4))
for(i in 1:dim(PS)[2]) { plot(density(PS[,i]),main=colnames(PS)[i]) }
dev.off()

###analysis of latent positions

Z<-read.table("Z")

#convert to an array
nss<-dim(OUT)[1]
n<-dim(Z)[1]/nss
k<-dim(Z)[2]
PZ<-array(dim=c(n,k,nss))
for(i in 1:nss) { PZ[,,i]<-as.matrix(Z[ ((i-1)*n+1):(i*n) ,])  }

PZ<-PZ[,,-(1:round(nss/2))]     #drop first half for burn in

#find posterior mean of Z %*% t(Z)
ZTZ<-matrix(0,n,n)
for(i in 1:dim(PZ)[3] ) { ZTZ<-ZTZ+PZ[,,i]%*%t(PZ[,,i]) }
ZTZ<-ZTZ/dim(PZ)[3]

#a configuration that approximates posterior mean of ZTZ
tmp<-eigen(ZTZ)
Z.pm<-tmp\$vec[,1:k]%*%sqrt(diag(tmp\$val[1:k]))

#now transform each sample Z to a common orientation
for(i in 1:dim(PZ)[3] ) { PZ[,,i]<-proc.rr(PZ[,,i],Z.pm) }

#
# a two dimensional plot of "mean" latent locations 
# and marginal confidence regions
#
k <- 2
if(k==2) {     

    r<-atan2(Z.pm[,2],Z.pm[,1])
    r<-r+abs(min(r))
    r<-r/max(r)
    g<-1-r
    b<-(Z.pm[,2]^2+Z.pm[,1]^2)
    b<-b/max(b)

    par(mfrow=c(1,1))
    pdf("plot3.pdf", width=6, height=6)
    plot(Z.pm[,1],Z.pm[,2],xlab="",ylab="",type="n",xlim=range(PZ[,1,]),
         ylim=range(PZ[,2,]))
    abline(h=0,lty=2);abline(v=0,lty=2)

    for(i in 1:n) { points( PZ[i,1,],PZ[i,2,],pch=46,col=rgb(r[i],g[i],b[i]) ) }
    [% SET labels = [] %]
    [% FOREACH id IN samples -%]
       [% labels.push("'" _ id _ "'") -%]
    [% END -%]
    text(Z.pm[,1],Z.pm[,2], cex = 0.3, labels=c([% labels.join(',') %]))   #add labels here
    dev.off()
}
EOF
}

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This routine creates the metadata distance matrix based on lat/lon     :::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub distance_metadata_matrix {
   # in_file contains sample, latitude, and longitude in K (Kilometers)
   # similarity distance is equal to the max distances in K for samples to be
   # considered "close", default = 1000
   my ($in_file, $similarity_distance, $metadir, $out_dir) = @_; 
   open (IN, "$metadir/$in_file") || die "Cannot open $in_file\n";
   my @meta = ();
   my %sample_to_metadata = ();
   my @samples;
   my $pi = atan2(1,1) * 4;
   
   # a test and expected degrees
   #print distance(32.9697, -96.80322, 29.46786, -98.53506, "M") . " Miles\n";
   #print distance(32.9697, -96.80322, 29.46786, -98.53506, "K") . " Kilometers\n";
   #print distance(32.9697, -96.80322, 29.46786, -98.53506, "N") . " Nautical Miles\n";
   
   my $i = 0;
   while (<IN>) {
      $i++;
      chomp $_;
   
      if ($i == 1) { 
         @meta = split (/\t/, $_);
         shift @meta; # remove id
      }
      else {
         my @values = split (/\t/, $_);
         my $id = shift @values;
         push (@samples, $id);
         for my $m (@meta) {
            my $v = shift @values;
            $sample_to_metadata{$id}{$m} = $v;
         }
      }
   }
   
   # create a file that calculates the distance between two geographic points
   # for each pairwise combination of samples
   
   open (OUT, ">$out_dir/$in_file.meta") || die "Cannot open metadata file $in_file.meta\n";
   print OUT "\t", join("\t", @samples), "\n";
   close OUT;
   
   # approximate radius of earth in km
   my $r = 6373.0;
   
   for my $id (sort @samples) {
     my @dist = ();
     for my $s (@samples) {
         my @a = ();  #metavalues for A lat/lon
         my @b = ();  #metavalues for B lat/lon
         for my $m (@meta) {
            my $s1 = $sample_to_metadata{$id}{$m};
            my $s2 = $sample_to_metadata{$s}{$m};
            if (($s1 eq 'NA') || ($s2 eq 'NA')) {
               $s1 = 0;
               $s2 = 0;
            }
            push (@a, $s1);
            push (@b, $s2);
        }
        #pairwise dist in km between A and B
        my $lat1 = $a[0];
        my $lat2 = $b[0];
        my $lon1 = $a[1];
        my $lon2 = $b[1];
        my $unit = 'K';
        my $d = 0;
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
   
    open (OUT, ">>$out_dir/$in_file.meta") || die "Cannot open metadata file $in_file.meta\n";
    print OUT "$id\t", join("\t", @dist), "\n";
    close OUT;
   }
   return ("$in_file.meta");
}

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::                                                                         :::
#:::  This routine calculates the distance between two points (given the     :::
#:::  latitude/longitude of those points). It is being used to calculate     :::
#:::  the distance between two locations                                     :::
#:::                                                                         :::
#:::  Definitions:                                                           :::
#:::    South latitudes are negative, east longitudes are positive           :::
#:::                                                                         :::
#:::  Passed to function:                                                    :::
#:::    lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  :::
#:::    lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  :::
#:::    unit = the unit you desire for results                               :::
#:::           where: 'M' is statute miles (default)                         :::
#:::                  'K' is kilometers                                      :::
#:::                  'N' is nautical miles                                  :::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub distance {
    my ($lat1, $lon1, $lat2, $lon2, $unit) = @_;
    #print "$lat1, $lon1, $lat2, $lon2, $unit \n";
    my $theta = $lon1 - $lon2;
    my $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
  $dist  = acos($dist);
  $dist = rad2deg($dist);
  $dist = $dist * 60 * 1.1515;
  if ($unit eq "K") {
    $dist = $dist * 1.609344;
  } elsif ($unit eq "N") {
    $dist = $dist * 0.8684;
        }
    return ($dist);
}
 
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function get the arccos function using arctan function   :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub acos {
    my ($rad) = @_;
    my $ret = atan2(sqrt(1 - $rad**2), $rad);
    return $ret;
}
 
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function converts decimal degrees to radians             :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub deg2rad {
    my ($deg) = @_;
    my $pi = atan2(1,1) * 4;
    return ($deg * $pi / 180);
}
 
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::  This function converts radians to decimal degrees             :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub rad2deg {
    my ($rad) = @_;
    my $pi = atan2(1,1) * 4;
    return ($rad * 180 / $pi);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
##:::  This routine creates the metadata matrix based on continuous data values :::
##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub continuous_metadata_matrix {
   # in_file contains sample, metadata (continous values) e.g. temperature
   # euclidean distance percentage = the bottom X percent when sorted low to high
   # considered "close", default = bottom 10 percent
   
   my ($in_file, $eucl_dist_per,$metadir, $out_dir) = @_;
   open (IN, "$metadir/$in_file") || die "Cannot open $in_file\n";   
   my @meta = ();
   my %sample_to_metadata = ();
   my @samples;
   
   my $i = 0;
   while (<IN>) {
      $i++;
      chomp $_;
   
      if ($i == 1) { 
         @meta = split (/\t/, $_);
         shift @meta; # remove id
      }
      else {
         my @values = split (/\t/, $_);
         my $id = shift @values;
         push (@samples, $id);
         for my $m (@meta) {
            my $v = shift @values;
            $sample_to_metadata{$id}{$m} = $v;
         }
      }
   }
   
   # create a file that calculates the eucledean distance for each value in the metadata file
   # for each pairwise combination of samples
   # where the value gives the eucledean distance 
   # for example "nutrients" might be comprised of nitrite, phosphate, silica
   
   open (OUT, ">$out_dir/$in_file.meta") || die "Cannot open metadata file $in_file.meta\n";
   print OUT "\t", join("\t", @samples), "\n";
   close OUT;
   
   # get all euc distances to determine what is reasonably "close"
   my @all_eucledean = ();
   for my $id (@samples) {
     my @pw_dist = ();
     for my $s (@samples) {
         my @a = ();  #metavalues for A
         my @b = ();  #metavalues for B
         for my $m (@meta) {
            my $s1 = $sample_to_metadata{$id}{$m};
            my $s2 = $sample_to_metadata{$s}{$m};
            push (@a, $s1);
            push (@b, $s2);
        }
        my $ct = @a;
        $ct = $ct - 1;
   
        my $sum = 0;
        #pairwise euc dist between A and B
        for my $i ( 0 .. $ct) {
           if (($a[$i] ne 'NA') && ($b[$i] ne 'NA')) {
              my $value = ($a[$i]-$b[$i])**2;
              $sum = $sum + $value;
           }
        }
        # we have a sample that is different s1 ne s2
        # there are no 'NA' values
        if ($sum > 0) {
           my $euc_dist = sqrt( $sum );
           push @all_eucledean, $euc_dist;
           #print "$euc_dist\n";
        }
     }
   }
   
   my @sorted = sort @all_eucledean;
   my $count = @sorted;
   #print "count $count";
   my $bottom_per = $count - int($eucl_dist_per * $count);
   #print "bottom $bottom_per\n";
   my $max_value = $sorted[$bottom_per];
   my $smallest_value = $sorted[0];
   
   #print "max euc dist: $max_value\n";
   
   
   for my $id (sort @samples) {
     my @pw_dist = ();
     my @eucledean_dist = ();
     for my $s (@samples) {
         my @a = ();  #metavalues for A
         my @b = ();  #metavalues for B
         for my $m (@meta) {
            my $s1 = $sample_to_metadata{$id}{$m};
            my $s2 = $sample_to_metadata{$s}{$m};
            push (@a, $s1);
            push (@b, $s2);
        }
        my $ct = @a;
        $ct = $ct - 1;
   
        my $sum = 0;
        #pairwise euc dist between A and B
        for my $i ( 0 .. $ct) {
           if (($a[$i] ne 'NA') && ($b[$i] ne 'NA')) {
              my $value = ($a[$i]-$b[$i])**2;
              $sum = $sum + $value;
           }
        }
        #print "$sum\n";
        
       if ($sum > 0) { 
           my $euc_dist = sqrt( $sum );
           push @eucledean_dist, $euc_dist;
       } 
       else {
          if ($id eq $s) {
             push @eucledean_dist, $smallest_value;
          }
          else {
             #push @eucledean_dist, 'NA';
             push @eucledean_dist, 0;
          }
       }
    }
   
     # close = 1
     # far = 0
   
     for my $euc_dist ( @eucledean_dist ) {
        #print "$euc_dist\n";
        if (($euc_dist < $max_value) && ($euc_dist > 0)) {
           push (@pw_dist, 1);
        }
        else {
           push (@pw_dist, 0);
        }
     }
   
    open (OUT, ">>$out_dir/$in_file.meta") || die "Cannot open metadata file $in_file.meta\n";
    print OUT "$id\t", join("\t", @pw_dist), "\n";
    close OUT;
   
   }
   return ("$in_file.meta");
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
##:::  This routine creates the metadata matrix based on discrete data values   :::
##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
sub discrete_metadata_matrix {
   # in_file contains sample, metadata (discrete values) e.g. longhurst province 
   # where 0 = different, and 1 = the same 

   my ($in_file, $metadir, $out_dir) = @_;
   open (IN, "$metadir/$in_file") || die "Cannot open $in_file\n";   
   my @meta = ();
   my %sample_to_metadata = ();
   my @samples;
   
   my $i = 0;
   while (<IN>) {
      $i++;
      chomp $_;
      # header line 
      if ($i == 1) { 
         @meta = split (/\t/, $_);
         shift @meta; # remove id for sample
      }
      else {
         my @values = split (/\t/, $_);
         my $id = shift @values;
         push (@samples, $id);
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
   open (OUT, ">$out_dir/$in_file.meta") || die "Cannot open metadata file $in_file.meta\n";
   print OUT "\t", join("\t", @samples), "\n";
   close OUT;
   
   for my $id (sort @samples) {
     my @same_diff = ();
     for my $s (@samples) {
         my @a = ();  #metavalues for A
         my @b = ();  #metavalues for B
         for my $m (@meta) {
            my $s1 = $sample_to_metadata{$id}{$m};
            my $s2 = $sample_to_metadata{$s}{$m};
            push (@a, $s1);
            push (@b, $s2);
        }
        # count for samples
        my $ct = @a;
        $ct = $ct - 1;
  
        #pairwise samenesscheck between A and B
        for my $i ( 0 .. $ct) {
           if (($a[$i] ne 'NA') && ($b[$i] ne 'NA')) {
              if ($a[$i] eq $b[$i] ) {
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
   
    open (OUT, ">>$out_dir/$in_file.meta") || die "Cannot open metadata file $in_file.meta\n";
    print OUT "$id\t", join("\t", @same_diff), "\n";
    close OUT;
   }
   return ("$in_file.meta");
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

sna.pl - social-network analysis

=head1 SYNOPSIS

  sna.pl -o out-dir -m metadata -s seq-matrix

Required Arguments:

  -o|--out-dir     Path to output directory
  -m|--metadir     Path to metadata files
  -s|--seq-matrix  Path to sequence matrix file

Options:
  -e|eucdistper    Eucledean distance percentage (bottom 10% by default)
  -d|sampledist    Maximimum physical distance b/w samples to be called "close" (default 1000 K)  
  -v|--verbose     Be chatty (default yes)
  --help           Show brief help and exit
  --man            Show full documentation

=head1 DESCRIPTION

(1) Creates metadata files that are in matrix format for R
to show similarities and differences for each pairwise 
sample combination

The "metadata" file should look something like this:

        SMAD3+  Hel+
    DNA1    1   1
    DNA2    0   1
    DNA3    1   0
    DNA4    0   0

(2) Creates the R code for running the SNA analysis

(3) Runs the R code for the SNA analysis

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
