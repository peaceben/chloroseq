#!/usr/bin/env nextflow

params.input = ''

Channel.fromPath(params.input)
    .splitCsv(header: true)
    .set { read_pairs_ch }

process MAPREADS { 

    container 'peaceben/chloroseq-tophat'
    tag "$sample_id"
   
    input:
    tuple val(sample_id), path(fw), path(rev)

    output: 
    path "${sample_id}/accepted_hits.bam" 
    val sample_id

    script: 
    """
    tophat2 -g 2 -G /home/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_bowtie2_index/TAIR10_ChrC.gff --no-novel-juncs -o $sample_id /home/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_bowtie2_index/TAIR10_ChrC $fw $rev
    """
    
} 

process CHLOROSEQ { 

    container 'peaceben/chloroseq'
    tag "$sample_id"
    publishDir 'results', saveAs: { filename -> "${sample_id}_${filename}" }, mode: 'copy'

    input:
    path bam
    val sample_id

    output: 
    file 'splicing_efficiency.txt'

    script: 
    """
    /home/chloroseq/ChloroSeq_scripts/chloroseq.pl -a 2 -b $bam -e /home/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_exon.gff3 -i /home/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_introns.gff3 -g 128214 -n ChrC -s /home/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_splice_sites_sort.gff3
    """
}

workflow { 
    mappedreads_ch = MAPREADS(read_pairs_ch)
    splicingefficiencies_ch = CHLOROSEQ(mappedreads_ch)
} 
