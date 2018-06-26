# NCBI-Hackathons/ATACFlow

![](https://raw.githubusercontent.com/NCBI-Hackathons/ATACFlow/master/docs/ATAC_logo.png) 

This pipeline performs ATAC Seq using Nextflow

[![Build Status](https://travis-ci.org/NCBI-Hackathons/ATACFlow.svg?branch=master)](https://travis-ci.org/NCBI-Hackathons/ATACFlow)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.30.0-brightgreen.svg)](https://www.nextflow.io/)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/stevetsa/atacflow.svg)](https://hub.docker.com/r/stevetsa/atacflow)
![Singularity Container available](
https://img.shields.io/badge/singularity-available-7E4C74.svg)

### Introduction
NCBI-Hackathons/ATACFlow: This pipeline performs ATAC Seq using Nextflow

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker / singularity containers making installation trivial and results highly reproducible.


### Documentation
The NCBI-Hackathons/ATACFlow pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](docs/installation.md)
2. Pipeline configuration
    * [Docker installation](docs/configuration/local.md)
    * [Adding your HPC](docs/configuration/adding_your_own.md)
3. [Running the pipeline](docs/usage.md)
4. [Pipeline Components](docs/output.md)
5. [Troubleshooting](docs/troubleshooting.md)
6. [Operating with Jupyter Notebook](docs/jupyter.md)

### Credits
This pipeline was written by ATACFlow Team @ [RMGCH-18](https://hackathon.colorado.edu/rmgh-2018-hackathon/) ([NCBI-Hackathons](https://github.com/NCBI-Hackathons)).

* Ignacio Tripodi (ignacio.tripodi at colorado.edu): Computer Scientist, closet wet-lab enthusiast
* Steve Tsang (hsinyi.tsang at nih.gov): Computational Biologist
* Jingjing Zhao (jjzhao123 at gmail.com): Bioinformatics Postdoctoral Scholar
* Evan Floden (evanfloden at gmail.com): Workflow Wrangler
* Chi Zhang (chzh1418 at colorado.edu): 
