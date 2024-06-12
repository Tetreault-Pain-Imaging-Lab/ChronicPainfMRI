#!/bin/bash

# Function to display help message
usage() {
    echo "Usage: $0 --BIDS_dir <BIDS_DIR> --output_dir <OUTPUT_DIR> --singularity_img <SINGULARITY_IMG> --license_file <LICENSE_FILE> --subj_id <SUBJ_ID> --sess_id <SESS_ID> --t1_file <T1_FILE>"
    echo
    echo "Arguments:"
    echo "  --BIDS_dir       Path to the BIDS dataset directory"
    echo "  --output_dir     Path to the FreeSurfer output directory"
    echo "  --singularity_img Path to the FreeSurfer Singularity image"
    echo "  --license_file   Path to the FreeSurfer license file"
    echo "  --subj_id        Subject ID"
    echo "  --sess_id        Session ID"
    echo "  --t1_file        Path to the T1-weighted image file"
    echo "  --help           Show this help message and exit"
    exit 1
}

# Parse arguments using getopts
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --BIDS_dir)
            BIDS_DIR="$2"
            shift
            ;;
        --output_dir)
            OUTPUT_DIR="$2"
            shift
            ;;
        --singularity_img)
            SINGULARITY_IMG="$2"
            shift
            ;;
        --license_file)
            LICENSE_FILE="$2"
            shift
            ;;
        --subj_id)
            SUBJ_ID="$2"
            shift
            ;;
        --sess_id)
            SESS_ID="$2"
            shift
            ;;
        --t1_file)
            T1_FILE="$2"
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown parameter passed: $1"
            usage
            ;;
    esac
    shift
done

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

# Run recon-all using Singularity
singularity run --cleanenv \
    -B $BIDS_DIR:/data:ro \
    -B $SUBJECTS_DIR:/output \
    -B $LICENSE_FILE:/opt/freesurfer/license.txt \
    $SINGULARITY_IMG recon-all \
    -i /data/${SUBJ_ID}/${SESS_ID}/anat/${SUBJ_ID}_${SESS_ID}_T1w.nii.gz \
    -s ${SUBJ_ID} -sd /output -all -3T
