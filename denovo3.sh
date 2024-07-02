#!/bin/bash

# Stop on error
set -e

# Define directory variables
RAW_DATA_DIR=fastqfiles
OUTPUT_DIR=output1
REPORT_DIR=report

# Create output and report directories if they don't exist
mkdir -p ${RAW_DATA_DIR}
mkdir -p ${OUTPUT_DIR}
mkdir -p ${REPORT_DIR}

# Iterate over each pair of FASTQ files in the RAW_DATA_DIR
for R1 in ${RAW_DATA_DIR}/*_R1.fastq; do
    # Derive the R2 file name and base name from the R1 file name
    R2=${R1/_R1.fastq/_R2.fastq}
    BASENAME=$(basename ${R1} _R1.fastq)

    # Step 1: Quality control and trimming
    echo "Starting Quality Control and Trimming for ${BASENAME}..."
    trim_galore --paired ${R1} ${R2} --output_dir ${OUTPUT_DIR}

    # Trimmed files naming convention depends on trim_galore, adjust as needed
    TRIMMED_R1=${OUTPUT_DIR}/${BASENAME}_R1_val_1.fq
    TRIMMED_R2=${OUTPUT_DIR}/${BASENAME}_R2_val_2.fq

    # Step 2: Error correction and normalization
    echo "Starting Error Correction and Normalization for ${BASENAME}..."
    bbnorm.sh in=${TRIMMED_R1} in2=${TRIMMED_R2} out=${OUTPUT_DIR}/${BASENAME}_R1_norm.fq out2=${OUTPUT_DIR}/${BASENAME}_R2_norm.fq

    # Step 3: Assembly with SPAdes
    echo "Starting Assembly with SPAdes for ${BASENAME}..."
    spades.py --isolate -o ${OUTPUT_DIR}/${BASENAME}_spades_output -1 ${OUTPUT_DIR}/${BASENAME}_R1_norm.fq -2 ${OUTPUT_DIR}/${BASENAME}_R2_norm.fq

    # Step 4: Assembly improvement with Pilon
    echo "Starting Assembly Improvement with Pilon for ${BASENAME}..."
    SPADES_OUTPUT=${OUTPUT_DIR}/${BASENAME}_spades_output
    bwa index ${SPADES_OUTPUT}/contigs.fasta
    bwa mem -t 8 ${SPADES_OUTPUT}/contigs.fasta ${OUTPUT_DIR}/${BASENAME}_R1_norm.fq ${OUTPUT_DIR}/${BASENAME}_R2_norm.fq > ${OUTPUT_DIR}/${BASENAME}_aligned_reads.sam
    samtools view -Sb ${OUTPUT_DIR}/${BASENAME}_aligned_reads.sam > ${OUTPUT_DIR}/${BASENAME}_aligned_reads.bam
    samtools sort ${OUTPUT_DIR}/${BASENAME}_aligned_reads.bam -o ${OUTPUT_DIR}/${BASENAME}_sorted_aligned_reads.bam
    samtools index ${OUTPUT_DIR}/${BASENAME}_sorted_aligned_reads.bam
    pilon --genome ${SPADES_OUTPUT}/contigs.fasta --frags ${OUTPUT_DIR}/${BASENAME}_sorted_aligned_reads.bam --output ${OUTPUT_DIR}/${BASENAME}_pilon_output

    # Step 5: Quality assessment with QUAST
    echo "Starting Quality Assessment with QUAST for ${BASENAME}..."
    quast.py -o ${OUTPUT_DIR}/${BASENAME}_quast_output ${SPADES_OUTPUT}/contigs.fasta

done

# Note: The report generation is now handled per sample within the loop.
echo "Pipeline completed. Check each sample directory within ${OUTPUT_DIR} for individual reports."

