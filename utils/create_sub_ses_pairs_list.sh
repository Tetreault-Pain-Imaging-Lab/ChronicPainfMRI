#!/bin/bash

# This scripts creates a txt file containing the subject-session pairs that are in a data_dir
# It doesn't look if subjects-session pairs have all the needed file, it only looks at present 
# folders in the directory.

# Example usage : bash utils/create_sub_ses_pairs_list.sh /home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-28_fmriprep/results .

# Set variables
data_dir="$1"
txt_file_path="$2"

# Find all subject-session pairs
subjects=$(find $data_dir -mindepth 1 -maxdepth 1 -type d -name "sub-*")

# Create a list of all subject-session pairs
subject_sessions=()
for sub_dir in $subjects; do
  subject=$(basename $sub_dir)
  echo "Found subject: $subject"
  sessions=$(find $sub_dir -mindepth 1 -maxdepth 1 -type d -name "ses-*")
  for ses_dir in $sessions; do
    session=$(basename $ses_dir)
    echo "Found session: $session for subject: $subject"
    subject_sessions+=("${subject}_${session}")
  done
done

# Save the pairs to a file
pairs_file="$txt_file_path/sub_ses_pairs.txt"
printf "%s\n" "${subject_sessions[@]}" > $pairs_file
