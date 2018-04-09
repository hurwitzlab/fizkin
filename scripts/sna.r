#!/usr/bin/env Rscript

#
# Runs the social network analysis using Peter Hoff's GBME
#
suppressMessages(library("hash"))
suppressMessages(library("igraph"))
suppressMessages(library("networkD3"))
suppressMessages(library("optparse"))
suppressMessages(library("R.utils"))
suppressMessages(library("vegan"))
suppressMessages(library("xtable"))

cargs = commandArgs(trailingOnly = FALSE)
source_dir = dirname(sub("^--file=", "", cargs[grep("^--file=", cargs)]))
source(file.path(source_dir, "gbme.r"))

option_list = list(
  make_option(
    c("-m", "--matrix"),
    default = "",
    type = "character",
    help = "Similarity matrix",
    metavar = "character"
  ),
  make_option(
    c("-o", "--out_dir"),
    default = "",
    type = "character",
    help = "outdir",
    metavar = "character"
  ),
  make_option(
    c("-s", "--sna"),
    default = "sna-gbme.pdf",
    type = "character",
    help = "GBME SNA output filename",
    metavar = "character"
  ),
  make_option(
    c("-n", "--number"),
    default = as.integer(50000),
    type = "integer",
    help = "Number of GBME iterations",
    metavar = "integer"
  ),
  make_option(
    c("-a", "--alias"),
    default = "",
    type = "character",
    help = "Sample name alias file",
    metavar = "alias"
  )
);

opt_parser   = OptionParser(option_list = option_list);
opt          = parse_args(opt_parser);
matrix.file  = opt$matrix  
out.dir      = opt$out_dir
n_iter       = opt$number
alias.file   = opt$alias
sna.filename = opt$sna

Y = as.matrix(read.table(matrix.file, header = TRUE))

if (nchar(matrix.file) == 0) {
  stop("Missing matrix file argument")
}

if (!file.exists(matrix.file)) {
  stop(paste("Invalid --matrix", matrix.file))
}

if (nchar(out.dir) == 0) {
  out.dir = dirname(matrix.file)
}

if (!dir.exists(out.dir)) {
  printf("Creating outdir '%s'\n", out.dir)
  dir.create(out.dir)
}

GBME_OUT = file.path(out.dir, "gbme.out")

# Look for the "*.meta" files 
meta_dir = file.path(out.dir, "meta")

Xss = NULL
if (dir.exists(meta_dir)) {
  meta_files = list.files(path = meta_dir, pattern = "*.meta$")
  print(meta_files)
  k = length(meta_files)
  
  printf("Found %s file%s in meta dir '%s'\n", k, 
         if (k == 1) { '' } else {'s'}, meta_dir)
  
  if (k > 0) {
    n = length(readLines(file.path(meta_dir, meta_files[1]))) - 1
    Xss = array(NA, dim = c(n,n,k))
    
    for (i in 1:k) {
      file = file.path(meta_dir, meta_files[i])
      Xss[,,i] = as.matrix(read.table(file, header = TRUE))
    }
  }
  print(Xss)
}

printf("Reading %s matrix\n", matrix.file)
Y = as.matrix(read.table(matrix.file, header = TRUE))
#print(Y)
n = nrow(Y)
args = c(Xss, fam = "gaussian", k = 2, direct = F, NS = n_iter, odens = 10, ofilename = GBME_OUT)

printf("Running GBME with %s scans\n", n_iter)

if (is.null(Xss)) {
  gbme(Y = Y, fam = "gaussian", k = 2, direct = F, NS = n_iter, odens = 10, ofilename = GBME_OUT)
} else {
  gbme(Y = Y, Xss, fam = "gaussian", k = 2, direct = F, NS = n_iter, odens = 10, ofilename = GBME_OUT)
}

if (!file.exists(GBME_OUT)) {
  stop("Failed to run GBME!")
}

printf("Using GBME_OUT '%s'\n", GBME_OUT)

