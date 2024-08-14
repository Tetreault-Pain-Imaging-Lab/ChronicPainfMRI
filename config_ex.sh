#!/bin/bash


# This files contains variables for you to set manually to be used in the scripts of this repository

# REPOS_DIR is the where you installed/cloned the ChronicPainDWI on your machine ChronicPainDWI
REPOS_DIR="/home/ludoal/scratch/ChronicPainfMRI"

# The tools_path is going to contain all tools like the sclilus lab container and their nextflow tools.
# We recommend you choose a path on your /user/projects directory to prevent it from being purged.
# It will be first used in the script /utils/install_tools_cc.sh, then as a reference to find tools
TOOLS_PATH="/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools"

 
#  BIDS_dir is the path where you have your raw BIDS formatted dataset. 
#  It should contain the subject folders and the following files :
#       -participants.tsv :
#       -participants.json : necessary for BIDS format (see BIDS documentation for what it should contain)
#       -dataset_description.json : necessary for BIDS format
BIDS_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/complete_dataset_raw"

# The results will be stored in folders named after the pipeline that produced them under the OUTPUT_DIR
OUTPUT_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal"


# You will need a freesurfer license file for fmriprep 
LICENSE_FILE="/home/ludoal/scratch/ChronicPainfMRI/license.txt"

# If your dataset is cross sectionnal, set to false
longitudinal=true

# The session labels of your longitudinal data
SESSIONS=("v1" "v2")
N_SESSIONS=${#SESSIONS[@]} 





# bids_filter files should be created for your dataset. See the README of the bids_filters folder
# If your dataset is longitudinal, you need a bids_filter file for each session, and you need to 
# add the session name at the end of the bids_filter file name. ex : fmriprep_bids_filter_v1.json
bids_filter_path="$REPOS_DIR/bids_filters" 


###############################         Ressource alloacation         ##########################################
#
# SLURM Parameters info :
#   --nodes: Number of nodes to allocate. Generally depends on the number of subjects and available cores per task.
#            If you have more subjects than cores (e.g., 38 subjects and 32 cpus-per-task), consider requesting an additional node.
#   --cpus-per-task: Number of CPUs to allocate per task. Choose based on your cluster's available configurations. 
#                    For example, Beluga allows 32, 40, or 64 CPUs per task.
#                    More information: https://docs.computecanada.ca/wiki/B%C3%A9luga/en#Node_Characteristics
#   --mem: Memory allocation per node. Setting this to 0 allocates all available memory on the node.
#          Adjust based on expected memory usage.
#   --time: Maximum job runtime. Adjust based on your pipeline's expected duration.
#   --mail-user: Email address for job notifications.
#   --mail-type: Conditions under which to send job status emails (BEGIN, END, FAIL, REQUEUE, ALL).
#   --output: Path to the output log file for the SLURM job. %A is the job ID.
#
# To monitor tasks use portals like https://portail.narval.calculquebec.ca/ (for narval)

#  Set the following variables to adjust ressources to your need. You will have to set them for every sbatch script (run_tractoflow_cc.sh, run_rbx_cc.sh and run_tractometry_cc.sh)

# General SBATCH directives 
MAIL="ludo.a.levesque@gmail.com"  # optionnal, remove the `#SBATCH --mail` lines in the ressources variables if you don't want this option
SLURM_OUT="$REPOS_DIR/outputs" 

# fmriprep ressources allocation (used in for the script /tractoflow/run_tractoflow_cc.sh)
fmriprep_ressources="#SBATCH --job-name=fmriprep_all
#SBATCH --time=20:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=0
#SBATCH --output=\"$SLURM_OUT/fmriprep_long/%slurm-%A-%a.out\"   
#SBATCH --mail-user=$MAIL
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --array=0-$((N_SESSIONS-1))"

# freesurfer ressources allocation (used in freesurfer_longitudinal.sh)
freesurfer_ressources="#SBATCH --job-name=freesurfer_long
#SBATCH --time=10:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3700M
#SBATCH --output=\"$SLURM_OUT/freesurfer_long/%slurm-%A-%a.out\"   
#SBATCH --mail-user=$MAIL
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE"


# Some variables might be added here by some scripts to speed up processing:
fs_dir='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-07-09_freesurfer'  # Path to freesurfer output folder containing one subfolder for each session
participants_v1=" 002 006 007 008 010 012 013 014 015 016 017 019 021 022 023 024 025 027 029 030 031 032 034 036 037 038 039 040 041 042 046 047 048 049 050 051 052 053 054 055 056 057 058 059 060 061 062 063 064 065"
participants_v2=" 002 006 007 010 012 013 014 015 016 017 019 021 022 023 024 025 027 029 030 031 032 034 035 036 038 040 041 042 046 047 048 049 050 051 052 053 054 055 056 058 059 060 061 062 063 064 065"
participants_v3=" 002 004 006 007 010 012 013 014 015 017 019 021 022 023 024 025 027 029 030 031 032 034 035 036 038 040 041 042 046 047 048 049 050 051 052 053 054 055 056 057 058 059 060 061 062 063 064 065"
