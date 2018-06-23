FROM nfcore/base
MAINTAINER ATACFlow Team @ RMGCH-18 <evanfloden@gmail.com>
LABEL authors="evanfloden@gmail.com" \
      description="Docker image containing all requirements for NCBI-Hackathons/ATACFlow pipeline"

RUN pip install dastk --user
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/ncbihackathons-atacflow-0.1.0/bin:$PATH
