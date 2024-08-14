#!/bin/bash

# Define the path to the configuration file
DEFAULT_CONFIG_FILE="config_ex.sh"

# Check if an argument is provided
if [ "$#" -eq 1 ]; then
    CONFIG_FILE="$1"
else
    CONFIG_FILE="$DEFAULT_CONFIG_FILE"
fi

# Check if the config file exists
if [ -f "$CONFIG_FILE" ]; then
    # Source the config file
    source "$CONFIG_FILE"
    echo "Using config file: $CONFIG_FILE"
else
    echo "Error: Config file '$CONFIG_FILE' not found."
    exit 1
fi

complete_config_path="$REPOS_DIR/$CONFIG_FILE"

TMP_t1_list="avail_T1s.txt"

find "$BIDS_DIR" -type f -name '*T1w.nii.gz' >> "$TMP_t1_list"

num_combinations=$(grep -cve '^\s*$' "$TMP_t1_list")
first_t1_file=$(head -n 1 "$TMP_t1_list")
rm $TMP_t1_list

session_id=$(echo "$first_t1_file" | grep -o -E 'ses-[^_]+')
if [ "$longitudinal" = "true" ] && [ -z "$session_id" ]; then
    echo "Your config_file indicates your dataset is longitudinal, However no session ID was found in your data."
    exit 1
fi
if [ "$longitudinal" = "false" ] && [ ! -z "$session_id" ]; then
    echo "Your config_file indicates your dataset is not longitudinal, However a session ID was found in your data."
    exit 1
fi

fs_dir="${OUTPUT_DIR}/freesurfer"

# Check if the variable fs_dir exists in the config file
if grep -q "^fs_dir=" "$CONFIG_FILE"; then
    sed -i "s|^fs_dir=.*|fs_dir=\"$fs_dir\"|" "$CONFIG_FILE"
else
    echo "fs_dir=\"$fs_dir\"" >> "$CONFIG_FILE"
fi

echo "Set fs_dir to $fs_dir in $CONFIG_FILE, to be used in further steps. 
Modify it directly in the config file if you change the name of the freesurfer folder manually."

SINGULARITY_IMG="$TOOLS_PATH/containers/freesurfer_7.2.0.sif"

TMP_SCRIPT=$(mktemp /tmp/slurm-freesurfer_XXXXXX.sh)

# Write the SLURM script to the temporary file
cat <<EOT > "$TMP_SCRIPT"
#!/bin/bash
$freesurfer_ressources
#SBATCH --array=1-$num_combinations

source "$complete_config_path"

TMP_t1_list="avail_T1s_\${SLURM_ARRAY_TASK_ID}.txt"
find "\$BIDS_DIR" -type f -name '*T1w.nii.gz' >> "\$TMP_t1_list"

# Get subject and session info from array index
T1_file_path=\$(sed -n "\${SLURM_ARRAY_TASK_ID}p" "\$TMP_t1_list")
T1_filename=\$(basename "\$T1_file_path")
subject_id=\$(echo "\$T1_filename" | grep -o -E 'sub-[0-9]{3}')
session_id=\$(echo "\$T1_filename" | grep -o -E 'ses-[^_]+')
rm "\$TMP_t1_list"

# Set SUBJECTS_DIR to point to FreeSurfer output directory
if [ "\$longitudinal" = "true" ]; then
    SUBJECTS_DIR="$fs_dir/\${session_id}"
else
    SUBJECTS_DIR="$fs_dir/"
    session_id=""
fi

if [ ! -d "\$SUBJECTS_DIR" ]; then
    mkdir -p "\$SUBJECTS_DIR"
fi

output_subj_dir="\${SUBJECTS_DIR}/\${subject_id}"

# Check if output already exists and is not empty to avoid reprocessing
if [ -d "\$output_subj_dir" ] && [ "\$(ls -A "\$output_subj_dir")" ]; then
    echo "Output already exists for \${subject_id} and is not empty, skipping."
    exit 0
fi

# Load module and run recon-all using Singularity
module load apptainer

export APPTAINERENV_FS_LICENSE=$LICENSE_FILE

cmd="apptainer run --cleanenv \
    -B $BIDS_DIR:/data:ro \
    -B \$SUBJECTS_DIR:/output \
    -B \$LICENSE_FILE:/opt/freesurfer/license.txt \
    $SINGULARITY_IMG recon-all \
    -i /data/\${subject_id}/\${session_id}/anat/\$T1_filename \
    -s \${subject_id} -sd /output -all -3T"

echo -e "Command line:\n\$cmd"

eval \$cmd



EOT

# Uncomment to print the script in the terminal
# cat "$TMP_SCRIPT"

# Submit the script as a Slurm job
sbatch "$TMP_SCRIPT"
