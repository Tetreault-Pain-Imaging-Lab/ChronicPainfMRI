#!/bin/bash

# This script installs the needed tools for this fMRI analysis in a folder given as argument

# Example usage: bash /home/ludoal/scratch/ChronicPainfMRI/utils/install_tools_cc.sh /home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools

# Function to display script usage information
display_help() {
    echo "This script installs the needed tools for this fMRI analysis in a folder given as argument"
    echo "Usage: $(basename "$0") [tools_folder] [options]"
    echo "Options:"
    echo "  --help    Display the help message"
}

fmriprep_img="fmriprep_23.2.3.sif"
tools_path="$1"
utils_path="$(dirname "$(realpath "$0")")"

## FMRIPREP

# Find the fmriprep_img and save the result in a variable
file_path=$(find "$tools_path" -type f -name "$fmriprep_img" -print -quit)

# Load the required module
module load apptainer

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

# create a temporary virtual environment to install the templateflow package
if [ ! -d $tools_path/templateflow ]; then
    # create a temporary virtual environment to install the templateflow package
    module load python
    ENVDIR="$HOME/ENV/templateflow"
    virtualenv --no-download $ENVDIR
    source $ENVDIR/bin/activate
    pip install --no-index --upgrade pip
    export TEMPLATEFLOW_HOME="$tools_path/templateflow"
    pip install -v -r requirements.txt
    python $utils_path/load_templates.py # Downloads the templates used in fmriprep
    
else 
    echo "directory $tools_path/templateflow already exists, skipping the installation"
fi

rm -rf $ENVDIR


