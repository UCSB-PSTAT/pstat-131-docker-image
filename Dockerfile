FROM rocker/verse:latest

USER root
ENV NB_UID 1000
ENV NB_USER rstudio
ENV VENV_DIR /srv/venv

# Set ENV for all programs...
ENV PATH ${VENV_DIR}/bin:$PATH
# And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron

# The `rsession` binary that is called by nbrsessionproxy to start R doesn't seem to start
# without this being explicitly set
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib

ENV HOME /home/${NB_USER}
WORKDIR ${HOME}

RUN apt-get update && \
    apt-get -y install python3-venv python3-dev && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
RUN mkdir -p ${VENV_DIR} && chown -R ${NB_USER} ${VENV_DIR}

### Non exhaustive list of packages already installed in rocker/verse:
# tidyverse: dplyr, lubridate, magrittr, purrr, readr, tibble, rlang, ...
# some database support: DBI, RMySQL, RPostgreSQL, RSQLite, ...
# ggplot2, shiny
# knitr, rmarkdown (along with pandoc and tex)
# Dev tools: devtools, roxygen2, testthat, Rcpp
# Misc utilities: jsonlite, stringi, MASS

# Note: Install can be memory hungry. Retry with larger memory if you get
# g++: internal compiler error: Killed (program cc1plus)

## USER ${NB_USER}

# ggplot2 extensions
RUN install2.r -s --error -r "https://cloud.r-project.org/" \ 
GGally \
ggridges \
RColorBrewer \
scales \
viridis

# Misc utilities
RUN install2.r -s --error -r "https://cloud.r-project.org/" \ 
beepr \
config \
doParallel \
DT \
foreach \
formattable \
glue \
here \
Hmisc \
httr \
jsonlite \
kableExtra \
logging \
MASS \
microbenchmark \
openxlsx \
pkgdown \
rlang \
RPushbullet \
roxygen2 \
stringr \
styler \
testthat \
usethis  \
imager \
ggridges \
plotmo 


# Caret and some ML packages
RUN install2.r -s --error -r "https://cloud.r-project.org/" \ 
# ML framework
caret \
car \
ensembleR \
# metrics
MLmetrics \
pROC \
ROCR \
# Models
Rtsne \
NbClust \
tree \
maptree \
arm \
e1071 \
elasticnet \ 
fitdistrplus \
gam \
gamlss \
glmnet \
lme4 \
ltm \
randomForest \ 
rpart \
# Data
ISLR 

RUN R -e "devtools::install_github('gbm-developers/gbm3')"
RUN R -e "devtools::install_github('bradleyboehmke/harrypotter')"




RUN python3 -m venv ${VENV_DIR} && \
    # Explicitly install a new enough version of pip
    pip3 install pip==9.0.1 && \
    pip3 install --no-cache-dir \
         notebook==5.2 \
         jupyterhub==0.9.4 \
         nbrsessionproxy==0.6.1 && \
    jupyter serverextension enable --sys-prefix --py nbrsessionproxy && \
    jupyter nbextension install    --sys-prefix --py nbrsessionproxy && \
    jupyter nbextension enable     --sys-prefix --py nbrsessionproxy


RUN wget -P /usr/local/bin https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start.sh && \
    wget -P /usr/local/bin https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-singleuser.sh && \
    wget -P /usr/local/bin https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-notebook.sh && \
    chmod a+x /usr/local/bin/start*.sh

# Extra stuff for pstat 115
# Install essentials
USER root
RUN tlmgr update --self && \
    tlmgr install float mathtools && \
    tlmgr update --self && \
    tlmgr install collection-latexextra

# Using clang to compile Stan
# Using the default g++ causes memory issues
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
clang \
libzmq3-dev \
libcurl4-openssl-dev \
libssl-dev 


RUN install2.r -s --error -r "https://cloud.r-project.org/" \
repr \
IRdisplay \
IRkernel
## jupyter-core \
## jupyter-client



RUN R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')"

RUN install2.r -s -error -r "https://cloud.r-project.org/" \
coda \
loo \
projpred \
MCMCpack \
hflights \
HDInterval \
dendextend

# install_stan.R creates a makevars file and installs rstan from source
# following the instructions at https://github.com/stan-dev/rstan/wiki/Installing-RStan-on-Linux
COPY install_stan.R install_stan.R
RUN ["r", "install_stan.R"]

# Installing the rest 
RUN install2.r -s --error -r "https://cloud.r-project.org/" \
rstantools \ 
shinystan

RUN sudo chmod -R 777 /home/rstudio/.local
USER ${NB_USER}

CMD jupyter notebook --ip 0.0.0.0
