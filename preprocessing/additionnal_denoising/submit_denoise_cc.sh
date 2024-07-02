#!/bin/bash

# Set variables
SES_LABELS=("v1" "v2" "v3")
TASK_LABEL="rest"
SPACE_LABEL="MNI152NLin2009cSym"
FMRIPREP_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-28_fmriprep/results"
ENVDIR='/home/ludoal/scratch/ENV/fMRI'
repos_path='/home/ludoal/scratch/ChronicPainfMRI'

# Find all subject-session pairs
subjects=$(find $FMRIPREP_DIR -mindepth 1 -maxdepth 1 -type d -name "sub-*")

# Create a list of all subject-session pairs
bash $repos_path/utils/create_sub_ses_pairs_list.sh $FMRIPREP_DIR $repos_path

# Count number of pairs
num_pairs=${#subject_sessions[@]}

# Define SBATCH script
SBATCH_SCRIPT="#!/bin/bash
#SBATCH --job-name=denoise_fmri
#SBATCH --output=/home/ludoal/scratch/ChronicPainfMRI/outputs/denoising/%x_%A_%a.out
#SBATCH --error=/home/ludoal/scratch/ChronicPainfMRI/outputs/denoising/%x_%A_%a.err
#SBATCH --array=0-$(($num_pairs-1))
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=01:00:00

# Load necessary modules or activate virtual environment if needed
module load python
source ${ENVDIR}/bin/activate

# Debugging output
echo \"Starting job array task ID \$SLURM_ARRAY_TASK_ID\"

# Read the subject-session pair for this job
subject_session=\$(sed -n \"\$((SLURM_ARRAY_TASK_ID + 1))p\" $pairs_file)
echo \"Processing subject_session: \$subject_session\"
subject=\$(echo \"\$subject_session\" | cut -d'_' -f1)
session=\$(echo \"\$subject_session\" | cut -d'_' -f2)

# Define input file paths
bold_file=${FMRIPREP_DIR}/\$subject/\$session/func/\${subject}_\${session}_task-${TASK_LABEL}_space-${SPACE_LABEL}_desc-preproc_bold.nii.gz
mask_file=${FMRIPREP_DIR}/\$subject/\$session/func/\${subject}_\${session}_task-${TASK_LABEL}_space-${SPACE_LABEL}_desc-brain_mask.nii.gz

# Define output file path
output_file=\${bold_file/bold/bold_denoised}

# Run denoise_with_nilearn.py
python $repos_path/preprocessing/additionnal_denoising/denoise_with_nilearn.py --input \$bold_file --strategy simple --mask \$mask_file --output \$output_file
"

# Write SBATCH script to a temporary file
sbatch_script_file="/tmp/denoise_sbatch.sh"
echo "$SBATCH_SCRIPT" > $sbatch_script_file

# Submit SBATCH script
sbatch $sbatch_script_file
