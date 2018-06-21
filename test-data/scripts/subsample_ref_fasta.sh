#!/bin/bash

# extract chr19 and chrM from original fasta

# mm10
SUBSAMPLED_REF_FA=mm10_no_alt_analysis_set_ENCODE.chr19_chrM.fasta
REF_FA=/mnt/data/pipeline_genome_data/mm10/mm10_no_alt_analysis_set_ENCODE.fasta
CHR_BEGIN=">chr19"
CHR_END=">chr1_GL456210_random"
CHRM_BEGIN=">chrM"
CHRM_END=">chrUn_GL456239"
LINE_CHR_BEGIN=$(grep -n "$CHR_BEGIN" $REF_FA | awk -F":" '{print $1}')
LINE_CHR_END=$(grep -n "$CHR_END" $REF_FA | awk -F":" '{print $1-1}')
LINE_CHRM_BEGIN=$(grep -n "$CHRM_BEGIN" $REF_FA | awk -F":" '{print $1}')
LINE_CHRM_END=$(grep -n "$CHRM_END" $REF_FA | awk -F":" '{print $1-1}')
echo "CHR: $LINE_CHR_BEGIN, $LINE_CHR_END"
echo "CHRM: $LINE_CHRM_BEGIN, $LINE_CHRM_END"
sed -n $LINE_CHR_BEGIN','$LINE_CHR_END'p' $REF_FA > $SUBSAMPLED_REF_FA
sed -n $LINE_CHRM_BEGIN','$LINE_CHRM_END'p' $REF_FA >> $SUBSAMPLED_REF_FA
gzip $SUBSAMPLED_REF_FA

# hg38
SUBSAMPLED_REF_FA=GRCh38_no_alt_analysis_set_GCA_000001405.15.chr19_chrM.fasta
REF_FA=/mnt/data/pipeline_genome_data/hg38/GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta
CHR_BEGIN=">chr19"
CHR_END=">chr20"
CHRM_BEGIN=">chrM"
CHRM_END=">chr1_KI270706v1_random"
LINE_CHR_BEGIN=$(grep -n "$CHR_BEGIN" $REF_FA | awk -F":" '{print $1}')
LINE_CHR_END=$(grep -n "$CHR_END" $REF_FA | awk -F":" '{print $1-1}')
LINE_CHRM_BEGIN=$(grep -n "$CHRM_BEGIN" $REF_FA | awk -F":" '{print $1}')
LINE_CHRM_END=$(grep -n "$CHRM_END" $REF_FA | awk -F":" '{print $1-1}')
echo "CHR: $LINE_CHR_BEGIN, $LINE_CHR_END"
echo "CHRM: $LINE_CHRM_BEGIN, $LINE_CHRM_END"
sed -n $LINE_CHR_BEGIN','$LINE_CHR_END'p' $REF_FA > $SUBSAMPLED_REF_FA
sed -n $LINE_CHRM_BEGIN','$LINE_CHRM_END'p' $REF_FA >> $SUBSAMPLED_REF_FA
gzip $SUBSAMPLED_REF_FA
