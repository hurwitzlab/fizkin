setwd("/gsfs1/rsgrps/bhurwitz/kyclark/fizkin/scripts/workers")
library(xtable)
NS <- 100000
odens <- 10
source("gbme.r")
Y <- as.matrix(read.table("", header = TRUE))
n <- nrow(Y)
k <- 
Xss<-array(NA, dim=c(n,n,k))

gbme(Y=Y, Xss, fam="gaussian", k=2, direct=F, NS=NS, odens=odens)

x.names <- c("", "intercept")

OUT <- read.table("OUT", header=T)
full.model <- t(apply(OUT, 2, quantile, c(0.5, 0.025, 0.975)))
rownames(full.model)[1:] <- x.names
table1 <- xtable(full.model[1:], align="c|c||cc")
print ( xtable (table1), type= "latex" , file= "table1.tex" )
