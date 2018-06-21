from __future__ import division
import os
import glob
import sys

#Calculates millions mapped reads
def calmp(num_of_reads, total_reads):
        mp = int(num_of_reads)/(int(total_reads)/1000000)
        return mp

#Normalize bedgraphs to millions mapped reads
def main(directory_of_sortedbams):
    dic_mapped = {}
    outdir = directory_of_sortedbams + "/genomecoveragebed/"
    for sorted_bam_file_and_path in glob.glob(os.path.join(directory_of_sortedbams, '*sorted.bam.flagstat')):
        bamfileroot = sorted_bam_file_and_path.split("/")[-1].split(".sorted")[0]
        f = open(sorted_bam_file_and_path)
        lines = f.readlines()
        mapped_reads = int(lines[4].split(" ")[0])
        dic_mapped[bamfileroot] = mapped_reads
        f.close()
    for bamfile in glob.glob(os.path.join(directory_of_sortedbams, '*.sorted.bam')):
        bamfileroot = bamfile.split("/")[-1]
        bamfileroot = bamfileroot.split(".sorted")[0]
        bedgraph = outdir+"sorted."+bamfileroot+".sorted.sorted.BedGraph"
        if not os.path.isfile(bedgraph):
            bedgraph = outdir+bamfileroot+".sorted.sorted.BedGraph"
        total_reads = dic_mapped[bamfileroot]
        bedgraphout = bedgraph+".mp.BedGraph"
        wf = open(bedgraphout, "w")
        with open(bedgraph) as f:
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
    main(sys.argv[1])

