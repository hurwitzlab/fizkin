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
    my $metadata   = '';
    my $seq_matrix = '';
    my $verbose    = 0;
    my ($help, $man_page);

    GetOptions(
        'o|out-dir=s'    => \$out_dir,
        'm|metadata=s'   => \$metadata,
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

    unless ($metadata) {
        pod2usage('No metadata file');
    }

    # step 1 create the metadata tables for the analysis
    # the input is in the format -> id<tab>@metadata (with a header)
    # an output table is created for each metadata field (name = header)
    # the output table has values:
    # 0 =  not the same between pairwise samples 
    # 1 =  the same between pairwise samples
    # these metadata tables match the seq_matrix in format
    # also note the ids and their order should be consistent
    # between the metadata tables and seq_matrix

    open my $M, '<', $metadata;
    my @meta = (); #metadata types
    my %sample_to_metadata = ();
    my @samples;

    my $i = 0;
    while (my $line = <$M>) {
       $i++;
       chomp $line;

       # get the header to define types of metadata
       if ($i == 1) { 
          @meta = split /\t/, $line;
          shift @meta; # remove id
       }
       else {
          my @values = split /\t/, $line;
          my $id = shift @values;
          push @samples, $id;
          for my $m (@meta) {
             my $v = shift @values;
             $sample_to_metadata{ $id }{ $m } = $v;
          }
       }
    }

    # create a file for each column in the metadata 
    # for each pairwise combination of samples
    # where 0 means they differ
    # and 1 means they are the same

    for my $m (@meta) {
       open my $OUT, '>', "$m.txt";
       say $OUT join "\t", '', @samples;
       close $OUT;
    }

    # note that we sort samples to keep them in the same order as the
    # input seq_matrix table
    for my $id (sort @samples) {
        for my $m (@meta) {
            open my $OUT, '>>', "$m.txt";
            my @same_or_not = ();
            for my $s (sort @samples) {
                my $s1 = $sample_to_metadata{$id}{$m};
                my $s2 = $sample_to_metadata{$s}{$m};

                push @same_or_not, $s1 eq $s2;
            }

            say $OUT join "\t", $id, @same_or_not;
            close $OUT;
        }
    }

            
    # now we need to run the SNA analysis
    # be sure that `module load R` has laready been run in the
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
        }, 
        'sna.R'
    ) or die $t->error;

    $t->process(
        \$plot_tmpl, 
        { 
            out_dir => $out_dir,
            #scan    => $scan,
        }, 
        'plot.R'
    ) or die $t->error;

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
   [% SET counter=count + 1 -%]
   [% m %] <- as.matrix(read.table("[% m %].txt", header = TRUE))
   Xss[,, [% counter%] ] <- [% m %]
[% END -%]

gbme(Y=Y, Xss, fam="gaussian", k=2, direct=F, NS=NS, odens=odens)

x.names <- c("[% meta.join('", "')%]", "intercept")

OUT <- read.table("OUT", header=T)
full.model <- t(apply(OUT, 2, quantile, c(0.5, 0.025, 0.975)))
rownames(full.model)[1:[% meta.size %]] <- x.names
table1 <- xtable(full.model[1:[% meta.size %]], align="c|c||cc")
print ( xtable (table1), type= "latex" , file= "table1.tex" )
EOF
}

# --------------------------------------------------
sub template_plot {
    return <<EOF
setwd("[% out_dir %]")
source("gbme.r")
# posterior samples, dropping
# the first half of the chain
# to allow for burn in
PS<-OUT[OUT[% scan %]>round(max(OUT[% scan %])/2),-(1:3)]  

#gives mean, std dev, and .025,.5,.975 quantiles
M.SD.Q<-rbind( apply(PS,2,mean),apply(PS,2,sd)
  apply(PS,2,quantile,probs=c(.025,.5,.975)) )

print(M.SD.Q)

#plots of posterior densities
par(mfrow=c(3,4))
for(i in 1:dim(PS)[2]) { plot(density(PS[,i]),main=colnames(PS)[i]) }

postscript("Zgraph2.eps", width = 12, height = 17, horizontal = FALSE,onefile = FALSE, paper = "special", colormodel = "cmyk",family = "Courier")"

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
Z.pm<-tmp[% vec %][,1:k]%*%sqrt(diag(tmp[% val %][1:k]))

#now transform each sample Z to a common orientation
for(i in 1:dim(PZ)[3] ) { PZ[,,i]<-proc.rr(PZ[,,i],Z.pm) }

#
# a two dimensional plot of "mean" latent locations 
# and marginal confidence regions
#
if(k==2) {     

    r<-atan2(Z.pm[,2],Z.pm[,1])
    r<-r+abs(min(r))
    r<-r/max(r)
    g<-1-r
    b<-(Z.pm[,2]^2+Z.pm[,1]^2)
    b<-b/max(b)

    par(mfrow=c(1,1))
    plot(Z.pm[,1],Z.pm[,2],xlab="",ylab="",type="n",xlim=range(PZ[,1,])
         ylim=range(PZ[,2,]))
    abline(h=0,lty=2);abline(v=0,lty=2)

    for(i in 1:n) { points( PZ[i,1,],PZ[i,2,],pch=46,col=rgb(r[i],g[i],b[i]) ) }
    [% SET labels = [] %]
    [% FOREACH id IN samples -%]
       [% labels.push("'" _ id _ "'") -%]
    [% END -%]
    text(Z.pm[,1],Z.pm[,2], cex = 0.3, labels=c([% labels.join(',') %]))   #add labels here
}

postscript("Zgraph3.eps", width = 12, height = 17, horizontal = FALSE,onefile = FALSE, paper = "special", colormodel = "cmyk",family = "Courier")"
EOF
}

