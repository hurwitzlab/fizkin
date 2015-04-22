setwd("/gsfs1/rsgrps/bhurwitz/kyclark/fizkin/scripts/workers")
source("/gsfs1/rsgrps/bhurwitz/kyclark/fizkin/scripts/workers/gbme.r")
OUT<-read.table("OUT",header=T)             #read in output

par(mfrow=c(3,4))                           #examine marginal mixing
for(i in 3:dim(OUT)[2]) { plot(OUT[,i],type="l") }

dev.print(device=postscript, "Zgraph1.eps", onefile=FALSE, horizontal=FALSE)


PS<-OUT[OUT$scan>round(max(OUT$scan)/2),-(1:3)]  #posterior samples, dropping
                                                 #the first half of the chain
                                                 #to allow for burn in

#gives mean, std dev, and .025,.5,.975 quantiles
M.SD.Q<-rbind( apply(PS,2,mean),apply(PS,2,sd),
                apply(PS,2,quantile,probs=c(.025,.5,.975)) )

print(M.SD.Q)

#plots of posterior densities
par(mfrow=c(3,4))
for(i in 1:dim(PS)[2]) { plot(density(PS[,i]),main=colnames(PS)[i]) }

dev.print(device=postscript, "Zgraph2.eps", onefile=FALSE, horizontal=FALSE)

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
Z.pm<-tmp$vec[,1:k]%*%sqrt(diag(tmp$val[1:k]))

#now transform each sample Z to a common orientation
for(i in 1:dim(PZ)[3] ) { PZ[,,i]<-proc.rr(PZ[,,i],Z.pm) }

#
if(k==2) {     # a two dimensional plot of "mean" latent locations and marginal confidence regions

r<-atan2(Z.pm[,2],Z.pm[,1])
r<-r+abs(min(r))
r<-r/max(r)
g<-1-r
b<-(Z.pm[,2]^2+Z.pm[,1]^2)
b<-b/max(b)

par(mfrow=c(1,1))
plot(Z.pm[,1],Z.pm[,2],xlab="",ylab="",type="n",xlim=range(PZ[,1,]),
     ylim=range(PZ[,2,]))
abline(h=0,lty=2);abline(v=0,lty=2)

for(i in 1:n) { points( PZ[i,1,],PZ[i,2,],pch=46,col=rgb(r[i],g[i],b[i]) ) }
text(Z.pm[,1],Z.pm[,2], cex = 0.3, labels=c(
'DNA1',
'DNA2',
'DNA3',
'DNA4',
))   #add labels here
    {
dev.print(device=postscript, "Zgraph3.eps", onefile=FALSE, horizontal=FALSE)
