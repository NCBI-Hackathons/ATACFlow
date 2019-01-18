#!/usr/bin/env nextflow
/*
========================================================================================
                         NCBI-Hackathons/ATACFlow
========================================================================================
 NCBI-Hackathons/ATACFlow Analysis Pipeline. Started 2018-06-21.
 #### Homepage / Documentation
 https://github.com/NCBI-Hackathons/ATACFlow
 #### Authors
 ATACFlow Team @ RMGCH-18 NCBI-Hackathons - https://github.com/NCBI-Hackathons>
 Ignacio Tripodi <ignacio.tripodi@colorado.edu>
 Steve Tsang <stevehtsang@gmail.com>
 Jingjing Zhao <jjzhao123@gmail.com>
 Evan Floden <evanfloden@gmail.com>
 Chi Zhang <chzh1418@colorado.edu>
----------------------------------------------------------------------------------------
*/


def helpMessage() {
    log.info"""
    =========================================
     NCBI-Hackathons/ATACFlow v${params.version}
    =========================================
    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run NCBI-Hackathons/ATACFlow -profile singularity,test

    Mandatory arguments:
      --reads                       Path to input data (must be surrounded with quotes)
      --sras                        Comma seperated list of SRAs ids
      --genome                      Name of iGenomes reference
      --bt2index                    Path to Bowtie2 index
      -profile                      Hardware config to use. docker / aws

    Options:
      --singleEnd                   Specifies that the input is single end reads

    Other options:
      --outdir                      The output directory where the results will be saved
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.
    """.stripIndent()
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

// Show help message
if (params.help){
    helpMessage()
    exit 0
}

// Configurable variables
params.name = false
params.multiqc_config = "$baseDir/conf/multiqc_config.yaml"
params.email = false
params.plaintext_email = false
multiqc_config = file(params.multiqc_config)
output_docs = file("$baseDir/docs/output.md")

// Validate inputs
if ( params.genome ){
    genome = file(params.genome)
    if( !genome.exists() ) exit 1, "Fasta genome file not found: ${params.genome}"
}

if ( params.bt2index ){
    bt2_index = file("${params.bt2index}.fa").baseName
    bt2_indices = Channel.fromPath( "${params.bt2index}*.bt2" ).toList()
    // if( !bt2_indices[0].exists() ) exit 1, "Reference genome Bowtie 2 index not found: ${params.bt2index}"
}

if ( params.chrom_sizes ){
    chrom_sizes = file(params.chrom_sizes)
    if( !chrom_sizes.exists() ) exit 1, "Genome chrom sizes file not found: ${params.chrom_sizes}"
}

if ( params.trimmomatic_jar_path ){
    trimmomatic_jar_path = file("${params.trimmomatic_jar_path}")
}

if ( params.sras ){
  sra_ids_list = params.sras.tokenize(",")
} else { Channel.empty().set {sra_ids_list } }


// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}


/*
 * Create a channel for input read files
 */
if (params.fastq_dir_pattern) {
    fastq_reads_for_qc = Channel
                        .fromPath(params.fastq_dir_pattern)
                        .map { file -> tuple(file.baseName, file) }
    fastq_reads_for_trim = Channel
                                          .fromPath(params.fastq_dir_pattern)
                                          .map { file -> tuple(file.baseName, file) }
}
else {
    Channel
        .empty()
        .into { fastq_reads_for_qc; fastq_reads_for_trim }
}

if (params.sra_dir_pattern) {
    println("pattern for SRAs provided")
    read_files_sra = Channel
                        .fromPath(params.sra_dir_pattern)
                        .map { file -> tuple(file.baseName, file) }
}
else {
    read_files_sra = Channel.empty()
}

if (params.sras) {
        sra_strings.into { read_files_fastqc; read_files_trimming }
}

if (params.sra_dir_pattern == "" && params.fastq_dir_pattern == "") {
     Channel
         .fromFilePairs( params.reads, size: params.singleEnd ? 1 : 2 )
         .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nIf this is single-end data, please specify --singleEnd on the command line." }
         .into { read_files_fastqc; read_files_trimming }
 }


// Header log info
log.info """=======================================================
                                          ,--./,-.
          ___     __   __   __   ___     /,-._.--~\'
    |\\ | |__  __ /  ` /  \\ |__) |__         }  {
    | \\| |       \\__, \\__/ |  \\ |___     \\`-._,-`-,
                                          `._,._,\'

NCBI-Hackathons/ATACFlow v${params.version}"
======================================================="""
def summary = [:]
summary['Pipeline Name']    = 'NCBI-Hackathons/ATACFlow'
summary['Pipeline Version'] = params.version
summary['Run Name']         = custom_runName ?: workflow.runName
summary['Reads']            = params.reads
summary['Genome Ref']       = params.genome
summary['Thread fqdump']    = params.threadfqdump ? 'YES' : 'NO'
summary['Bowtie2 Index']    = params.bt2index
summary['Data Type']        = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Max Memory']       = params.max_memory
summary['Max CPUs']         = params.max_cpus
summary['Max Time']         = params.max_time
summary['Output dir']       = params.outdir
summary['Working dir']      = workflow.workDir
summary['Container Engine'] = workflow.containerEngine
if(workflow.containerEngine) summary['Container'] = workflow.container
summary['Current home']     = "$HOME"
summary['Current user']     = "$USER"
summary['Current path']     = "$PWD"
summary['Working dir']      = workflow.workDir
summary['Output dir']       = params.outdir
summary['Script dir']       = workflow.projectDir
summary['Config Profile']   = workflow.profile
if(params.email) summary['E-mail Address'] = params.email
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

// Check that Nextflow version is up to date enough
// try / throw / catch works for NF versions < 0.25 when this was implemented
try {
    if( ! nextflow.version.matches(">= $params.nf_required_version") ){
        throw GroovyException('Nextflow version too old')
    }
} catch (all) {
    log.error "====================================================\n" +
              "  Nextflow version $params.nf_required_version required! You are running v$workflow.nextflow.version.\n" +
              "  Pipeline execution will continue, but things may break.\n" +
              "  Please run `nextflow self-update` to update Nextflow.\n" +
              "============================================================"
}


/*
 * Parse software version numbers
 */
process get_software_versions {

    input:
    file(trimmomatic_jar_path)

    output:
    file 'software_versions_mqc.yaml' into software_versions_yaml

    script:
    """
    module load sra/2.8.0
    module load igvtools/2.3.75
    module load fastqc/0.11.5
    module load bedtools/2.25.0
    module load bowtie/2.2.9
    module load samtools/1.8

    echo $params.version > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    fastqc --version > v_fastqc.txt
    java -XX:ParallelGCThreads=1 -jar ${trimmomatic_jar_path} -version &> v_trimmomatic.txt
    multiqc --version > v_multiqc.txt
    samtools --version &> v_samtools.txt
    bowtie2 --version &> v_bowtie2.txt
    fastq-dump --version &> v_fastq-dump.txt
    bedtools --version &> v_bedtools.txt
    igvtools &> v_igv-tools.txt
    macs2 --version &>  v_macs2.txt
    scrape_software_versions.py > software_versions_mqc.yaml
    """
}


process sra_dump {
    publishDir "${params.outdir}/fastq/", mode: 'copy', pattern: '*.fastq'
    tag "$fname"
    if (params.threadfqdump) {
        cpus 8 }
    else { 
        cpus 1
    }

    input:
    set val(fname), file(reads) from read_files_sra

    output:
    set val(fname), file("*.fastq") into fastq_reads_for_trim_from_sra
    set val(fname), file("*.fastq") into fastq_reads_for_qc_from_sra

/* Updated to new version of sra tools which has "fasterq-dump" -- automatically splits files that have multiple reads 
  * (i.e. paired-end data) and is much quicker relative to fastq-dump. Also has multi-threading (currently set with -e 8) 
  * and requires a temp directory which is set to the nextflow temp directory
  */

    script:
    if (!params.threadfqdump) {
        """
        module load sra/2.9.2
        echo ${fname}

        fastq-dump --split-3 ${reads}
        """
    } else {
        """
        export PATH=~/.local/bin:$PATH
        module load sra/2.9.2
        module load python/3.6.3

        parallel-fastq-dump \
            --threads 8 \
            --sra-id ${reads}
        """
    }
}

//fastq_read_files
//   .into {fastq_reads_for_trim; fastq_reads_for_qc}


/*
 * STEP 1 - Trimmomatic
 */

process trimmomatic {
    memory '200 GB'
    time '12h'
    tag "$name"
    publishDir "${params.outdir}/trimmomatic/", mode: 'copy', pattern: '*_trimmed.fastq'

    input:
    file(trimmomatic_jar_path)
    set val(name), file(reads) from fastq_reads_for_trim.mix(fastq_reads_for_trim_from_sra)

    output:
    set val(name), file("*_trimmed.fastq") into trimmed_reads_ch
//    file "*trimming_report.txt" into trimmomatic_results

    script:
    if (params.singleEnd) {
        """
        java -XX:ParallelGCThreads=1 -jar ${trimmomatic_jar_path} SE \
             -phred33 -trimlog ${name}.trimlog \
             ${reads[0]} ${name}_trimmed.fastq \
             LEADING:20 TRAILING:20 SLIDINGWINDOW:4:20 MINLEN:36
        """
    } else {
        """
        java -XX:ParallelGCThreads=1 -jar ${trimmomatic_jar_path} PE \
             -phred33 -trimlog ${name}.trimlog \
             ${name}_1.fastq ${name}_2.fastq \
             ${name}_1_trimmed.fastq ${name}_1_trimmed_unpaired.fastq \
             ${name}_2_trimmed.fastq ${name}_2_trimmed_unpaired.fastq \
             LEADING:20 TRAILING:20 SLIDINGWINDOW:4:20 MINLEN:36
        """
    }
}


/*
 * STEP 2 - FastQC
 */

process fastqc {
    tag "$name"
    publishDir "${params.outdir}/fastqc", mode: 'copy',
        saveAs: {filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"}

    input:
    set val(name), file(reads) from fastq_reads_for_qc.mix(fastq_reads_for_qc_from_sra)

    output:
    file "*_fastqc.{zip,html}" into fastqc_results

    script:
    """
    module load fastqc/0.11.5

    fastqc -q $reads
    """
}


/*
 * STEP 3 (Optional) - Build Bowtie2 Index
 *
 * process buildIndex {
 *   tag "$genome_file.baseName"
 *
 *   input:
 *   file genome from genome_file
 *
 *   output:
 *   file 'genome.index*' into genome_index
 *
 *   """
 *   bowtie2-build ${genome} genome.index
 *   """
 *   }
 */


/*
 * STEP 4 - Map reads to reference genome
 *          TODO: SUPPORT SINGLE-END READS
 */
process bowtie2 {
    tag "$name"
    cpus 32
    publishDir "${params.outdir}/bowtie2/", mode: 'copy', pattern: "${name}.sam"

    input:
    val(bt2_prefix) from bt2_index
    file(indices) from bt2_indices
    set val(name), file(trimmed_reads) from trimmed_reads_ch

    output:
    set val(name), file("${name}.sam") into mapped_sam_file_ch

    script:
    """
    module load bowtie/2.2.9

    bowtie2 -X 2000 \
            -p 32 \
            -x $bt2_prefix \
            -1 ${trimmed_reads[0]} \
            -2 ${trimmed_reads[1]} \
            -S ${name}.sam
    """
}


/*
 * STEP X - Convert to BAM format and sort
 */

process samtools {
    tag "$name"
    cpus 32
    memory '500 GB'
    time '96h'
    publishDir "${params.outdir}/samtools/", mode: 'copy', pattern: "${name}.sorted.bam"

    input:
    set val(name), file(mapped_sam) from mapped_sam_file_ch

    output:
    set val(name), file("${name}.sorted.bam") into sorted_bam_ch
    set val(name), file("${name}.sorted.bam.flagstat") into flagstat_ch

    script:
    """
    module load samtools/1.8

    samtools view -S -b ${mapped_sam} -o ${name}.bam
    samtools flagstat ${name}.bam > ${name}.bam.flagstat
    samtools sort -m500G -o ${name}.sorted.bam ${name}.bam
    samtools index ${name}.sorted.bam
    samtools view -cF 0x100 ${mapped_sam} > ${name}.millionsmapped
    samtools flagstat ${name}.sorted.bam > ${name}.sorted.bam.flagstat
    """
}

sorted_bam_ch
   .into {sorted_bams_for_bedtools; sorted_bams_for_macs2}


/*
 *STEP X - Create a BedGraph file
 */

process bedtools {
    tag "$name"
    memory '200 GB'
    time '12h'
    publishDir "${params.outdir}/bedtools/", mode: 'copy', pattern: "${name}.sorted.BedGraph"

    input:
    set val(name), file(bam_file) from sorted_bams_for_bedtools
    file(chrom_sizes) from chrom_sizes

    output:
    set val(name), file("${name}.sorted.BedGraph") into bed_file_ch

    script:
    """
    module load bedtools/2.25.0

    genomeCoverageBed -bg -ibam ${bam_file} -g ${chrom_sizes} > ${name}.BedGraph
    bedtools sort -i ${name}.BedGraph > ${name}.sorted.BedGraph
    """
 }

bed_file_ch
    .combine(flagstat_ch, by:0)
    .set {bed_and_flagset_ch}

/*
 * STEP X - Normalise Counts
 */

process normalize_counts {
    tag "$name"
    publishDir "${params.outdir}/bedtools/", mode: 'copy', pattern: "${name}.sorted.mp.BedGraph"

    input:
    set val(name), file(sorted_bed), file(flagstat) from bed_and_flagset_ch

    output:
    set val(name), file("${name}.sorted.mp.BedGraph") into normalized_bed_ch

    script:
    """
    readcount_corrected_geneomeBedgraphs.py ${flagstat} ${sorted_bed}
    """
}


/*
 *STEP X - IGV Tools
 */

process igvtools {
    tag "$name"
    errorStrategy 'ignore'
    // Need to play with this upper boundary a bit... igvtools can be a memory hog
    memory '8 GB'
    publishDir "${params.outdir}/igv_tools/", mode: 'copy', pattern: "${name}.tdf"

    input:
    set val(name), file(normalized_bed) from normalized_bed_ch
    file(genome)

    output:
    set val(name), file("${name}.tdf") into tiled_data_ch

    script:
    """
    module load igvtools/2.3.75

    JAVA_OPTS="-Xmx8000m" igvtools toTDF ${normalized_bed} ${name}.tdf ${genome}
    """
 }


/*
 *STEP X - Peak calling
 */

process macs2 {
    tag "$name"
    cpus 8
    memory '2 GB'
    time '3h'
    publishDir "${params.outdir}/macs2/", mode: 'copy', pattern: "${name}_peaks_clean.broadPeak"

    input:
    set val(name), file(sorted_bam) from sorted_bams_for_macs2

    output:
    set val(name), file("${name}_peaks_clean.broadPeak") into macs2_ch

    script:
    """
    macs2 callpeak -n ${name} \
                   --nomodel \
                   --format BAMPE \
                   -t ${sorted_bam} \
                   --shift -100 \
                   --extsize 200 \
                   -B \
                   --broad
    bedtools intersect -a ${name}_peaks.broadPeak \
                       -b ${params.region_blacklist} \
                       -v \
                       > ${name}_peaks_clean.broadPeak

    """
 }


/*
 *STEP X - Calculate MD-scores
 *         NOTE: Since we only have the SRA number as an identifier,
 *         the file should be renamed later with the proper condition
 *         name to replace "CONDITION" (e.g. "DMSO", "wildtype", "DrugTreated4hr", etc)
*/
process process_atac {
    tag "$name"
    cpus 12
    memory '500 GB'
    time '6h'
    publishDir "${params.outdir}/md_scores/", mode: 'copy', pattern: "${name}*md_scores.txt"

    input:
    set val(name), file(peaks_file) from macs2_ch

    output:
    set val(name), file("${name}*md_scores.txt") into dastk_ch

    script:
    """
    process_atac --prefix '${name}_CONDITION' \
		 --threads 12 \
		 --atac-peaks ${peaks_file} \
		 --motif-path ${params.tf_motif_sites}
    """
}


/*
 * STEP X - MultiQC
 */
process multiqc {
    publishDir "${params.outdir}/MultiQC", mode: 'copy'

    input:
    file multiqc_config
    file ('fastqc/*') from fastqc_results.collect()
//    file ('trimmomatic/*') from trimmomatic_results.collect()
    file ('software_versions/*') from software_versions_yaml

    output:
    file "*multiqc_report.html" into multiqc_report
    file "*_data"

    script:
    rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
    rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
    """
    multiqc -f $rtitle $rfilename --config $multiqc_config .
    """
}



/*
 * STEP 3 - Output Description HTML
 *
*
*process output_documentation {
*    tag "$prefix"
*    publishDir "${params.outdir}/Documentation", mode: 'copy'
*
*    input:
*    file output_docs
*
*    output:
*    file "results_description.html"
*
*    script:
*    """
*    markdown_to_html.r $output_docs results_description.html
*    """
*}



/*
 * Completion e-mail notification
 */
workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[NCBI-Hackathons/ATACFlow] Successful: $workflow.runName"
    if(!workflow.success){
      subject = "[NCBI-Hackathons/ATACFlow] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = params.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if(workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if(workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if(workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", attach1: "$baseDir/results/Documentation/pipeline_report.html", attach2: "$baseDir/results/pipeline_info/NCBI-Hackathons/ATACFlow_report.html", attach3: "$baseDir/results/pipeline_info/NCBI-Hackathons/ATACFlow_timeline.html" ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (params.email) {
        try {
          if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
          // Try to send HTML e-mail using sendmail
          [ 'sendmail', '-t' ].execute() << sendmail_html
          log.info "[NCBI-Hackathons/ATACFlow] Sent summary e-mail to $params.email (sendmail)"
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, params.email ].execute() << email_txt
          log.info "[NCBI-Hackathons/ATACFlow] Sent summary e-mail to $params.email (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File( "${params.outdir}/Documentation/" )
    if( !output_d.exists() ) {
      output_d.mkdirs()
    }
    def output_hf = new File( output_d, "pipeline_report.html" )
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_txt }

    log.info "[NCBI-Hackathons/ATACFlow] Pipeline Complete"

}
