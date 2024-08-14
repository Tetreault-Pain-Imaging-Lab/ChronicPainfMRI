#!/bin/bash

# This script installs the needed tools for this fMRI analysis in a folder given as argument and creates virtual environments to run certain scripts

# Example usage: bash /home/ludoal/scratch/ChronicPainfMRI/utils/install_tools_cc.sh /home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools /home/ludoal/scratch/ENV



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

fmriprep_img="fmriprep_23.2.3.sif"
tools_path=$TOOLS_PATH
utils_path="$REPOS_DIR/utils"
env_path="$tools_path/ENV"

# Load the required module
module load apptainer

## FMRIPREP

# Find the fmriprep_img and save the result in a variable
file_path=$(find "$tools_path" -type f -name "$fmriprep_img" -print -quit)

if [ -n "$file_path" ]; then
    echo "File $fmriprep_img exists at: $file_path, moving it to $tools_path/containers "
    mv $file_path $tools_path/containers
else
    echo "File $fmriprep_img does not exist in $tools_path or its subdirectories."
    
    if [ ! -d "$tools_path/containers" ];then 
        mkdir -p $tools_path/containers
    fi

    cd $tools_path/containers
    echo "Building $fmriprep_img in $tools_path/containers  ..."
    apptainer build "$fmriprep_img" docker://nipreps/fmriprep:23.2.3
fi

## FREESURFER ... (freesurfer/freesurfer:7.2.0)

freesurfer_img="freesurfer_7.2.0.sif"

# Find the freesurfer_img and save the result in a variable
file_path=$(find "$tools_path" -type f -name "$freesurfer_img" -print -quit)

if [ -n "$file_path" ]; then
    echo "File $freesurfer_img exists at: $file_path, moving it to $tools_path/containers "
    mv $file_path $tools_path/containers
else
    echo "File $freesurfer_img does not exist in $tools_path or its subdirectories."
    
    if [ ! -d "$tools_path/containers" ];then 
        mkdir -p $tools_path/containers
    fi

    cd $tools_path/containers
    echo "Building $freesurfer_img in $tools_path/containers  ..."
    apptainer build "$freesurfer_img" docker://freesurfer/freesurfer:7.2.0
fi


## TEMPLATEFLOW

# create a virtual environment to install the templateflow package
requirements_file="$REPOS_DIR/templateflow_requirements.txt"
module load python
ENVDIR="$env_path/templateflow"
virtualenv --no-download $ENVDIR
source $ENVDIR/bin/activate
pip install --no-index --upgrade pip
export TEMPLATEFLOW_HOME="$tools_path/templateflow"
pip install -v -r $requirements_file 

# Downloads the templates used in fmriprep
python $utils_path/load_templates.py 

