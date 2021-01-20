FROM ucsb/r-base:v20210120.1

LABEL maintainer="Patrick Windmiller <windmiller@pstat.ucsb.edu>"

USER root

#-- RSTAN
#-- install rstan reqs
RUN R -e "install.packages(c('inline','gridExtra','loo'))"
#-- install rstan
RUN R -e "dotR <- file.path(Sys.getenv('HOME'), '.R'); if(!file.exists(dotR)){ dir.create(dotR) }; Makevars <- file.path(dotR, 'Makevars'); if (!file.exists(Makevars)){  file.crea$
RUN R -e "install.packages(c('ggplot2','StanHeaders'))"
RUN R -e "packageurl <- 'http://cran.r-project.org/src/contrib/Archive/rstan/rstan_2.19.3.tar.gz'; install.packages(packageurl, repos = NULL, type = 'source')"

#-- ggplot2 extensions
RUN R -e "install.packages(c('GGally','ggridges','viridis'))"

#-- Misc utilities
RUN R -e "install.packages(c('beepr','config','tinytex','rmarkdown','formattable','here','Hmisc'))"

RUN R -e "install.packages(c('kableExtra','logging','microbenchmark','openxlsx'))"

RUN R -e "install.packages(c('RPushbullet','styler','ggridges','plotmo'))"

RUN R -e "install.packages(c('nloptr'))"

RUN R --vanilla -e "install.packages('minqa',repos='https://cloud.r-project.org', dependencies=TRUE)"

#-- Caret and some ML packages
#-- ML framework, metrics and Models
RUN R -e "install.packages(c('codetools'))"
RUN R --vanilla -e "install.packages('caret',repos='https://cloud.r-project.org')"
RUN R -e "install.packages(c('car','ensembleR','MLmetrics','pROC','ROCR','Rtsne','NbClust'))"

RUN apt-get update && apt-get install -y \
    nano && \
    apt-get clean && rm -rf /var/lib/lists/*

RUN R -e "install.packages(c('tree','maptree','arm','e1071','elasticnet','fitdistrplus','gam','gamlss','glmnet','lme4','ltm','randomForest','rpart','ISLR'))"

#-- More Bayes stuff
RUN R -e "install.packages(c('coda','projpred','MCMCpack','hflights','HDInterval','tidytext','dendextend','LearnBayes'))"

RUN R -e "install.packages(c('rstantools', 'shinystan'))"

RUN R -e "install.packages(c('mvtnorm','dagitty','tidyverse'))"

RUN R -e "devtools::install_github('rmcelreath/rethinking', upgrade = c('never'))"

#-- Cairo
#-- Cairo Requirements
RUN apt-get update && apt-get install -y \
    libpixman-1-dev \
    libcairo2-dev \
    libxt-dev && \
    apt-get clean && rm -rf /var/lib/lists/*
RUN R -e "install.packages(c('Cairo'))"

#install nano editor
RUN apt-get update && apt-get install -y \
    nano && \
    apt-get clean && rm -rf /var/lib/lists/*

USER $NB_USER
