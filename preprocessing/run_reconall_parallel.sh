#!/bin/bash

#SBATCH --job-name=reconall_parallel
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=10G
#SBATCH --mail-user=ludo.a.levesque@gmail.com
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE,ALL
#SBATCH --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/recon-all/slurm-%A.out"

# Directories
BIDS_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test"          # Replace with your BIDS dataset directory
OUTPUT_DIR="/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-11_freesurfer"   # Replace with your desired FreeSurfer output directory
SINGULARITY_IMG="/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/containers/freesurfer_7.2.0.sif" # Replace with the path to your FreeSurfer Singularity image
LICENSE_FILE="/home/ludoal/scratch/ChronicPainfMRI/license.txt"       # Replace with the path to your FreeSurfer license file
REPOS_PATH='/home/ludoal/scratch/ChronicPainfMRI'


# Loop through subjects and sessions
for subj in $BIDS_DIR/sub-*; do
    subj_id=$(basename $subj)

    for sess in $subj/ses-*; do
        sess_id=$(basename $sess)
        t1_file=$sess/anat/${subj_id}_${sess_id}_T1w.nii.gz

        if [ -f $t1_file ]; then
            echo "Processing $subj_id $sess_id"

            sbatch --job-name=recon-all-${subj_id}_${sess_id} \
                --output="$REPOS_PATH/outputs/recon-all/slurm-%A_%x.out" \
            $REPOS_PATH/preprocessing/reconall_single.sh \
                --BIDS_dir $BIDS_DIR \
                --output_dir $OUTPUT_DIR \
                --singularity_img $SINGULARITY_IMG \
                --license_file $LICENSE_FILE \
                --subj_id $subj_id \
                --sess_id $sess_id \
                --t1_file $t1_file
            
            sleep 1m
        else
            echo "T1 file not found for $subj_id $sess_id"
        fi
    done
done
