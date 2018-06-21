from __future__ import division
import glob
import os
import sys


def main2(fullpath):
	save_path = fullpath
	directory_of_sortedbams = fullpath.split('sortedbam')[0]+'sortedbam'
	keyword = fullpath.split("/")[-1]
	completeName = os.path.join(save_path, "millions_mapped.txt")
	file2 = open(completeName, "w")
	file2.truncate()
	for sorted_bam_file_and_path in glob.glob(os.path.join(directory_of_sortedbams, '*sorted.bam.flagstat')):
			bamfileroot = sorted_bam_file_and_path.split("/")[-1]
			n = 1
			while n < len(bamfileroot):
				character = bamfileroot[n]
				if str(character) == ".":
					break
				else:
					n = n+1
			cropped_bamfileroot = bamfileroot[0:n]
			f = open(sorted_bam_file_and_path)
			lines = f.readlines()
			total_reads = lines[0]
			total_reads = int(total_reads.split(" ")[0])
			mapped_reads = lines[4]
			mapped_reads = int(mapped_reads.split(" ")[0])
			percent_mapped = mapped_reads/total_reads  
			file2 = open(completeName, "a")
			value = keyword, cropped_bamfileroot, total_reads, mapped_reads, percent_mapped
			s = str(value)
			file2.write("keyword, cropped_bamfileroot, total_reads, mapped_reads, percent_mapped")
			file2.write(s)
			file2.write('\n')
			file2.close()

if __name__=="__main__":
	main2(sys.argv[1])
	#f2.close()
