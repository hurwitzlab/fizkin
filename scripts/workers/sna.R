setwd("/gsfs1/rsgrps/bhurwitz/kyclark/fizkin/scripts/workers")
library(xtable)
NS <- 100000
odens <- 10
source("/gsfs1/rsgrps/bhurwitz/kyclark/fizkin/scripts/workers/gbme.r")
Y <- as.matrix(read.table("/gsfs1/rsgrps/bhurwitz/kyclark/fizkin/data-mouse/matrix/matrix.tab", header = TRUE))
n <- nrow(Y)
k <- 2
Xss<-array(NA, dim=c(n,n,k))
SMAD3 <- as.matrix(read.table("SMAD3.txt", header = TRUE))
Xss[,,1] <- SMAD3
Hel <- as.matrix(read.table("Hel.txt", header = TRUE))
Xss[,,2] <- Hel
gbme(Y=Y, Xss, fam="gaussian", k=2, direct=F, NS=NS, odens=odens)
x.names <- c("", "", "intercept")
OUT <- read.table("OUT", header=T)
full.model <- t(apply(OUT, 2, quantile, c(0.5, 0.025, 0.975)))
rownames(full.model)[1:2] <- x.names
table1 <- xtable(full.model[1:2,], align="c|c||cc")
print ( xtable (table1), type= "latex" , file= "table1.tex" )
