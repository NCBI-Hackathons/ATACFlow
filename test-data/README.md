# atac-seq-pipeline-test-data
Test data for ENCODE atac-seq-pipeline

Single ended dataset (ENCSR889WQX) and paired end dataset (ENCSR356KRQ) are subsampled down to 1/400 reads.

For genome data (`/genome_data`) sequences for chr19 and chrM are extracted from hg38 and mm10 and bowtie2 indices are built on them.


# How to extract chr19 and chrM from original fasta

```
$ cd scripts
$ ./subsample_ref_fasta.sh
```

# How to generate reference outputs

0) Make sure that you have an executable `cromwell-30.1.jar` in your `PATH`.

1) Specify correct file paths in `subsample_fastq.sh` and run to subsample test samples.
```
$ cd test_sample
$ ./subsample_fastq.sh
```

2) Generate base reference outputs by running the following shell scripts. These test samples are subsampled down to 1/200 reads.
```
$ cd scripts
$ ./ENCSR356KRQ.sh
$ ./ENCSR889WQX.sh
```

3) Wait until 2) is done. Link outputs of 2) to JSON files in `test_sample/*.sh`, run other shell scripts.
```
$ cd scripts
$ ./ENCSR356KRQ_disable_tn5_shift.sh
$ ./ENCSR356KRQ_no_dup_removal.sh
$ ./ENCSR356KRQ_no_multimapping.sh
$ ./ENCSR356KRQ_subsample.sh
$ ./ENCSR356KRQ_subsample_xcor.sh
$ ./ENCSR889WQX_disable_tn5_shift.sh
$ ./ENCSR889WQX_no_dup_removal.sh
$ ./ENCSR889WQX_no_multimapping.sh
$ ./ENCSR889WQX_subsample.sh
$ ./ENCSR889WQX_subsample_xcor.sh
```
