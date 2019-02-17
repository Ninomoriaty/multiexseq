FROM nfcore/base
LABEL authors="Qi Zhao" \
      description="Docker image containing all requirements for nf-core/multiexseq pipeline"

COPY environment1.yml environment2.yml ./
COPY /shiny-server-section/shiny-server.sh /usr/bin/shiny-server.sh
COPY /shiny-server-section/shiny-server.conf  /etc/shiny-server/shiny-server.conf
COPY /shiny-server-section/neededapp /srv/shiny-server/

EXPOSE 80

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ed \
		less \
		locales \
		vim-tiny \
		wget \
		ca-certificates \
		fonts-texgyre \
		sudo \
        gdebi-core \
        pandoc \
        pandoc-citeproc \
        libcurl4-gnutls-dev \
        libxt-dev \
        libssl-dev \
        libxml2 \
        libxml2-dev
    && rm -rf /var/lib/apt/lists/*

# R-base
RUN apt-get update \
	&& apt-get install -t unstable -y --no-install-recommends \
		littler \
        r-cran-littler \
		r-base=${R_BASE_VERSION}-* \
		r-base-dev=${R_BASE_VERSION}-* \
		r-recommended=${R_BASE_VERSION}-* \
	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*

# shiny-server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

RUN R -e "install.packages(c('Rcpp', 'shiny', 'rmarkdown', 'tm', 'wordcloud', 'memoise'), repos='http://cran.rstudio.com/')"

# already
RUN wget http://www.openbioinformatics.org/annovar/download/0wgxR2rIVP/annovar.latest.tar.gz && tar -xzvf annovar.latest.tar.gz && rm annovar.latest.tar.gz

ENV PATH /opt/conda/envs/multiexseq_facets/bin:$PATH
RUN conda env create -f /environment1.yml -n multiexseq_facets && conda clean -a

ENV PATH /opt/conda/envs/multiexseq_freec/bin:$PATH
RUN conda env create -f /environment2.yml -n multiexseq_freec && conda clean -a

RUN cd annovar && perl annotate_variation.pl -downdb -buildver hg19 -webfrom annovar refGene humandb/


CMD ["/usr/bin/shiny-server.sh", "/bin/bash"]