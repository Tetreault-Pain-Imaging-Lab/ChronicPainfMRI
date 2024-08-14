#!/bin/bash

# This script prepares and submits a SLURM job for running fMRIPrep, 
# a tool for preprocessing MRI data, within a Singularity (Apptainer) container.

# Define the default path to the configuration file
DEFAULT_CONFIG_FILE="config_ex.sh"

# Check if an argument is provided
# If an argument is given, use it as the configuration file path.
# Otherwise, use the default configuration file.
if [ "$#" -eq 1 ]; then
    CONFIG_FILE="$1"
else
    CONFIG_FILE="$DEFAULT_CONFIG_FILE"
fi

# Check if the specified configuration file exists
if [ -f "$CONFIG_FILE" ]; then
    # Source (import) the configuration file to make its variables and settings available
    source "$CONFIG_FILE"
    echo "Using config file: $CONFIG_FILE"
else
    # If the config file is not found, print an error message and exit the script
    echo "Error: Config file '$CONFIG_FILE' not found."
    exit 1
fi

# Check if the FreeSurfer subjects directory exists
if [ ! -d "$fs_dir" ]; then
    echo "Error: FreeSurfer subjects directory 'fs_dir' not found. Make sure you ran freesurfer before fmriprep"
    exit 1
fi

# Construct the full path to the configuration file based on the REPOS_DIR variable
complete_config_path="$REPOS_DIR/$CONFIG_FILE"

# Define paths and variables for fMRIPrep execution
my_fmriprep_img="$TOOLS_PATH/containers/fmriprep_23.2.3.sif" # Path to the fMRIPrep Singularity image (.sif or .img)
my_input=$BIDS_DIR  # Input directory containing BIDS-compliant data
my_output="${OUTPUT_DIR}/fmriprep"  # Output directory for fMRIPrep results

# Define paths for TemplateFlow and FreeSurfer license
my_templateflow_path="$TOOLS_PATH/templateflow"
my_licence_fs="$REPOS_DIR/license.txt" # Path to the FreeSurfer license file

# Create a temporary file to hold the SLURM submission script
TMP_SCRIPT=$(mktemp /tmp/slurm-frmriprep_XXXXXX.sh)

# Write the SLURM script to the temporary file
cat <<EOT > $TMP_SCRIPT
#!/bin/bash

# Load any additional resources needed for fMRIPrep
$fmriprep_ressources

# Source the configuration file inside the SLURM job
source $complete_config_path

# Initialize an empty string to store participant labels
participants=""

# Check if the analysis is longitudinal (involving multiple sessions per participant)
if [ "\$longitudinal" = true ]; then
    # If longitudinal, fetch the session ID from the SLURM_ARRAY_TASK_ID
    session=\${SESSIONS[\$SLURM_ARRAY_TASK_ID]}
    
    # Get participants for the specified session
    if ! participants=\$(bash "$REPOS_DIR/utils/get_subs_for_session.sh" "$my_input" "\$session"); then
        printf "Error fetching participants for session %s\n" "\$session" >&2
        continue
    fi

    # Print the list of valid subjects for the session
    echo -e "Valid subjects for \$session are :\n\$participants\n"

    # Select the appropriate BIDS filter file for the session
    my_bids_filter="${REPOS_DIR}/bids_filters/fmriprep_bids_filter_\${session}.json"

    # Define the FreeSurfer subjects directory for this session
    fs_sub_dir="${fs_dir}/ses-\${session}"

else
    # If not longitudinal, get all participants from the input directory
    if ! participants=\$(bash "$REPOS_DIR/utils/get_all_subs.sh" "$my_input"); then
        printf "Error fetching participants\n" >&2
        continue
    fi

    # Print the list of valid subjects
    echo -e "Valid subjects are :\n\$participants\n"

    # Select the default BIDS filter file
    my_bids_filter="${REPOS_DIR}/bids_filters/fmriprep_bids_filter.json"

    # Use the default FreeSurfer subjects directory
    fs_sub_dir=$fs_dir
fi

# Ensure that each session (if present) has its own working directory
my_work=$my_output/work/\$session
if [ ! -d \$my_work ]; then
    mkdir -p \$my_work
fi

# Set environment variables for the fMRIPrep container
export APPTAINERENV_TEMPLATEFLOW_HOME=$my_templateflow_path
export APPTAINERENV_FS_LICENSE=$my_licence_fs

# Load the Apptainer (Singularity) module
module load apptainer 

# Run fMRIPrep inside the Apptainer container
apptainer run --cleanenv \
    $my_fmriprep_img $my_input $my_output participant \
    --participant-label \$participants \
    --output-spaces T1w MNI152NLin2009cSym \
    --cifti-output 91k \
    --bids-filter-file \$my_bids_filter \
    --fs-subjects-dir \$fs_sub_dir \
    -w \$my_work

EOT

# Uncomment the following line to print the generated SLURM script to the terminal for debugging
# cat $TMP_SCRIPT

# Submit the script as a SLURM job
sbatch $TMP_SCRIPT