#!/bin/bash

# Configuration for FreeSurfer processing

# Directories and paths
export BIDS_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test"  # Replace with your BIDS dataset directory
export OUTPUT_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-11_freesurfer" # Replace with your desired FreeSurfer output directory
export SINGULARITY_IMG="/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/freesurfer_7.2.0.sif" # Replace with the path to your FreeSurfer Singularity image
export LICENSE_FILE="/home/ludoal/scratch/ChronicPainfMRI/license.txt"   # Replace with the path to your FreeSurfer license file
export REPOS_PATH='/home/ludoal/scratch/ChronicPainfMRI'
