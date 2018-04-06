#!/usr/bin/env Rscript

suppressMessages(library("optparse"))
suppressMessages(library("ggdendro"))
suppressMessages(library("ggplot2"))
suppressMessages(library("vegan"))
suppressMessages(library("R.utils"))
suppressMessages(library("reshape2"))

# set arguments
option_list = list (
  make_option(c("-m", "--matrix"), 
              type = "character", 
              default = "",
              help = "Matrix file", 
              metavar="character"
  ),
  make_option(c("-o", "--out_dir"), 
              type = "character", 
              default = '',
              help = "set work directory (--file dir)"
  ),
);

opt_parser  = OptionParser(option_list = option_list)
opt         = parse_args(opt_parser)
out.dir     = opt$out_dir
matrix.file = opt$matrix


# check arguments
if (nchar(matrix.file) == 0) {
  stop("Missing --matrix")
}

if (!file.exists(matrix.file)) {
  stop(paste("Bad matrix file", matrix.file))
}

if (nchar(out.dir) == 0) {
  out.dir = dirname(matrix.file)
}

if (!dir.exists(out.dir)) {
  dir.create(out.dir)
}

#matrix.file = "~/work/fizkin-paper/ecoli_flex/figures/matrix_norm.tab"
#out.dir = dirname(matrix.file)

df = read.table(file = matrix.file, header = TRUE, check.names = F)

# Dendrogram
dist.matrix = as.dist(1 - df)
fit = hclust(dist.matrix, method = "ward.D2") 
out.file = file.path(out.dir, "dendrogram.png")
ggsave(out.file, 
       width=5, 
       height=5,
       plot=ggdendro::ggdendrogram(fit, rotate=T) + ggtitle("Distance"))

# PCOA plot
fiz_pcoa = rda(df)
p1 = round(fiz_pcoa$CA$eig[1]/sum(fiz_pcoa$CA$eig)*100, digits = 2)
p2 = round(fiz_pcoa$CA$eig[2]/sum(fiz_pcoa$CA$eig)*100, digits = 2)
xlabel = paste0("PCoA1 (", p1, "%)")
ylabel = paste0("PCoA2 (", p2, "%)")

# PCoA
pdf(file.path(out.dir, "pcoa.pdf"), 7, 7)
biplot(fiz_pcoa,
       display = "sites",
       col     = "black",
       cex     = 2,
       xlab    = paste(xlabel),
       ylab    = paste(ylabel)
)
points(fiz_pcoa,
       display = "sites",
       col     = "black",
       cex     = .5,
       pch     = 20
)
title(main = "PCOA")
dev.off()

# Heatmap
tri.df = df
tri.df[upper.tri(tri.df)] = NA
counts = na.omit(melt(as.matrix(tri.df)))
colnames(counts) = c("s1", "s2", "value")

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

printf("Done, see output in '%s'\n", out_dir)