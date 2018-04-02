library("ggdendro")
library("ggplot2")
library("philentropy")
library("vegan")
library("R.utils")

main = function () {
  dirs = list.dirs("~/work/fizkin-paper", recursive=T)
  Map(mkfigs, dirs[grep(pattern="sna$", dirs)])
  print("Done")
}

mkfigs = function (dir.name) {
  if (!dir.exists(dir.name)) {
    printf("Bad directory '%s'", dir.name)
    return()
  }
  
  print(paste("Processing", dir.name))
  setwd(dir.name)
  
  matrix = "matrix_raw.txt"
  if (!file.exists(matrix)) {
    printf("Missing matrix file '%s'", file.path(dir.name, matrix))
    return()
  }
  
  dat = read.table(matrix, header = TRUE)
  
  fig.dir = "figures"
  if (!dir.exists(fig.dir)) {
    dir.create(fig.dir)
  }
  
  for (dmethod in c("manhattan", "euclidean", "squared_euclidean", "pearson", "avg")) {
    df = as.data.frame(distance(dat, method = dmethod))
    rownames(df) = rownames(dat)
    fit = hclust(as.dist(df), method = "ward.D2") 
    out.file = file.path(fig.dir, paste0(dmethod, ".png"))
    ggsave(out.file, 
           width=5, 
           height=5,
           plot=ggdendro::ggdendrogram(fit, rotate=T) + ggtitle(dmethod))
    
    # PCOA plot
    fiz_pcoa = rda(df)
    p1 = round(fiz_pcoa$CA$eig[1]/sum(fiz_pcoa$CA$eig)*100, digits = 2)
    p2 = round(fiz_pcoa$CA$eig[2]/sum(fiz_pcoa$CA$eig)*100, digits = 2)
    xlabel = paste0("PCoA1 (", p1, "%)")
    ylabel = paste0("PCoA2 (", p2, "%)")
    
    # plot PCoA
    pdf(file.path(fig.dir, paste0("pcoa-", dmethod, ".pdf")), width = 6, height = 6)
    
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
    title(main = dmethod)
    dev.off()
  }
}

main()