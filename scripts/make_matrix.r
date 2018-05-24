#!/usr/bin/env Rscript

suppressMessages(library("optparse"))
suppressMessages(library("R.utils"))

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
  make_option(c("-n", "--read_nums"), 
              type = "character", 
              default = "",
              help = "CSV file with number of reads for each file"
  )
)

opt_parser = OptionParser(option_list = option_list)
opt        = parse_args(opt_parser)
out.dir    = opt$out_dir
mode.dir   = opt$mode_dir
read.nums  = opt$read_nums

if (nchar(mode.dir) == 0) {
  stop("--mode_dir is required")
}

if (!dir.exists(mode.dir)) {
  stop(paste("Bad --mode_dir", matrix_file))
}

if (nchar(read.nums) == 0) {
  stop("--read_nums is required")
}

if (!file.exists(read.nums)) {
  stop("--read_nums must be a file")
}

if (nchar(out.dir) == 0) {
  out.dir = mode.dir
}

if (!dir.exists(out.dir)) {
  dir.create(out.dir)
}

if (!dir.exists(out.dir)) {
  dir.create(out.dir)
}

# mode.dir = "~/work/dolphin/mode/"
# read.nums = "~/work/dolphin/counts.csv"

num.reads = read.csv(read.nums, header=FALSE)
colnames(num.reads) = c('file', 'num')
files = list.files(path = mode.dir, recursive = T, full.names = T)
printf("Processing %s files in '%s'\n", length(files), mode.dir)

samples = sort(unlist(unique(Map(basename, files))))
num.samples = length(samples)
df = data.frame(matrix(data = 0, 
                       nrow = num.samples, 
                       ncol = num.samples))
colnames(df) = samples
rownames(df) = samples

norm.df = df[0,]
for (path in files) {
  s1 = basename(dirname(path)) # the index
  s2 = basename(path) # the query
  n = as.integer(readLines(path))
  s2.reads = num.reads[num.reads$file == s2, 'num']
  df[s1, s2] = n # raw
  norm.df[s1, s2] = n/s2.reads # normalized by the size of the query 
}

# Clone the data.frame structure (no data)
# Fill in with mean of A-B/B-A
avg.df = norm.df[0,]
for (c in colnames(norm.df)) {
  for (r in rownames(norm.df)) {
    # log of a number < 1 is negative, so need to mult/div by 100 (percentage)
    avg.df[r, c] = log(mean(c(norm.df[r,c], norm.df[c,r])) * 100) / 100
  }
}

write.table(df, file = file.path(out.dir, "matrix_raw.tab"))
write.table(norm.df, file = file.path(out.dir, "matrix_norm.tab"))
write.table(avg.df, file = file.path(out.dir, "matrix_norm_log_avg.tab"))
write.table(1 - avg.df, file = file.path(out.dir, "matrix_dist.tab"))

printf("Done, wrote raw/norm files to out_dir '%s'\n", out.dir)
