#!/bin/bash

# This would run fMRIprep with the following parameters:
#   - bids: clinical data from TPIL lab (27 CLBP and 25 control subjects);
#   - with-singularity: container image fMRIprep 23.2.0


#SBATCH --job-name=fmriprep
#SBATCH --time=5:00:00
#SBATCH --nodes=1              # --> Generally depends on your nb of subjects.
                               # See the comment for the cpus-per-task. One general rule could be
                               # that if you have more subjects than cores/cpus (ex, if you process 38
                               # subjects on 32 cpus-per-task), you could ask for one more node.
#SBATCH --cpus-per-task=32     # --> You can see here the choices. For beluga, you can choose 32, 40 or 64.
                               # https://docs.computecanada.ca/wiki/B%C3%A9luga/en#Node_Characteristics
#SBATCH --mem=0                # --> 0 means you take all the memory of the node. If you think you will need
                               # all the node, you can keep 0.


#SBATCH --mail-user=ludo.a.levesque@gmail.com
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=ALL
#SBATCH --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/fmriprep/slurm-%A.out"

## Variables to set manually
my_fmriprep_img='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/fmriprep_23.2.3.sif' # or .img
my_input='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test'
my_output='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/fmriprep/results'
my_work="${my_output}/work"
my_templateflow_path='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/templateflow'
fs_dir='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/freesurfer_v1'
bids_filter='/home/ludoal/scratch/ChronicPainfMRI/preprocessing/fmriprep_bids_filter_v1.json'
# get your license by registering here : https://surfer.nmr.mgh.harvard.edu/registration.html
my_licence_fs='/home/ludoal/scratch/ChronicPainfMRI/license.txt'

# # v1  remove 004 and 035
# my_participants='002 006 007 008'


module load apptainer 

# https://neurostars.org/t/fmriprep-in-compute-canada/28474/6
export APPTAINERENV_TEMPLATEFLOW_HOME=$my_templateflow_path
export APPTAINERENV_FS_LICENSE=$my_licence_fs
apptainer exec --cleanenv -B /project:/project -B /scratch:/scratch $my_fmriprep_img env | grep FS_LICENSE

## Valid subjects
utils_path="$(dirname "$(realpath "$0")")"
my_participants=$(bash $utils_path/get_subs_for_visit.sh $my_input v1)


##  Command
apptainer run --cleanenv \
    # -B /project:/project -B /scratch:/scratch \ # may not be necessary 
    $my_fmriprep_img $my_input $my_output participant \
    --participant-label $my_participants \
    -w $my_work \
    --output-spaces T1w MNI152NLin2009cSym \
    --cifti-output 91k \
    --bids-filter-file $bids_filter \
    --fs-subjects-dir $fs_dir
