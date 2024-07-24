#!/bin/bash

# This would run fMRIprep with the following parameters:
#   - bids: clinical data from TPIL lab (27 CLBP and 25 control subjects);
#   - with-singularity: container image fMRIprep 23.2.0


# Define the path to the configuration file
CONFIG_FILE="my_variables.sh"

# Check if the configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Configuration file not found."
  echo "Please ensure the current directory is ChronicPainfMRI or a parent directory when running this script."
  exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"
complete_config_path="$REPOS_DIR/$CONFIG_FILE"


my_fmriprep_img="$TOOLS_PATH/containers/fmriprep_23.2.3.sif" # or .img
my_input=$BIDS_DIR
my_output="${OUTPUT_DIR}/fmriprep_all"

my_templateflow_path="$TOOLS_PATH/templateflow"
fs_dir='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-07-09_freesurfer'  # Path to freesurfer output folder containing one subfolder for each session
my_licence_fs="$REPOS_DIR/license.txt" # get your license by registering here : https://surfer.nmr.mgh.harvard.edu/registration.html


TMP_SCRIPT=$(mktemp /tmp/slurm-frmriprep_XXXXXX.sh)

# Write the SLURM script to the temporary file
cat <<EOT > $TMP_SCRIPT
#!/bin/bash
$fmriprep_ressources


source $complete_config_path


participants=""
if [ "\$longitudinal" = true ]; then
    session=\${SESSIONS[\$SLURM_ARRAY_TASK_ID]}
    if ! participants=\$(bash "$REPOS_DIR/utils/get_subs_for_session.sh" "$my_input" "\$session"); then
        printf "Error fetching participants for session %s\n" "\$session" >&2
        continue
    fi

    echo -e "Valid subjects for \$session are :\n\$participants\n"

    # Fetch the right bids_filter file 
    my_bids_filter="${REPOS_DIR}/bids_filters/fmriprep_bids_filter_\${session}.json"

    fs_sub_dir="${fs_dir}/ses-\${session}"


else
    if ! participants=\$(bash "$REPOS_DIR/utils/get_all_subs.sh" "$my_input"); then
        printf "Error fetching participants\n" >&2
    echo -e "Valid subjects are :\n\$participants\n"
        continue
    fi

    echo -e "Valid subjects are :\n\$participants\n"

    # Fetch the right bids_filter file 
    my_bids_filter="${REPOS_DIR}/bids_filters/fmriprep_bids_filter.json"

    fs_sub_dir=$fs_dir


fi


# Make sure array jobs have different work dir per SESSIONS if there are sessions
my_work=$REPOS_DIR/fmriprep_work/\$session
if [ ! -d \$my_work ]; then
    mkdir -p \$my_work
fi

# To check if the license is accesible to fmriprep use this line :
# apptainer exec --cleanenv -B /project:/project -B /scratch:/scratch $my_fmriprep_img env | grep FS_LICENSE


export APPTAINERENV_TEMPLATEFLOW_HOME=$my_templateflow_path
export APPTAINERENV_FS_LICENSE=$my_licence_fs

module load apptainer 

apptainer run --cleanenv \
    $my_fmriprep_img $my_input $my_output participant \
    --participant-label \$participants \
    --output-spaces T1w MNI152NLin2009cSym \
    --cifti-output 91k \
    --bids-filter-file \$my_bids_filter \
    --fs-subjects-dir \$fs_sub_dir \
    -w \$my_work

EOT

# uncomment to print the script in the terminal
# cat $TMP_SCRIPT

# Submit the scipt as a slurm job
sbatch $TMP_SCRIPT


# Uncomment to automatically remove the temporary script 
# sleep 5s
# rm $TMP_SCRIPT


