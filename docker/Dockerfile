FROM perl:latest

MAINTAINER Ken Youens-Clark <kyclark@email.arizona.edu>

COPY local /usr/local/

COPY scripts /usr/local/bin/

COPY scripts/Fizkin.pm /usr/local/cpan/local/lib/perl5/

RUN apt-get update && apt-get install r-base -y

WORKDIR /usr/local/r

RUN R CMD INSTALL xtable_1.8-0.tar.gz

RUN curl -L http://cpanmin.us | perl - App::cpanminus

RUN cpanm Carton

WORKDIR /usr/local/cpan

RUN carton install 

ENV PERL5LIB /usr/local/cpan/local/lib/perl5/

ENV LD_LIBRARY_PATH=/usr/local/lib

ENTRYPOINT ["run-fizkin.pl"]
