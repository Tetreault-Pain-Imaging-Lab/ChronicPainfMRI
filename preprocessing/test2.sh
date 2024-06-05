#!/bin/bash

#SBATCH --job-name=test
#SBATCH --time=0:10:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2K
#SBATCH --output="/home/ludoal/scratch/ChronicPainfMRI/outputs/tests/slurm-%A.out"


touch "test/${SLURM_ARRAY_TASK_ID}.txt"
