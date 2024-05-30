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
directory="$1"

## FMRIPREP

# Find the fmriprep_img and save the result in a variable
file_path=$(find "$directory" -type f -name "$fmriprep_img" -print -quit)

# Load the required module
module load apptainer

if [ -n "$file_path" ]; then
    echo "File $fmriprep_img exists at: $file_path"
else
    echo "File $fmriprep_img does not exist in $directory or its subdirectories."
    echo "Building $fmriprep_img..."
    apptainer build "$fmriprep_img" docker://nipreps/fmriprep:23.2.3
fi

# Add the file to .gitignore to prevent it from getting pushed in commits
if ! grep -qF "$fmriprep_img" .gitignore; then
    echo "$fmriprep_img" >> .gitignore
    echo "Added $fmriprep_img to .gitignore"
else
    echo "$fmriprep_img is already in .gitignore"
fi


## TEMPLATEFLOW
tmp=$(find)
# create a temporary virtual environment to install the templateflow package
module load python
ENVDIR='/home/ludoal/ENV/templateflow'
virtualenv --no-download $ENVDIR
source $ENVDIR/bin/activate
pip install --no-index --upgrade pip
export TEMPLATEFLOW_HOME="$directory/templateflow"
pip install -v -r requirements.txt
python /home/ludoal/scratch/ChronicPainfMRI/utils/load_templates.py # Downloads the templates used in fmriprep

rm -rf $ENVDIR
