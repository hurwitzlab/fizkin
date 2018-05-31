FROM python:latest

LABEL Description="Run Fizkin"

WORKDIR /app

RUN git clone https://github.com/hurwitzlab/fizkin.git fizkin
RUN python -m pip install -r /app/fizkin/scripts/requirements.txt

#ENV LD_LIBRARY_PATH=/usr/local/lib

#WORKDIR /app/fizkin/scripts

#RUN jellyfish

#RUN apt-get update \
#    && apt-get install -y locales git build-essential autoconf libtool \
#       pkg-config yaggo wget graphviz curl libcurl4-openssl-dev \
#       python3 python3-pip libssl-dev parallel \
#    && locale-gen en_US.UTF-8 \
#    && mkdir /root/.parallel \
#    && touch /root/.parallel/will-cite \
#    && mkdir -p /app \
#    && cd /app \
#    && wget https://github.com/gmarcais/Jellyfish/releases/download/v2.2.10/jellyfish-2.2.10.tar.gz \
#    && tar xvf jellyfish-2.2.10.tar.gz \
#    && cd jellyfish-2.2.10 \
#    && ./configure && make install \
#    && cd /app \
#    && git clone https://github.com/hurwitzlab/Jellyfish.git jellyfish \
#    && cd jellyfish/examples/query_per_sequence_mode \
#    && make \
#    && cp query_per_sequence /usr/local/bin
#
#RUN cd /app \
#    && git clone https://github.com/hurwitzlab/fizkin.git fizkin \
#    && python3 -m pip install -r /app/fizkin/scripts/requirements.txt

#ENTRYPOINT /app/fizkin/scripts/fizkin.py

#    #
#    # Clone Fizkin 
#    #
#    cd $APP_DIR
#
#    #
#    # Add CRAN to sources to get latest R
#    #
#    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
#    apt-get install -y r-base r-base-dev
# 
#    #
#    # CPAN installs want to use "/bin/make"
#    #
#    ln -s /usr/bin/make /bin/make
#
#    #
#    # Install R modules (need the .Rprofile to indicate CRAN mirror)
#    #
#    cat << EOF > .Rprofile
#local({
#  r = getOption("repos")
#  r["CRAN"] = "http://mirrors.nics.utk.edu/cran/"
#  options(repos = r)
#})
#EOF
#    Rscript /app/fizkin/scripts/install.r
#  
#    # Mount points for TACC directories
#    mkdir /home1
#    mkdir /scratch
#    mkdir /work