#    # first part is to run the SNA analysis
#    open (R1, ">sna.R") || die "Cannot open sna.R for writing\n";
#
#    print R1 'setwd("', $out_dir, '")', "\n";
#    print R1 'library(xtable)', "\n";
#    print R1 'NS <- 100000', "\n";       
#    print R1 'odens <- 10', "\n";
#    print R1 'source("gbme.r")', "\n";
#    print R1 'Y <- as.matrix(read.table("', $seq_matrix, '", header = TRUE))', "\n";
#    print R1 'n <- nrow(Y)', "\n";
#
#    my $meta_count = @meta;
#    my $counter = 0;
#    print R1 'k <- ', $meta_count, "\n";
#    print R1 'Xss<-array(NA, dim=c(n,n,k))', "\n";
#    for my $m (@meta) {
#       $counter++;
#       print R1 $m, ' <- as.matrix(read.table("', $m , '.txt", header = TRUE))', "\n";
#       print R1 'Xss[,,', $counter, '] <- ', $m, "\n"; 
#    }
#
#    print R1 'gbme(Y=Y, Xss, fam="gaussian", k=2, direct=F, NS=NS, odens=odens)', "\n";
#
#    print R1 'x.names <- c("', join(@meta, '", "'), '", "intercept")', "\n";
#
#    print R1 'OUT <- read.table("OUT", header=T)', "\n";
#    print R1 'full.model <- t(apply(OUT, 2, quantile, c(0.5, 0.025, 0.975)))', "\n";
#    print R1 'rownames(full.model)[1:', $meta_count, '] <- x.names', "\n";
#    print R1 'table1 <- xtable(full.model[1:', $meta_count, ',], align="c|c||cc")', "\n";
#    print R1 'print ( xtable (table1), type= "latex" , file= "table1.tex" )', "\n";
#    close R1;
#
#    my $cmd1 = `R CMD BATCH --slave sna.R`;
#
#    ## create the plot
#    open (R2, ">plot.R") || die "Cannot open sna.R for writing\n";
#
#    print R2 'setwd("', $out_dir, '")', "\n";
#    print R2 'source("gbme.r")', "\n";
#
#    print R2 'OUT<-read.table("OUT",header=T)             #read in output', "\n";
#    print R2 '', "\n";
#    print R2 'par(mfrow=c(3,4))                           #examine marginal mixing', "\n";
#    print R2 'for(i in 3:dim(OUT)[2]) { plot(OUT[,i],type="l") }', "\n";
#    print R2 '', "\n";
#    print R2 'postscript(“Zgraph1.eps", width = 12, height = 17, horizontal = FALSE,onefile = FALSE, paper = "special", colormodel = "cmyk",family = "Courier")"', "\n";
#    print R2 '', "\n";
#    print R2 '', "\n";
#    print R2 'PS<-OUT[OUT$scan>round(max(OUT$scan)/2),-(1:3)]  #posterior samples, dropping', "\n";
#    print R2 '                                                 #the first half of the chain', "\n";
#    print R2 '                                                 #to allow for burn in', "\n";
#    print R2 '', "\n";
#    print R2 '#gives mean, std dev, and .025,.5,.975 quantiles', "\n";
#    print R2 'M.SD.Q<-rbind( apply(PS,2,mean),apply(PS,2,sd),', "\n";
#    print R2 '                apply(PS,2,quantile,probs=c(.025,.5,.975)) )', "\n";
#    print R2 '', "\n";
#    print R2 'print(M.SD.Q)', "\n";
#    print R2 '', "\n";
#    print R2 '#plots of posterior densities', "\n";
#    print R2 'par(mfrow=c(3,4))', "\n";
#    print R2 'for(i in 1:dim(PS)[2]) { plot(density(PS[,i]),main=colnames(PS)[i]) }', "\n";
#    print R2 '', "\n";
#    print R2 'postscript(“Zgraph2.eps", width = 12, height = 17, horizontal = FALSE,onefile = FALSE, paper = "special", colormodel = "cmyk",family = "Courier")"', "\n";
#    print R2 '', "\n";
#    print R2 '###analysis of latent positions', "\n";
#    print R2 'Z<-read.table("Z")', "\n";
#    print R2 '', "\n";
#    print R2 '#convert to an array', "\n";
#    print R2 'nss<-dim(OUT)[1]', "\n";
#    print R2 'n<-dim(Z)[1]/nss', "\n";
#    print R2 'k<-dim(Z)[2]', "\n";
#    print R2 'PZ<-array(dim=c(n,k,nss))', "\n";
#    print R2 'for(i in 1:nss) { PZ[,,i]<-as.matrix(Z[ ((i-1)*n+1):(i*n) ,])  }', "\n";
#    print R2 '', "\n";
#    print R2 'PZ<-PZ[,,-(1:round(nss/2))]     #drop first half for burn in', "\n";
#    print R2 '', "\n";
#    print R2 '#find posterior mean of Z %*% t(Z)', "\n";
#    print R2 'ZTZ<-matrix(0,n,n)', "\n";
#    print R2 'for(i in 1:dim(PZ)[3] ) { ZTZ<-ZTZ+PZ[,,i]%*%t(PZ[,,i]) }', "\n";
#    print R2 'ZTZ<-ZTZ/dim(PZ)[3]', "\n";
#    print R2 '', "\n";
#    print R2 '#a configuration that approximates posterior mean of ZTZ', "\n";
#    print R2 'tmp<-eigen(ZTZ)', "\n";
#    print R2 'Z.pm<-tmp$vec[,1:k]%*%sqrt(diag(tmp$val[1:k]))', "\n";
#    print R2 '', "\n";
#    print R2 '#now transform each sample Z to a common orientation', "\n";
#    print R2 'for(i in 1:dim(PZ)[3] ) { PZ[,,i]<-proc.rr(PZ[,,i],Z.pm) }', "\n";
#    print R2 '', "\n";
#    print R2 '#', "\n";
#    print R2 'if(k==2) {     # a two dimensional plot of "mean" latent locations and marginal confidence regions', "\n";
#    print R2 '', "\n";
#    print R2 'r<-atan2(Z.pm[,2],Z.pm[,1])', "\n";
#    print R2 'r<-r+abs(min(r))', "\n";
#    print R2 'r<-r/max(r)', "\n";
#    print R2 'g<-1-r', "\n";
#    print R2 'b<-(Z.pm[,2]^2+Z.pm[,1]^2)', "\n";
#    print R2 'b<-b/max(b)', "\n";
#    print R2 '', "\n";
#    print R2 'par(mfrow=c(1,1))', "\n";
#    print R2 'plot(Z.pm[,1],Z.pm[,2],xlab="",ylab="",type="n",xlim=range(PZ[,1,]),', "\n";
#    print R2 '     ylim=range(PZ[,2,]))', "\n";
#    print R2 'abline(h=0,lty=2);abline(v=0,lty=2)', "\n";
#    print R2 '', "\n";
#    print R2 'for(i in 1:n) { points( PZ[i,1,],PZ[i,2,],pch=46,col=rgb(r[i],g[i],b[i]) ) }', "\n";
#    print R2 'text(Z.pm[,1],Z.pm[,2], cex = 0.3, labels=c(', "\n";
#    for my $id (@samples) {
#       print R2 "'", $id, "',", "\n";
#    }
#    print R2 '))   #add labels here', "\n";
#    print R2 '    {', "\n";
#    print R2 'postscript(“Zgraph3.eps", width = 12, height = 17, horizontal = FALSE,onefile = FALSE, paper = "special", colormodel = "cmyk",family = "Courier")"', "\n"; 
#    #print R2 'print ( type= "eps" , file= "Zgraph3.eps" )', "\n";
#    #print R2 'dev.print(device=postscript, "Zgraph3.eps", onefile=FALSE, horizontal=FALSE)', "\n";
#
#
#    my $cmd2 = `R CMD BATCH --slave plot.R`;
#}


__END__

# --------------------------------------------------

=pod

=head1 NAME

sna.pl - social-network analysis

=head1 SYNOPSIS

  sna.pl -o out-dir -m metadata -s seq-matrix

Required Arguments:

  -o|--out-dir     Path to output directory
  -m|--metadata    Path to metadata file
  -s|--seq-matrix  Path to sequence matrix file

Options:

  -v|--verbose     Be chatty (default yes)
  --help           Show brief help and exit
  --man            Show full documentation

=head1 DESCRIPTION

Runs the social-network analysis on the output of "make-matrix.pl."

The "metadata" file should look something like this:

        SMAD3+	Hel+
    DNA1	1	1
    DNA2	0	1
    DNA3	1	0
    DNA4	0	0

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
