# NCBI-Hackathons/ATACFlow Jupyter Notebook

## Using Jupyter Notebooks
A practical way to execute this pipeline and perform downstream analysis is to use a Jupyter Notebook to connect to the instantiated container, thus leaving the heavy computations to the backend and the operation of the workflow to a notebook. We need to make use of port forwarding to accomplish this. In this example, we use  the 8888 port for everything, but it can also be executed with any other available port:

```bash
ssh -L 8888:0.0.0.0:8888 $USERNAME@AWS_public_ip_address
## to run from your laptop (free), start here
docker pull stevetsa/atacflow:0.1.0
#mkdir work  ### where notebooks will be stored
#chmod 777 work
cd work
docker run -it --rm -v `pwd`:`pwd` -w `pwd` -p 8888:8888 stevetsa/atacflow:0.1.0
```

Then, copy and paste the last line of output to your browser:

```bash
"http://localhost:8888/?token=c42bxxxxxxxxxxxxxxxxxxx"
```

A clone of this Github repository is included in the container.  This can be accessed from the notebook terminal. You can create new notebooks, upload or modify notebook to be stored in /home/$USERNAME/work/ (in the AWS instance) 



