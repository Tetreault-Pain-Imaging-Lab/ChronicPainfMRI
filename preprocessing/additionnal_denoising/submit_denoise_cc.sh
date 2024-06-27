#!/bin/bash

# Set variables
SES_LABELS=("v1" "v2" "v3")
TASK_LABEL="rest"
SPACE_LABEL="MNI152NLin2009cSym"
FMRIPREP_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-13_fmriprep/results"

# Find all subject-session pairs
subjects=$(find $FMRIPREP_DIR -mindepth 1 -maxdepth 1 -type d -name "sub-*")

# Create a list of all subject-session pairs
subject_sessions=()
for sub_dir in $subjects; do
  subject=$(basename $sub_dir)
#   echo "Found subject: $subject"
  sessions=$(find $sub_dir -mindepth 1 -maxdepth 1 -type d -name "ses-*")
  for ses_dir in $sessions; do
    session=$(basename $ses_dir)
    # echo "Found session: $session for subject: $subject"
    subject_sessions+=("${subject}_${session}")
  done
done

# # Save the pairs to a file
# printf "%s\n" "${subject_sessions[@]}" > sub_ses_pairs.txt

# Export subject_sessions array for use in SBATCH script
export subject_sessions


# Define SBATCH script
SBATCH_SCRIPT="#!/bin/bash
#SBATCH --job-name=denoise_fmri
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --array=0-$((${#subject_sessions[@]}-1))
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00

# Load necessary modules or activate virtual environment if needed
# module load python
# source /path/to/virtualenv/bin/activate

subject_session=\${subject_sessions[\$SLURM_ARRAY_TASK_ID]}
subject=\$(echo \$subject_session | cut -d'_' -f1)
session=\$(echo \$subject_session | cut -d'_' -f2)

# Define input file paths
bold_file=${FMRIPREP_DIR}/\$subject/\$session/func/\${subject}_\${session}_task-${TASK_LABEL}_space-${SPACE_LABEL}_desc-preproc_bold.nii.gz
mask_file=${FMRIPREP_DIR}/\$subject/\$session/func/\${subject}_\${session}_task-${TASK_LABEL}_space-${SPACE_LABEL}_desc-brain_mask.nii.gz

# Define output file path
output_file=\${bold_file/preproc/denoised}

# Run denoise_with_nilearn.py
python /path/to/denoise_with_nilearn.py --input \$bold_file --mask \$mask_file --output \$output_file
"


# Write SBATCH script to a temporary file
echo "$SBATCH_SCRIPT" > /tmp/denoise_sbatch.sh

# Submit SBATCH script
sbatch /tmp/denoise_sbatch.sh
