#!/bin/bash

# DOESN'T WORK

# launch_fmriprep_parallel.sh
# This script launches fmriprep on multiple subjects and visits in parallel using sbatch.
# This is a custom script to lauch fmriprep on a specific dataset onn compute canada. 
# Edit the main for a different datase and edit the function run_fmriprep to run with different options

#SBATCH --job-name=fmriprep_parallel
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G
#SBATCH --mail-user=ludo.a.levesque@gmail.com
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE,ALL
#SBATCH --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/fmriprep_parallel/slurm-%A.out"

## Global Variables (Set these variables manually)
# Path to the fmriprep Singularity image
FMRIPREP_IMG='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/fmriprep_23.2.3.sif'
# Input directory containing the dataset
INPUT_DIR='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test'
# Output directory for fmriprep results
OUTPUT_DIR='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-05_fmriprep/results'
# Path to TemplateFlow templates
TEMPLATEFLOW_PATH='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/templateflow'
# Directory for FreeSurfer subjects
FS_DIR='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/freesurfer_v1'
# Path to the repository (for utility scripts and license file)
REPOS_PATH='/home/ludoal/scratch/ChronicPainfMRI/'
# Path to your bids filter file (used to run fmriprep only on certain files)
BIDS_FILTERS='/home/ludoal/scratch/ChronicPainfMRI/bids_filters'
# Path to the FreeSurfer license file
LICENSE_FS="$REPOS_PATH/license.txt"

# Environment variables for TemplateFlow and FreeSurfer license
export APPTAINERENV_TEMPLATEFLOW_HOME='/templateflow'
export APPTAINERENV_FS_LICENSE=$LICENSE_FS

## Function to run fmriprep for a given subject and visit
# Arguments:
#   $1 - Visit identifier (e.g., v1, v2, v3)
#   $2 - Space separated list of subject identifiers
run_fmriprep() {
    local visit=$1
    local subjects=$2
    local bids_filter="${BIDS_FILTERS}/fmriprep_bids_filter_${visit}.json"

    printf "Running fmriprep for visit %s \n And subject %s\n" "$visit" "$subjects"

    # Submit the fmriprep job to the scheduler with specified resources (add ressources for bigger datasets)
    sbatch --job-name=fmriprep_${visit} \
           --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/fmriprep_parallel/slurm-%A_%x.out" \
           --nodes=1 \
           --cpus-per-task=32 \
           --mem=0 \
           --time=12:00:00 <<EOF
#!/bin/bash 
module load apptainer
apptainer run --cleanenv -B $TEMPLATEFLOW_PATH:/templateflow \
    "$FMRIPREP_IMG" "$INPUT_DIR" "$OUTPUT_DIR" participant \
    --participant-label $subjects \
    --output-spaces T1w MNI152NLin2009cSym \
    --cifti-output 91k \
    --bids-filter-file "$bids_filter" \
    --fs-subjects-dir "$FS_DIR" 
EOF
}


## Main function
main() {
    # List of visits to process
    # local visits=( "v1" )   #for testing
    local visits=("v1" "v2" "v3")
    
    # Loop through each visit
    for visit in "${visits[@]}"; do
        # Fetch participants for the specified visit
        local participants
        if ! participants=$(bash "$REPOS_PATH/utils/get_subs_for_visit.sh" "$INPUT_DIR" "$visit"); then
            printf "Error fetching participants for visit %s\n" "$visit" >&2
            continue
        fi
        
        run_fmriprep "$visit" "$participants" || printf "Failed to submit job for visit %s and subject %s\n" "$visit" "$participants" >&2
        sleep 1m  # Add a 1-min wait time between job submissions

    done
}

# Execute the main function with passed arguments
main "$@"
