#!/usr/bin/env Rscript

library("optparse")
library("R.utils")
library("ggdendro")
library("ggplot2")
library("gplots")

option_list = list (
  make_option(c("-m", "--mode_dir"), 
              type = "character", 
              default = "",
              help = "Mode directory", 
              metavar="character"
  ),
  make_option(c("-o", "--out_dir"), 
              type = "character", 
              default = '',
              help = "Output directory (--file dir)"
  ),
  make_option(c("-n", "--num_reads"), 
              type = "integer", 
              default = 0,
              help = "Number of reads for normalization"
  )
)

opt_parser = OptionParser(option_list = option_list)
opt        = parse_args(opt_parser)
out.dir    = opt$out_dir
mode.dir   = opt$mode_dir
num.reads  = opt$num_reads

if (nchar(mode.dir) == 0) {
  stop("Missing --mode_dir")
}

if (!dir.exists(mode.dir)) {
  stop(paste("Bad --mode_dir", matrix_file))
}

if (num.reads <= 0) {
  stop("--num_reads must be a postive integer")
}

if (nchar(out.dir) == 0) {
  out.dir = mode.dir
}

if (!dir.exists(out.dir)) {
  dir.create(out.dir)
}

mode.dir = "~/work/fizkin-paper/ecoli_flex/mode"
out.dir = "~/work/fizkin-paper/ecoli_flex/sna"
num.reads = 500000

if (!dir.exists(out.dir)) {
  dir.create(out.dir)
}

files = list.files(path = mode.dir, recursive = T, full.names = T)
printf("Processing %s files in '%s'\n", length(files), mode.dir)

samples = sort(unlist(unique(Map(basename, files))))
num.samples = length(samples)
df = data.frame(matrix(data = 0, 
                       nrow = num.samples, 
                       ncol = num.samples))
colnames(df) = samples
rownames(df) = samples

for (path in files) {
  s1 = basename(dirname(path))
  s2 = basename(path)
  df[s1, s2] = as.integer(readLines(path))
}

# Clone the data.frame structure (no data)
# Fill in with mean of A-B/B-A
avg.df = df[0,]
for (c in colnames(df)) {
  for (r in rownames(df)) {
    avg.df[r, c] = as.integer(mean(c(df[r,c], df[c,r])))
  }
}

# Normalize and invert for distance 
norm.df = avg.df/num.reads
dist.df = 1 - norm.df

write.table(avg.df, file = file.path(out.dir, "matrix_raw.tab"))
write.table(norm.df, file = file.path(out.dir, "matrix_norm.tab"))
write.table(dist.df, file = file.path(out.dir, "matrix_dist.tab"))

printf("Done, wrote raw/norm files to out_dir '%s'\n", out.dir)