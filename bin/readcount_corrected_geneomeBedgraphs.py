#!/usr/bin/env python
from __future__ import division
import os
import glob
import sys

#Calculates millions mapped reads
def calmp(num_of_reads, total_reads):
        mp = int(num_of_reads)/(int(total_reads)/1000000)
        return mp

#Normalize bedgraphs to millions mapped reads
def main(flagstat_file, sorted_bed_file):
    bamfileroot = flagstat_file.split("/")[-1].split(".sorted")[0]
    f = open(flagstat_file)
    lines = f.readlines()
    total_reads = int(lines[4].split(" ")[0])
    f.close()
    bedgraphout = '.'.join(sorted_bed_file.split('.')[:-1]) + '.mp.BedGraph'
    wf = open(bedgraphout, "w")
    with open(sorted_bed_file) as f:
        for line in f:
            line = line.strip('\n').split('\t')
            if len(line)<3:
                try:
            	    line = line[0].split(" ")
                except:
            	    print line
            chrom, start, stop, num_of_reads = line
            frag = calmp(float(num_of_reads), total_reads)
            newline = "\t".join([chrom, start, stop, str(frag)])+"\n"
            wf.write(newline)
    wf.close()



if __name__=="__main__":
    main(sys.argv[1], sys.argv[2])

