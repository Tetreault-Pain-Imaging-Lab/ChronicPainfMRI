#!/bin/bash

# Source the configuration file
# source /path/to/reconall_config.sh  # Update with the actual path to the config script

# Generate list of subject/session combinations
combinations=($(find $BIDS_DIR -mindepth 2 -maxdepth 2 -type d -name "ses-*"))

# Check if array index is within bounds
if [ $SLURM_ARRAY_TASK_ID -ge ${#combinations[@]} ]; then
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

    # Check if all required arguments are provided
if [[ -z "$BIDS_DIR" || -z "$OUTPUT_DIR" || -z "$SINGULARITY_IMG" || -z "$LICENSE_FILE" || -z "$SUBJ_ID" || -z "$SESS_ID" || -z "$T1_FILE" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

# Set SUBJECTS_DIR to point to FreeSurfer output directory
export SUBJECTS_DIR="${OUTPUT_DIR}/${SESS_ID}"

# Create the output directory if it doesn't exist
mkdir -p $SUBJECTS_DIR

output_subj_dir="${SUBJECTS_DIR}/${SUBJ_ID}"

# Check if output already exists to avoid reprocessing
if [ -d "$output_subj_dir" ]; then
    echo "Output already exists for ${SUBJ_ID}, skipping."
    exit 0
fi

module load apptainer
# Run recon-all using Singularity
apptainer run --cleanenv \
    -B $BIDS_DIR:/data:ro \
    -B $SUBJECTS_DIR:/output \
    -B $LICENSE_FILE:/opt/freesurfer/license.txt \
    $SINGULARITY_IMG recon-all \
    -i /data/${SUBJ_ID}/${SESS_ID}/anat/${SUBJ_ID}_${SESS_ID}_T1w.nii.gz \
    -s ${SUBJ_ID} -sd /output -all -3T

    
else
    echo "T1 file not found for $subj_id $sess_id"
fi
