#!/bin/bash

# Generate list of subject/session combinations
combinations=($(find $BIDS_DIR -mindepth 2 -maxdepth 2 -type d -name "ses-*"))

# Check if array index is within bounds
if [ $SLURM_ARRAY_TASK_ID -ge ${#combinations[@]} ]; then
    echo "Array index out of bounds"
    exit 0
fi

# Get subject and session info from array index
combination=${combinations[$SLURM_ARRAY_TASK_ID]}
subj_id=$(basename $(dirname $combination))
sess_id=$(basename $combination)
t1_file=$combination/anat/${subj_id}_${sess_id}_T1w.nii.gz

# Check if T1 file exists
if [ ! -f $t1_file ]; then
    echo "T1 file not found for $subj_id $sess_id"
    exit 1
fi

# Check if all required arguments are provided
if [[ -z "$BIDS_DIR" || -z "$OUTPUT_DIR" || -z "$SINGULARITY_IMG" || -z "$LICENSE_FILE" ]]; then
    echo "Error: Missing required arguments."
    exit 1
fi

# Set SUBJECTS_DIR to point to FreeSurfer output directory
SUBJECTS_DIR="${OUTPUT_DIR}/${sess_id}"
mkdir -p $SUBJECTS_DIR
output_subj_dir="${SUBJECTS_DIR}/${subj_id}"

echo "Processing $subj_id $sess_id"
echo "BIDS_DIR: $BIDS_DIR"
echo "OUTPUT_DIR: $OUTPUT_DIR"
echo "SINGULARITY_IMG: $SINGULARITY_IMG"
echo "LICENSE_FILE: $LICENSE_FILE"
echo "SUBJ_ID: $subj_id"
echo "SESS_ID: $sess_id"
echo "T1_FILE: $t1_file"
echo "SUBJECTS_DIR: $SUBJECTS_DIR"
echo "Output subject directory: $output_subj_dir"



# Check if output already exists to avoid reprocessing
# if [ -d "$output_subj_dir" ]; then
#     echo "Output already exists for ${subj_id}, skipping."
#     exit 0
# fi

# Load module and run recon-all using Singularity
module load apptainer

export APPTAINERENV_FS_LICENSE=$LICENSE_FILE

cmd="apptainer run --cleanenv \
    -B $BIDS_DIR:/data:ro \
    -B $SUBJECTS_DIR:/output \
    -B $LICENSE_FILE:/opt/freesurfer/license.txt \
    $SINGULARITY_IMG recon-all \
    -i /data/${subj_id}/${sess_id}/anat/${subj_id}_${sess_id}_T1w.nii.gz \
    -s ${subj_id} -sd /output -all -3T"

echo -e "Command line :"
echo -e $cmd

eval $cmd
