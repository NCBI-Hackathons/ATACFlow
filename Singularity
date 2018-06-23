From:nfcore/base
Bootstrap:docker

%labels
    MAINTAINER ATACFlow Team @ RMGCH-18 <evanfloden@gmail.com>
    DESCRIPTION Singularity image containing all requirements for NCBI-Hackathons/ATACFlow pipeline
    VERSION 0.1.0

%environment
    PATH=/opt/conda/envs/ncbihackathons-atacflow-0.1.0/bin:$PATH
    export PATH

%files
    environment.yml /

%post
    pip install dastk
    /opt/conda/bin/conda env create -f /environment.yml
    /opt/conda/bin/conda clean -a
