#!/usr/bin/env python
from __future__ import print_function
from collections import OrderedDict
import re

regexes = {
    'NCBI-Hackathons/ATACFlow': ['v_pipeline.txt', r"(\S+)"],
    'Nextflow': ['v_nextflow.txt', r"(\S+)"],
    'FastQC': ['v_fastqc.txt', r"FastQC v(\S+)"],
    'MultiQC': ['v_multiqc.txt', r"multiqc, version (\S+)"],
    'Trim Galore!': ['v_trim_galore.txt', r"version (\S+)"],
    'Samtools': ['v_samtools.txt', r"samtools (\S+)"],
    'Bowtie2': ['v_bowtie2.txt', r"version (\S+)"],
    'fastq-dump': ['v_fastq-dump.txt', r"fastq-dump : (\S+)"],
    'Bedtools': ['v_bedtools.txt', r"bedtools v(\S+)"],
    'IGV Tools': ['v_igv-tools.txt', r"IGV Version (\S+)"],
    'MACS2': ['v_macs2.txt', r"macs2 (\S+)"]

}
results = OrderedDict()
results['NCBI-Hackathons/ATACFlow'] = '<span style="color:#999999;\">N/A</span>'
results['Nextflow'] = '<span style="color:#999999;\">N/A</span>'
results['FastQC'] = '<span style="color:#999999;\">N/A</span>'
results['MultiQC'] = '<span style="color:#999999;\">N/A</span>'

# Search each file using its regex
for k, v in regexes.items():
    with open(v[0]) as x:
        versions = x.read()
        match = re.search(v[1], versions)
        if match:
            results[k] = "v{}".format(match.group(1))

# Dump to YAML
print ('''
id: 'ncbi-hackathons/atacflow-software-versions'
section_name: 'NCBI-Hackathons/ATACFlow Software Versions'
section_href: 'https://github.com/NCBI-Hackathons/ATACFlow'
plot_type: 'html'
description: 'are collected at run time from the software output.'
data: |
    <dl class="dl-horizontal">
''')
for k,v in results.items():
    print("        <dt>{}</dt><dd>{}</dd>".format(k,v))
print ("    </dl>")
