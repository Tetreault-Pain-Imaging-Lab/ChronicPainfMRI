#!/bin/bash

# This script installs the needed tools for this fMRI analysis in a folder given as argument

# Function to display script usage information
display_help() {
    echo "This script installs the needed tools for this fMRI analysis in a folder given as argument"
    echo "Usage: $(basename "$0") [tools_folder] [options]"
    echo "Options:"
    echo "  --help    Display the help message"
}

# Default values
filename="fmriprep_23.2.3.sif"

# Check for command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            display_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            display_help
            exit 1
            ;;
    esac
    shift
done

# Find the file and save the result in a variable
file_path=$(find "$directory" -type f -name "$filename" -print -quit)

# Load the required module
module load apptainer

if [ -n "$file_path" ]; then
    echo "File $filename exists at: $file_path"
else
    echo "File $filename does not exist in $directory or its subdirectories."
    echo "Building $filename..."
    apptainer build "$filename" docker://nipreps/fmriprep:23.2.3
fi

# Add the file to .gitignore to prevent it from getting pushed in commits
if ! grep -qF "$filename" .gitignore; then
    echo "$filename" >> .gitignore
    echo "Added $filename to .gitignore"
else
    echo "$filename is already in .gitignore"
fi