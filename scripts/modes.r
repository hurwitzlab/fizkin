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

mode.dir = "~/work/fizkin-paper/mode"
out.dir = "~/work/fizkin-paper/dendrograms"
num.reads = 500000

if (!dir.exists(out.dir)) {
  dir.create(out.dir)
}

files = list.files(path = mode.dir, recursive = T)
printf("Processing %s files in '%s'\n", length(files), mode.dir)

samples = sort(unlist(unique(Map(basename, files))))
num.samples = length(samples)
df = data.frame(matrix(data = 0, 
                       nrow = num.samples, 
                       ncol = num.samples, 
                       dimnames = list(samples, samples)))

for (path in files) {
  s1 = basename(dirname(path))
  s2 = basename(path)
  df[s1, s2] = as.integer(readLines(path))
  # df[s1, s2] = as.integer(readLines(file.path(mode.dir, file)))
}

avg.df = df[0,]
for (c in colnames(df)) {
  for (r in rownames(df)) {
    avg.df[r, c] = as.integer(mean(c(df[r,c], df[c,r])))
  }
}

write.table(df, file = file.path(out.dir, "matrix_raw.tab"))
write.table(norm.df, file = file.path(out.dir, "matrix_norm.tab"))

norm.df = avg.df/num.total.reads
fit = hclust(as.dist(1 - norm.df), method = "ward.D2") 
ggdendro::ggdendrogram(fit, rotate=T) + ggtitle("Distance")


pdf(file = file.path(mode.dir, "heatmap.pdf"), width = 500, height = 500)
heatmap.2(as.matrix(norm.df), 
          main = "foo",
          density.info="none",
          trace="none", 
          dendrogram = "row",
          key=F, 
          cexRow = 1,
          cexCol = 1,
          margins = c(12,12),
          Colv="NA",
          srtCol = 45)
graphics.off()
dev.off()

library("reshape2")

tri.df = df
tri.df[upper.tri(tri.df)] = NA
counts = na.omit(melt(as.matrix(tri.df)))
colnames(counts) = c("s1", "s2", "value")

#counts$s1 = factor(counts$s1, levels=ordered.names)
#counts$s2 = factor(counts$s2, levels=ordered.names)

ggplot(counts, aes(s1, s2)) +
  ggtitle('Foo') +
  theme_bw() +
  xlab('Sample1') +
  ylab('Sample2') +
  geom_tile(aes(fill = value), color='white') +
  scale_fill_gradient(low = 'white', high = 'darkblue', space = 'Lab') +
  theme(axis.text.x=element_text(angle=90),
        axis.ticks=element_blank(),
        axis.line=element_blank(),
        panel.border=element_blank(),
        panel.grid.major=element_line(color='#eeeeee'))

ggplot(counts, aes(s1, value)) +
  theme_bw() +
  geom_point(aes(color=s1)) +
  theme(axis.text.x=element_text(angle=90))


