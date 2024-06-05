#!/bin/bash

# This script looks into the data_path for missing subject files (outliers)
# for a given session and returns a space-separated list of participant labels
# to use as the --participant-label argument in fmriprep. 
# It ensures that all participants with the necessary files (BOLD, T1) are included
# to prevent fmriprep from crashing. 

# Usage :
#     example : bash utils/get_subs_for_visit.sh '/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test' v1 

set -euo pipefail

# Assign command line arguments to variables
DATA_PATH="$1"  # Path to the BIDS dataset
SES="$2"        # Session identifier (e.g., v1)

SUB_NUMS=""     # Initialize a string to store subject numbers

# Function to remove trailing slashes from a path
sanitize_path() {
    local path="$1"
    printf "%s\n" "$path" | sed 's:/*$::'
}

# Function to extract subject number from the subject ID
get_sub_num() {
    local sub_id="$1"
    printf "%s\n" "$sub_id" | cut -d '-' -f 2
}

# Main function
main() {
    # Sanitize the data path
    DATA_PATH=$(sanitize_path "$DATA_PATH")

    # Loop through each subject folder in the data path
    for sub_folder in "$DATA_PATH"/sub*; do
        local sub_id sub_num search_folder
        sub_id=$(basename "$sub_folder")  # Extract subject ID from folder name
        sub_num=$(get_sub_num "$sub_id")  # Extract subject number from subject ID

        # Form path to session folder
        search_folder="$sub_folder/ses-$SES"

        # Check if all three required folders (func, anat, fmap) exist
        if [[ -d "$search_folder/func" && -d "$search_folder/anat" && -d "$search_folder/fmap" ]]; then
            # Add subject number to SUB_NUMS if all folders exist
            SUB_NUMS="$SUB_NUMS $sub_num"
        fi
    done

    # Output valid subject numbers as a space-separated list
    printf "%s\n" "$SUB_NUMS"
}

# Call the main function with command line arguments
main "$@"
