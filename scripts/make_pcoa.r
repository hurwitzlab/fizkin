#!/usr/bin/env Rscript

library("optparse")

# set arguments
option_list <- list (
    make_option(c("-d","--dir"), type = "character", default = "$HOME",
                help = "set work directory [default= %default]"),  
    make_option(c("-f","--file"), type = "character", default=NULL,
                help="data file name", metavar="character"),
    make_option(c("-o","--out"), type = "character", default="out",
                help="output file name [default= %default]"),
    make_option(c("-n","--number"), type = "integer", default=NULL,
                help="total number of reads per sample"),
    make_option(c("-t","--title"), type = "character", default=NULL,
                help="title of PCoA plot [default= %default]")
);

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# check arguments
if (is.null(opt$file) | is.null(opt$number)) {
  print_help(opt_parser)
  stop("data file or total number of reads are missing", call.=FALSE)
}

# make PCoA
library(vegan)
setwd(opt$dir)

# input fizkin matrix
fiz <- as.data.frame(read.table(opt$file,header=TRUE,
                                sep = ",",row.names = 1))
colnames(fiz) <- row.names(fiz)

# scaling to mash range (0 to 1)
fiz <- fiz/opt$number

# make euclidean distance matrix 
fiz_dis <- as.data.frame(as.matrix(dist(fiz,method="euclidean")))

# calculate PCoA 
fiz_pcoa <- rda(fiz_dis[1:9])

# calculating PCoA1% and PCoA2%
pcoa1_number <- round(fiz_pcoa$CA$eig[1]/sum(fiz_pcoa$CA$eig)*100,digits = 2)
pcoa2_number <- round(fiz_pcoa$CA$eig[2]/sum(fiz_pcoa$CA$eig)*100,digits = 2)

# make x-y label name
xlabel <- paste("PCoA1",paste('(',pcoa1_number,'%',')', sep=''))
ylabel <- paste("PCoA2",paste('(',pcoa2_number,'%',')', sep=''))

# plot PCoA
setEPS()
postscript(opt$out)
biplot(fiz_pcoa,display = "sites",col="red",cex=2,
       xlab= paste(xlabel),
       ylab= paste(ylabel))
points(fiz_pcoa,display = "sites",cex =1.5,pch=20,col="red")
title(main = opt$title)
dev.off()
