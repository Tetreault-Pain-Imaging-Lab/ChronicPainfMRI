#!/bin/bash

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
#   $2 - Subject identifier
run_fmriprep() {
    local visit=$1
    local subject=$2
    local bids_filter="${BIDS_FILTERS}/fmriprep_bids_filter_${visit}.json"
    export APPTAINERENV_TEMPLATEFLOW_HOME='/templateflow'
    export APPTAINERENV_FS_LICENSE=$LICENSE_FS

    printf "Running fmriprep for visit %s and subject %s\n" "$visit" "$subject"

    # Submit the fmriprep job to the scheduler with specified resources
    sbatch --job-name=fmriprep_${visit}_${subject} \
           --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/fmriprep_parallel/slurm-%A_%x.out" \
           --nodes=1 \
           --cpus-per-task=16 \
           --mem=10G \
           --time=3:00:00 <<EOF
#!/bin/bash
module load apptainer
apptainer run --cleanenv -B $TEMPLATEFLOW_PATH:/templateflow \
    "$FMRIPREP_IMG" "$INPUT_DIR" "$OUTPUT_DIR" participant \
    --participant-label $subject \
    -w "${OUTPUT_DIR}/work" \
    --output-spaces T1w MNI152NLin2009cSym \
    --cifti-output 91k \
    --bids-filter-file "$bids_filter" \
    --fs-subjects-dir "$FS_DIR" \
    --notrack 
EOF
}


## Main function
main() {
    # List of visits to process
    local visits=("v1" "v2" "v3")
    
    # Loop through each visit
    for visit in "${visits[@]}"; do
        # Fetch participants for the specified visit
        local participants
        if ! participants=$(bash "$REPOS_PATH/utils/get_subs_for_visit.sh" "$INPUT_DIR" "$visit"); then
            printf "Error fetching participants for visit %s\n" "$visit" >&2
            continue
        fi
        
        # Loop through each participant and run fmriprep
        for subject in $participants; do
            run_fmriprep "$visit" "$subject" || printf "Failed to submit job for visit %s and subject %s\n" "$visit" "$subject" >&2
            sleep 1m  # Add a 1-min wait time between job submissions

        done
        sleep 1
    done
}

# Execute the main function with passed arguments
main "$@"
