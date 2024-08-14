#!/bin/bash

# This script sets up and submits a SLURM job for processing MRI data with FreeSurfer using Singularity (Apptainer).

# Define the default path to the configuration file
DEFAULT_CONFIG_FILE="config_ex.sh"

# Check if a configuration file is provided as an argument.
# If an argument is provided, use it as the config file path.
# Otherwise, use the default config file.
if [ "$#" -eq 1 ]; then
    CONFIG_FILE="$1"
else
    CONFIG_FILE="$DEFAULT_CONFIG_FILE"
fi

# Check if the specified config file exists.
if [ -f "$CONFIG_FILE" ]; then
    # Source (import) the configuration file to make its variables and settings available.
    source "$CONFIG_FILE"
    echo "Using config file: $CONFIG_FILE"
else
    # If the config file is not found, print an error message and exit the script.
    echo "Error: Config file '$CONFIG_FILE' not found."
    exit 1
fi

# Construct the full path to the configuration file based on the REPOS_DIR variable.
complete_config_path="$REPOS_DIR/$CONFIG_FILE"

# Define a temporary file to store the list of available T1-weighted MRI files.
TMP_t1_list="avail_T1s.txt"

# Find all T1-weighted MRI files in the BIDS-compliant input directory and save their paths to the temporary list.
find "$BIDS_DIR" -type f -name '*T1w.nii.gz' >> "$TMP_t1_list"

# Count the number of non-empty lines in the list, which corresponds to the number of T1 files found.
num_combinations=$(grep -cve '^\s*$' "$TMP_t1_list")

# Get the path of the first T1 file from the list.
first_t1_file=$(head -n 1 "$TMP_t1_list")

# Remove the temporary list file to clean up.
rm $TMP_t1_list

# Extract the session ID from the first T1 file's path using a regular expression.
session_id=$(echo "$first_t1_file" | grep -o -E 'ses-[^_]+')

# Check if the dataset is longitudinal (involving multiple sessions per participant).
# If the dataset is marked as longitudinal but no session ID is found, print an error message and exit.
if [ "$longitudinal" = "true" ] && [ -z "$session_id" ]; then
    echo "Your config_file indicates your dataset is longitudinal, However no session ID was found in your data."
    exit 1
fi

# If the dataset is not marked as longitudinal but a session ID is found, print an error message and exit.
if [ "$longitudinal" = "false" ] && [ ! -z "$session_id" ]; then
    echo "Your config_file indicates your dataset is not longitudinal, However a session ID was found in your data."
    exit 1
fi

# Define the FreeSurfer output directory path.
fs_dir="${OUTPUT_DIR}/freesurfer"

# Check if the variable fs_dir exists in the config file.
# If it exists, update its value to the new FreeSurfer directory path.
# If it does not exist, add it to the config file.
if grep -q "^fs_dir=" "$CONFIG_FILE"; then
    sed -i "s|^fs_dir=.*|fs_dir=\"$fs_dir\"|" "$CONFIG_FILE"
else
    echo "fs_dir=\"$fs_dir\"" >> "$CONFIG_FILE"
fi

# Inform the user that fs_dir has been set in the config file.
echo "Set fs_dir to $fs_dir in $CONFIG_FILE, to be used in further steps. 
Modify it directly in the config file if you change the name of the freesurfer folder manually."

# Define the path to the Singularity (Apptainer) image for FreeSurfer.
SINGULARITY_IMG="$TOOLS_PATH/containers/freesurfer_7.2.0.sif"

# Create a temporary file to hold the SLURM submission script.
TMP_SCRIPT=$(mktemp /tmp/slurm-freesurfer_XXXXXX.sh)

# Write the SLURM script to the temporary file.
cat <<EOT > "$TMP_SCRIPT"
#!/bin/bash

# Load the FreeSurfer resources specified in the config file.
$freesurfer_ressources

# Set the SLURM job array to process each T1-weighted MRI file.
#SBATCH --array=1-$num_combinations

# Source the configuration file inside the SLURM job.
source "$complete_config_path"

# Define a temporary list to hold the T1 files for the current SLURM array task.
TMP_t1_list="avail_T1s_\${SLURM_ARRAY_TASK_ID}.txt"

# Find all T1-weighted MRI files again and save them to the temporary list.
find "\$BIDS_DIR" -type f -name '*T1w.nii.gz' >> "\$TMP_t1_list"

# Get the T1 file path corresponding to the current SLURM array task.
T1_file_path=\$(sed -n "\${SLURM_ARRAY_TASK_ID}p" "\$TMP_t1_list")

# Extract the filename, subject ID, and session ID from the T1 file path.
T1_filename=\$(basename "\$T1_file_path")
subject_id=\$(echo "\$T1_filename" | grep -o -E 'sub-[0-9]{3}')
session_id=\$(echo "\$T1_filename" | grep -o -E 'ses-[^_]+')

# Remove the temporary list file to clean up.
rm "\$TMP_t1_list"

# Set the FreeSurfer SUBJECTS_DIR based on whether the analysis is longitudinal.
if [ "\$longitudinal" = "true" ]; then
    SUBJECTS_DIR="$fs_dir/\${session_id}"
else
    SUBJECTS_DIR="$fs_dir/"
    session_id=""
fi

# Create the SUBJECTS_DIR directory if it does not already exist.
if [ ! -d "\$SUBJECTS_DIR" ]; then
    mkdir -p "\$SUBJECTS_DIR"
fi

# Define the output directory for the current subject.
output_subj_dir="\${SUBJECTS_DIR}/\${subject_id}"

# Check if the output directory already exists and is not empty to avoid reprocessing.
if [ -d "\$output_subj_dir" ] && [ "\$(ls -A "\$output_subj_dir")" ]; then
    echo "Output already exists for \${subject_id} and is not empty, skipping."
    exit 0
fi

# Load the Apptainer (Singularity) module.
module load apptainer

# Set the environment variable for the FreeSurfer license file.
export APPTAINERENV_FS_LICENSE=$LICENSE_FILE

# Construct the command to run FreeSurfer's recon-all using Singularity.
cmd="apptainer run --cleanenv \
    -B $BIDS_DIR:/data:ro \
    -B \$SUBJECTS_DIR:/output \
    -B \$LICENSE_FILE:/opt/freesurfer/license.txt \
    $SINGULARITY_IMG recon-all \
    -i /data/\${subject_id}/\${session_id}/anat/\$T1_filename \
    -s \${subject_id} -sd /output -all -3T"

# Print the constructed command for debugging.
echo -e "Command line:\n\$cmd"

# Execute the constructed command.
eval \$cmd

EOT

# Uncomment the following line to print the generated SLURM script to the terminal for debugging.
# cat "$TMP_SCRIPT"

# Submit the generated script as a SLURM job.
sbatch "$TMP_SCRIPT"
