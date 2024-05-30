#!/bin/bash

# This would run fMRIprep with the following parameters:
#   - bids: clinical data from TPIL lab (27 CLBP and 25 control subjects);
#   - with-singularity: container image fMRIprep 23.2.0


#SBATCH --job-name=fmriprep
#SBATCH --time=30:00:00
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


my_fmriprep_img='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_scil/containers/fmriprep_23.2.3.sif' # or .img
my_input='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test'
my_output='/home/ludoal/scratch/tpil_data/BIDS_longitudinal/fmriprep/results'
my_work="${my_output}/work"
my_templateflow_path='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/templateflow'
fs_dir='/home/pabaua/projects/def-pascalt-ab/pabaua/dev_tpil/data/freesurfer_v1'
bids_filter='/home/pabaua/projects/def-pascalt-ab/pabaua/dev_tpil/tpil_dmri/script_local/fmriprep_bids_filter_v1.json'

my_licence_fs='/home/ludoal/scratch/ChronicPainfMRI/license.txt'

# v1  remove 004 and 035
my_participants='002 006 007 008'

## Create a virtual environment to install Templateflow
module load StdEnv/2020 apptainer/1.1.8 python
virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip
export TEMPLATEFLOW_HOME=$my_templateflow_path
if [ ! -d $my_templateflow_path ]; then 
    mkdir -p $my_templateflow_path
fi

pip install -r -v requirements.txt
python /home/ludoal/scratch/ChronicPainfMRI/utils/load_templates.py #downloads the templates used in fmriprep

# https://neurostars.org/t/fmriprep-in-compute-canada/28474/6
export APPTAINERENV_TEMPLATEFLOW_HOME=$my_templateflow_path
export APPTAINERENV_FS_LICENSE=$my_licence_fs
apptainer exec --cleanenv -B /project:/project -B /scratch:/scratch $my_fmriprep_img env | grep FS_LICENSE

# apptainer run --cleanenv \
#     -B /project:/project -B /scratch:/scratch \
#     $my_fmriprep_img $my_input $my_output participant \
#     --participant-label $my_participants \
#     -w $my_work \
#     --output-spaces T1w MNI152NLin2009cSym \
#     --cifti-output 91k \
#     --bids-filter-file $bids_filter \
#     --fs-subjects-dir $fs_dir

# #done