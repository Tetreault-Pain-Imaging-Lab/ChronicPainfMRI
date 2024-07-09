#!/bin/bash

# This would run fMRIprep with the following parameters:
#   - bids: clinical data from TPIL lab (27 CLBP and 25 control subjects);
#   - with-singularity: container image fMRIprep 23.2.0


# To monitor ressources usage on Narval and adjust ressource alloacation : https://portail.narval.calculquebec.ca/

# SLURM Parameters:
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

#SBATCH --job-name=fmriprep_all
#SBATCH --time=50:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=70G
#SBATCH --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/fmriprep_parallel/slurm-%x-%A_%a.out"


#SBATCH --mail-user=ludo.a.levesque@gmail.com
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=ALL

#SBATCH --array=0-2            # Array range based on number of visits

## Variables to set manually
my_fmriprep_img='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/fmriprep_23.2.3.sif' # or .img
my_input='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/complete_dataset_raw'
my_output='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-07-05_fmriprep_all/'
my_templateflow_path='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/templateflow'
fs_dir='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-07-09_freesurfer'  # Path to freesurfer output folder containing one subfolder for each visit
bids_filter_path='/home/ludoal/scratch/ChronicPainfMRI/bids_filters'
repos_path='/home/ludoal/scratch/ChronicPainfMRI'
visits=("v1" "v2" "v3")



# Determine the visit based on the array task ID
visit=${visits[$SLURM_ARRAY_TASK_ID]}

# Testing array jobs with different work dir per visits
my_work=$repos_path/fmriprep_work/$visit
if [ ! -d $my_work ]; then
    mkdir -p $my_work
fi

# Automatic variables
my_licence_fs="$repos_path/license.txt" # get your license by registering here : https://surfer.nmr.mgh.harvard.edu/registration.html

module load apptainer 

# https://neurostars.org/t/fmriprep-in-compute-canada/28474/6
export APPTAINERENV_TEMPLATEFLOW_HOME=$my_templateflow_path
export APPTAINERENV_FS_LICENSE=$my_licence_fs

# To check if the license is accesible to fmriprep use this line :
# apptainer exec --cleanenv -B /project:/project -B /scratch:/scratch $my_fmriprep_img env | grep FS_LICENSE


# Fetch participants for the specified visit
participants=""
if ! participants=$(bash "$repos_path/utils/get_subs_for_visit.sh" "$my_input" "$visit"); then # get_subs_for_visit returns a space seperated list of subject numbers)
    printf "Error fetching participants for visit %s\n" "$visit" >&2
    continue
fi

echo -e "Valid subjects for $visit are :\n$participants\n"  


# Fetch the right bids_filter file 
my_bids_filter="${repos_path}/bids_filters/fmriprep_bids_filter_${visit}.json"

##  Command
apptainer run --cleanenv \
    $my_fmriprep_img $my_input $my_output participant \
    --participant-label $participants \
    --output-spaces T1w MNI152NLin2009cSym \
    --cifti-output 91k \
    --bids-filter-file $my_bids_filter \
    --fs-subjects-dir "${fs_dir}/ses-${visit}" \
    -w $my_work 

