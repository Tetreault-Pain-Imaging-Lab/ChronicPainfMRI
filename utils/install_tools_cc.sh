#!/bin/bash

# This script sets up the necessary environment for running fMRIPrep and FreeSurfer using Singularity (Apptainer).
# It also prepares the TemplateFlow package for use with fMRIPrep.

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

# Define variables for the paths to the fMRIPrep and FreeSurfer Singularity images, tools, and environment directories.
fmriprep_img="fmriprep_23.2.3.sif"
tools_path=$TOOLS_PATH
utils_path="$REPOS_DIR/utils"
env_path="$tools_path/ENV"

# Load the required module for running Singularity (Apptainer).
module load apptainer

## FMRIPREP

# Search for the fMRIPrep Singularity image in the tools path and its subdirectories.
file_path=$(find "$tools_path" -type f -name "$fmriprep_img" -print -quit)

# If the image is found, move it to the containers directory.
if [ -n "$file_path" ]; then
    echo "File $fmriprep_img exists at: $file_path, moving it to $tools_path/containers "
    mv $file_path $tools_path/containers
else
    # If the image is not found, check if the containers directory exists; if not, create it.
    echo "File $fmriprep_img does not exist in $tools_path or its subdirectories."
    
    if [ ! -d "$tools_path/containers" ];then 
        mkdir -p $tools_path/containers
    fi

    # Change directory to the containers path and build the fMRIPrep Singularity image from DockerHub.
    cd $tools_path/containers
    echo "Building $fmriprep_img in $tools_path/containers  ..."
    apptainer build "$fmriprep_img" docker://nipreps/fmriprep:23.2.3
fi

## FREESURFER

# Define the FreeSurfer Singularity image filename.
freesurfer_img="freesurfer_7.2.0.sif"

# Search for the FreeSurfer Singularity image in the tools path and its subdirectories.
file_path=$(find "$tools_path" -type f -name "$freesurfer_img" -print -quit)

# If the image is found, move it to the containers directory.
if [ -n "$file_path" ]; then
    echo "File $freesurfer_img exists at: $file_path, moving it to $tools_path/containers "
    mv $file_path $tools_path/containers
else
    # If the image is not found, check if the containers directory exists; if not, create it.
    echo "File $freesurfer_img does not exist in $tools_path or its subdirectories."
    
    if [ ! -d "$tools_path/containers" ];then 
        mkdir -p $tools_path/containers
    fi

    # Change directory to the containers path and build the FreeSurfer Singularity image from DockerHub.
    cd $tools_path/containers
    echo "Building $freesurfer_img in $tools_path/containers  ..."
    apptainer build "$freesurfer_img" docker://freesurfer/freesurfer:7.2.0
fi

## TEMPLATEFLOW

# Define the requirements file for the TemplateFlow package.
requirements_file="$REPOS_DIR/templateflow_requirements.txt"

# Load the Python module required for creating a virtual environment.
module load python

# Define the directory for the TemplateFlow virtual environment.
ENVDIR="$env_path/templateflow"

# Create a virtual environment for installing the TemplateFlow package.
virtualenv --no-download $ENVDIR

# Activate the virtual environment.
source $ENVDIR/bin/activate

# Upgrade pip within the virtual environment.
pip install --no-index --upgrade pip

# Set the TEMPLATEFLOW_HOME environment variable to the specified path.
export TEMPLATEFLOW_HOME="$tools_path/templateflow"

# Install the required Python packages for TemplateFlow from the requirements file.
pip install -v -r $requirements_file 

# Run the script to download the templates used in fMRIPrep.
python $utils_path/load_templates.py 
