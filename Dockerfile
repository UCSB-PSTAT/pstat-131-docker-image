FROM rocker/verse:3.4.3

ENV NB_USER rstudio
ENV NB_UID 1000
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

USER ${NB_USER}

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

RUN R --quiet -e "devtools::install_github('IRkernel/IRkernel')" && \
    R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')"

RUN R -e "install.packages(c('e1071', 'kableExtra', 'ggmap', 'Rtsne', 'NbClust', 'tree', 'maptree', 'glmnet', 'randomForest', 'ROCR', 'imager', 'ISLR', 'ggridges', 'plotmo'), repos = 'http://cran.us.r-project.org')" && \
    R -e "devtools::install_github('gbm-developers/gbm3')"
    
RUN wget -P /usr/local/bin https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start.sh && \
    wget -P /usr/local/bin https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-singleuser.sh && \
    wget -P /usr/local/bin https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook/start-notebook.sh && \
    chmod a+x /usr/local/bin/start*.sh


CMD jupyter notebook --ip 0.0.0.0
