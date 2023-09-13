#!/usr/bin/env nextflow

params.input = ''

Channel.fromPath(params.input)
    .splitCsv(header: true)
    .set { read_pairs_ch }

process MAPREADS { 

    tag "$sample_id"
   
    input:
    tuple val(sample_id), path(fw), path(rev)

    output: 
    path "${sample_id}/accepted_hits.bam" 
    val sample_id

    script: 
    """
    tophat2 -g 2 -G /home/linux/Desktop/splicing_pipeline/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_bowtie2_index/TAIR10_ChrC.gff --no-novel-juncs -o $sample_id /home/linux/Desktop/splicing_pipeline/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_bowtie2_index/TAIR10_ChrC $fw $rev
    """
    
} 

process CHLOROSEQ { 

    tag "$sample_id"

    input:
    path bam
    val sample_id

    output: 
    file 'splicing_efficiency.txt'
    val sample_id

    script: 
    """
    chloroseq.pl -a 2 -b $bam -e /home/linux/Desktop/splicing_pipeline/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_exon.gff3 -i /home/linux/Desktop/splicing_pipeline/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_introns.gff3 -g 128214 -n ChrC -s /home/linux/Desktop/splicing_pipeline/chloroseq/TAIR10_ChrC_files/TAIR10_ChrC_splice_sites_sort.gff3
    """
}

process OUTPUT { 
   
    tag "$sample_id"

    input:
    path results
    val sample_id

    output: 
    stdout
   
    script: 
    """
    cp $results "/home/linux/Desktop/${sample_id}_splicing_efficiency.txt"
    """
    
}

workflow { 
    mappedreads_ch = MAPREADS(read_pairs_ch)
    splicingefficiencies_ch = CHLOROSEQ(mappedreads_ch)
    output_ch = OUTPUT(splicingefficiencies_ch)
} 
