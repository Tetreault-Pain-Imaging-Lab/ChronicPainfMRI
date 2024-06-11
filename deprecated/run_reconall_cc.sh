#!/bin/bash

# Directories
BIDS_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test"          # Replace with your BIDS dataset directory
OUTPUT_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-11_freesurfer"   # Replace with your desired FreeSurfer output directory
SINGULARITY_IMG="/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/freesurfer_7.2.0.sif" # Replace with the path to your FreeSurfer Singularity image
LICENSE_FILE="/home/ludoal/scratch/ChronicPainfMRI/license.txt"       # Replace with the path to your FreeSurfer license file


# Function to run recon-all
run_recon_all() {
    local subj_id=$1
    local sess_id=$2
    local t1_file=$3

    # Set SUBJECTS_DIR to point to FreeSurfer output directory
    export SUBJECTS_DIR="${OUTPUT_DIR}/${sess_id}"

    # Create the output directory if it doesn't exist
    if [ ! -d $SUBJECTS_DIR ]; then
        mkdir -p $SUBJECTS_DIR
    fi

    local output_subj_dir="${SUBJECTS_DIR}/${subj_id}"

    # Check if output already exists to avoid reprocessing
    if [ -d "$output_subj_dir" ]; then
        echo "Output already exists for ${subj_id}, skipping."
        return
    fi

    # Run recon-all using Singularity
    aptainer run --cleanenv \
        -B $BIDS_DIR:/data:ro \
        -B $SUBJECTS_DIR:/output \
        -B $LICENSE_FILE:/opt/freesurfer/license.txt \
        $SINGULARITY_IMG recon-all \
        -i /data/${subj_id}/${sess_id}/anat/${subj_id}_${sess_id}_T1w.nii.gz \
        -s ${subj_id} -sd /output -all -3T
}

# Loop through subjects and sessions
for subj in $BIDS_DIR/sub-*; do
    subj_id=$(basename $subj)

    for sess in $subj/ses-*; do
        sess_id=$(basename $sess)
        t1_file=$sess/anat/${subj_id}_${sess_id}_T1w.nii.gz

        if [ -f $t1_file ]; then
            echo "Processing $subj_id $sess_id"
            run_recon_all $subj_id $sess_id $t1_file
            sleep 1m
        else
            echo "T1 file not found for $subj_id $sess_id"
        fi
    done
done
