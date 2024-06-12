#!/bin/bash

#SBATCH --job-name=reconall_array_test
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10K
#SBATCH --mail-user=ludo.a.levesque@gmail.com
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE,ALL
#SBATCH --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/recon-all/test-slurm-%A_%a.out"
#SBATCH --array=0-99

# Directories and paths
BIDS_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test"  # Replace with your BIDS dataset directory
OUTPUT_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-12_freesurfer" # Replace with your desired FreeSurfer output directory
SINGULARITY_IMG="/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/freesurfer_7.2.0.sif" # Replace with the path to your FreeSurfer Singularity image
LICENSE_FILE="/home/ludoal/scratch/ChronicPainfMRI/license.txt"   # Replace with the path to your FreeSurfer license file
REPOS_PATH='/home/ludoal/scratch/ChronicPainfMRI'

# Generate list of subject/session combinations
combinations=($(find $BIDS_DIR -mindepth 2 -maxdepth 2 -type d -name "ses-*"))
total_combinations=${#combinations[@]}

# Check if array index is within bounds
if [ $SLURM_ARRAY_TASK_ID -ge $total_combinations ]; then
    echo "Array index out of bounds"
    exit 1
fi

# Get subject and session info from array index
combination=${combinations[$SLURM_ARRAY_TASK_ID]}
subj_id=$(basename $(dirname $combination))
sess_id=$(basename $combination)
t1_file=$combination/anat/${subj_id}_${sess_id}_T1w.nii.gz

if [ -f $t1_file ]; then
    echo "Processing $subj_id $sess_id"
    echo "BIDS_DIR: $BIDS_DIR"
    echo "OUTPUT_DIR: $OUTPUT_DIR"
    echo "SINGULARITY_IMG: $SINGULARITY_IMG"
    echo "LICENSE_FILE: $LICENSE_FILE"
    echo "SUBJ_ID: $subj_id"
    echo "SESS_ID: $sess_id"
    echo "T1_FILE: $t1_file"
    echo "SUBJECTS_DIR: ${OUTPUT_DIR}/${sess_id}"
    echo "Output subject directory: ${OUTPUT_DIR}/${sess_id}/${subj_id}"

    SUBJECTS_DIR="${OUTPUT_DIR}/${sess_id}"
    mkdir -p $SUBJECTS_DIR
    output_subj_dir="${SUBJECTS_DIR}/${subj_id}"

    # Check if output already exists to avoid reprocessing
    if [ -d "$output_subj_dir" ]; then
        echo "Output already exists for ${subj_id}, skipping."
        exit 0
    fi

    # Simulate processing
    echo "Simulating recon-all command for ${subj_id} ${sess_id}"
else
    echo "T1 file not found for $subj_id $sess_id"
fi
