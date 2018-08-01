#FROM nfcore/base
#MAINTAINER ATACFlow Team @ RMGCH-18 <evanfloden@gmail.com>
#LABEL authors="evanfloden@gmail.com" \
#      description="Docker image containing all requirements for NCBI-Hackathons/ATACFlow pipeline"
#RUN pip install dastk --user
#COPY environment.yml /
#RUN conda env create -f /environment.yml && conda clean -a
#ENV PATH /opt/conda/envs/ncbihackathons-atacflow-0.1.0/bin:$PATH
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Ubuntu 16.04 (xenial) from 2018-02-28
# https://github.com/docker-library/official-images/commit/8728671fdca3dfc029be4ab838ab5315aa125181
FROM ubuntu:xenial-20180228@sha256:e348fbbea0e0a0e73ab0370de151e7800684445c509d46195aef73e090a49bd6

LABEL maintainer="Steve Tsa <mylagimail2004@yahoo.com>"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    git \
    curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

ADD fix-permissions /usr/local/bin/fix-permissions
# Create jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    fix-permissions $HOME && \
    fix-permissions $CONDA_DIR

USER $NB_UID

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    fix-permissions /home/$NB_USER

# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION 4.4.10
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "bec6203dbb2f53011e974e9bf4d46e93 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install Jupyter Notebook and Hub
RUN conda install --quiet --yes \
    'notebook=5.4.*' \
    'jupyterhub=0.8.*' \
    'jupyterlab=0.32.*' && \
    conda clean -tipsy && \
    jupyter labextension install @jupyterlab/hub-extension@^0.8.1 && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

USER root

#####  Tools needed for the NextFlow ATACSeq Workflow
RUN pip install dastk
RUN pip install --upgrade --force-reinstall git+https://github.com/nf-core/tools.git
WORKDIR /home/$NB_USER/work
RUN chmod -R 777 /home/$NB_USER/work
#RUN conda install -n base conda
#RUN pip install --upgrade --force-reinstall git+https://github.com/nf-core/tools.git
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/ncbihackathons-atacflow-0.1.0/bin:$PATH
RUN curl -s https://get.nextflow.io | bash
RUN cp nextflow /usr/local/bin/.

RUN git clone https://github.com/NCBI-Hackathons/ATACFlow.git
RUN fix-permissions /home/$NB_USER
RUN fix-permissions $CONDA_DIR

### Graphviz installation
#RUN conda install -c anaconda graphviz - failed
#RUN apt-get install -y 
  
#WORKDIR /opt/
#RUN wget https://graphviz.gitlab.io/pub/graphviz/stable/SOURCES/graphviz.tar.gz 
#RUN tar xvzf graphviz-2.40.1.tar.gz
#WORKDIR /opt/graphviz-2.40.1
#RUN ./configure
#RUN make
#RUN make install
RUN pip install graphviz
#########

USER root
RUN chmod 777 /usr/local/bin/nextflow
EXPOSE 8888

# Configure container startup
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
ENV USER $NB_USER

