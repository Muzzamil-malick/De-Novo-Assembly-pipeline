# De-Novo-Assembly-pipeline
This repository contains a bash script to automate the processing of paired-end FASTQ files. The pipeline includes steps for quality control, error correction, normalization, assembly, assembly improvement, and quality assessment.

## Features

- Quality control and trimming of raw reads using Trim Galore.
- Error correction and normalization using BBNorm.
- De novo assembly using SPAdes.
- Assembly improvement using Pilon.
- Quality assessment using QUAST.

## Requirements

Ensure the following tools are installed and available in your PATH:

- Trim Galore
- BBNorm (part of BBTools)
- SPAdes
- BWA
- SAMtools
- Pilon
- QUAST