x.names = c("", "", "", "intercept")
OUT = read.table(GBME_OUT, header = T)
full.model = t(apply(OUT, 2, quantile, c(0.5, 0.025, 0.975)))
rownames(full.model)[1:4] = x.names
table1 = xtable(full.model[1:4,], align = "c|c||cc")
print(xtable(table1), type = "latex", file = "table1.tex")

#
# examine marginal mixing
#
par(mfrow = c(3,4))
pdf(file.path(out.dir, "marginal-mixing.pdf"), width = 6, height = 6)
for (i in 3:dim(OUT)[2]) {
  plot(OUT[,i],type = "l")
}
dev.off()

# posterior samples, dropping
# the first half of the chain
# to allow for burn in
PS <- OUT[OUT$scan > round(max(OUT$scan) / 2),-(1:3)]

#
# gives mean, std dev, and .025,.5,.975 quantiles
#
M.SD.Q <-
  rbind(apply(PS,2,mean),
        apply(PS,2,sd),
        apply(PS,2,quantile,probs = c(.025, .5, .975)))

print(M.SD.Q)

#
# plots of posterior densities
#
pdf(file.path(out.dir, "posterior-densities.pdf"), width = 6, height = 6)
par(mfrow = c(3,4))
for (i in 1:dim(PS)[2]) {
  plot(density(PS[,i]),main = colnames(PS)[i])
}
dev.off()

#
# analysis of latent positions
#
Z <- read.table("Z")

#
# convert to an array
#
nss <- dim(OUT)[1]
n <- dim(Z)[1] / nss
k <- dim(Z)[2]
PZ <- array(dim = c(n,k,nss))
for (i in 1:nss) {
  PZ[,,i] <- as.matrix(Z[((i - 1) * n + 1):(i * n) ,])
}

PZ <- PZ[,,-(1:round(nss / 2))] #drop first half for burn in

#
# find posterior mean of Z %*% t(Z)
#
ZTZ <- matrix(0,n,n)
for (i in 1:dim(PZ)[3]) {
  ZTZ <- ZTZ + PZ[,,i] %*% t(PZ[,,i])
}
ZTZ <- ZTZ / dim(PZ)[3]

#
# a configuration that approximates posterior mean of ZTZ
#
tmp <- eigen(ZTZ)
Z.pm <- tmp$vec[, 1:k] %*% sqrt(diag(tmp$val[1:k]))

#now transform each sample Z to a common orientation
for (i in 1:dim(PZ)[3]) {
  PZ[,,i] <- proc.rr(PZ[,,i],Z.pm)
}

#
# a two dimensional plot of "mean" latent locations
# and marginal confidence regions
#
k <- 2
if (k == 2) {
  r <- atan2(Z.pm[,2], Z.pm[,1])
  r <- r + abs(min(r))
  r <- r / max(r)
  g <- 1 - r
  b <- (Z.pm[,2] ^ 2 + Z.pm[,1] ^ 2)
  b <- b / max(b)
  
  par(mfrow = c(1,1))
  pdf(file.path(out.dir, sna.filename), width = 6, height = 6)
  plot(
    Z.pm[,1],
    Z.pm[,2],
    xlab = "",
    ylab = "",
    type = "n",
    xlim = range(PZ[,1,]),
    ylim = range(PZ[,2,])
  )
  
  abline(h = 0,lty = 2);abline(v = 0,lty = 2)
  
  for (i in 1:n) {
    points(PZ[i,1,], 
           PZ[i,2,], 
           pch = 46, 
           col = rgb(r[i], g[i], b[i]))
  }
  
  # add labels here
  labels = rownames(Y)
  if (length(alias.file) > 0 & file.exists(alias.file)) {
    printf("Using alias file '%s'\n", alias.file)
    aliases = read.table(alias.file, header=T, as.is=T)
    for (i in 1:length(labels)) {
      label = labels[i]
      alias = aliases[aliases$name == label, "alias"]
      if (length(alias) > 0) {
        printf("Alias '%s' -> '%s'\n", label, alias)
        labels[i] = alias
      }
    }
  }
  
  text(Z.pm[,1],Z.pm[,2], cex = 0.3, labels = labels)   
  dev.off()
}

printf("Done, see output dir '%s'\n", out.dir)