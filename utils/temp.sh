#!/bin/bash

# Example usage: bash /home/ludoal/scratch/ChronicPainfMRI/utils/install_tools_cc.sh /home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools

# Help message function
display_help() {
    echo "Usage: $0 [directory]"
    echo "Installs tools usefull for fMRI in the specified directory."
    echo "Arguments:"
    echo "  directory  The directory where the tools will be installed."
}

# Check for the --help option
if [[ "$1" == "--help" ]]; then
    display_help
    exit 0
fi

# Check for the number of command-line arguments
if [[ $# -eq 0 ]]; then
    echo "Error: Not enough arguments. Provide the directory where you want to install the tools."
    exit 1
elif [[ $# -gt 1 ]]; then
    echo "Error: Too many arguments."
    exit 1
fi

# Initialize a variable 'directory' with the value of the argument
directory="$1"
if [ -d "$directory" ]; then
    # Directory exists
    echo "Directory exists."
else
    # Directory does not exist
    echo "Directory does not exists, creating it ..."
    mkdir -p "$directory"
fi

# Load the required module
module load StdEnv/2020 java/14.0.2 nextflow/21.10.3 apptainer/1.1.8

## FMRIPREP
# Build the .sif file in a directory called containers
if [ ! -d "${directory}/containers" ]; then
    mkdir "${directory}/containers" || { echo "Failed to create containers directory. Exiting..."; exit 1; }
fi

if [ ! -f "${directory}/containers/fmriprep_23.2.3.sif" ]; then
    apptainer build fmriprep_23.2.3.sif docker://nipreps/fmriprep:23.2.3|| exit 1
    mv fmriprep_23.2.3.sif "${directory}/containers"
else
    echo "fmriprep_23.2.3.sif is already installed" 
fi

## TEMPLATEFLOW



# Clone the necessary repository in the specified directory
tractoflow_path="${directory}/tractoflow"


if [ -d "$tractoflow_path" ]; then
    echo "tractoflow is already installed. Skipping installation"
else
    git clone https://github.com/scilus/tractoflow.git "$tractoflow_path" || exit 1
fi

if [ -d "$dmriqc_path" ]; then
    echo "dmriqc_flow is already installed.Skipping installation"
else
    git clone https://github.com/scilus/dmriqc_flow.git "$dmriqc_path" || exit 1
fi

if [ -d "$rbx_path" ]; then
    echo "rbx_flow is already installed. Skipping installation"
else
    git clone https://github.com/scilus/rbx_flow.git "$rbx_path" || exit 1
fi

if [ -d "$combineflow_path" ]; then
    echo "combine_flow is already installed. Skipping installation"
else
    git clone https://github.com/scilus/combine_flows.git "$combineflow_path" || exit 1
fi

if [ -d "$tractometryflow_path" ]; then
    echo "tractometry_flow is already installed. Skipping installation"
else
    git clone https://github.com/scilus/tractometry_flow.git "$tractometryflow_path" || exit 1
fi

# Create the atlas folder fo bundleseg (using the version 3.1 on https://zenodo.org/records/10103446, there might be newer version)
atlas_folder="${directory}/atlas_dir"
echo "Atlas folder : ${atlas_folder} "

if [ ! -d $atlas_folder ];then
    echo "The atlas folder doesnt exist. Creating it and downoading atlas files"
    wget https://zenodo.org/records/10103446/files/atlas.zip || exit 1
    wget https://zenodo.org/records/10103446/files/config.zip || exit 1
    unzip atlas.zip -d $atlas_folder
    unzip config.zip -d $atlas_folder
    rm *.zip
 
else
    echo "Atlas folder already exist"
    tree $atlas_folder
fi