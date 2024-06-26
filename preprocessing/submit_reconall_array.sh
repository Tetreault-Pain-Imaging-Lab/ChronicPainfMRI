#!/bin/bash


    ## Directories and paths
# your BIDS dataset directory
export BIDS_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test"  
# Your desired FreeSurfer output directory (to run fmriprep one session at a time, the freesurfer output folder needs to have one subfolderper session)
export OUTPUT_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-12_freesurfer" 
# Path to your FreeSurfer image
export SINGULARITY_IMG="/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/freesurfer_7.2.0.sif" 
# Path to your FreeSurfer license file
export LICENSE_FILE="/home/ludoal/scratch/ChronicPainfMRI/license.txt"
# Path to the repository containing this script   
export REPOS_PATH='/home/ludoal/scratch/ChronicPainfMRI'

# Calculate total number of subject/session combinations
total_combinations=$(find $BIDS_DIR -mindepth 2 -maxdepth 2 -type d -name "ses-*" | wc -l)

# Submit the Slurm job with the calculated array size
if [ $total_combinations -gt 0 ]; then

# Adjust the allocated ressources in the sbatch command to your dataset
# To monitor ressources usage on Narval : https://portail.narval.calculquebec.ca/

    sbatch --job-name=reconall_array \
           --time=10:00:00 \
           --nodes=1 \
           --cpus-per-task=1 \
           --mem=3700M \
           --mail-user=ludo.a.levesque@gmail.com \
           --mail-type=BEGIN,END,FAIL,REQUEUE,ALL \
           --output="${REPOS_PATH}/outputs/recon-all/slurm-%A_%a.out" \
           --array=0-$(($total_combinations - 1)) \
           "${REPOS_PATH}/preprocessing/run_reconall_array.sh"
else
    echo "No valid subject/session combinations found."
fi
