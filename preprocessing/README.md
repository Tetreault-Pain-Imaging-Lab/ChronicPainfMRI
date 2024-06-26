# Preprocessing

The preprocessing of our data was done with [fmriprep](https://fmriprep.org/en/stable/), but in order to speed up the pipeline, we precomputed Freesurfer outputs that fmriprep uses. So the first step in our analysis was to run Freesurfer's recon-all on the BIDS formatted raw data. Then we ran fmriprep on the same BIDS raw dataset. An important thing to keep in mind is that since this is a longitudinal study, we want to run a different instance of fmriprep for different sessions, otherwise fmriprep will compute averages over sessions for some outputs. 
This means that that the output directory (subjects_dir) of recon-all needs to be different for every session. 

Here is the structure of our BIDS dataset :
```
                   [root]
                   ├── dataset_description.json
                   ├── participants.json
                   ├── sub-001
                   │   ├── ses-v1
                   │   |   └── ...
                   │   ├── ses-v2
                   │   |   └── ...
                   │   └── ses-v3
                   │   |   └── ...
                   ├── sub-002
                   │   └── ...

```

And here is the desired structure of freesurfer outputs:

```
                    [Freesurfer]
                    ├── ses-v1
                    │   ├── sub-001
                    │   │   ├── label
                    │   │   ├── mri
                    │   │   ├── scripts
                    │   │   ├── stats
                    │   │   ├── surf
                    │   │   ├── tmp
                    │   │   ├── touch
                    │   │   └── trash
                    │   ├── sub-002
                    │   └── ...

    
```

## Freesurfer recon-all
It is possible to run recon-all using cbrain, or you can use the scripts `submit_reconall_array.sh` that runs recon-all on every subject-sesion pair in parallel on a compute canada cluster. If using cbrain, make sure you respect the mentionned output structure. To use recon-all on compute canada, we used a combination of 2 scripts; `run_reconall_array.sh` runs reconall on one subject-session pair and `submit_reconall_array.sh` submits an array job that runs `run_reconall_array.sh` for every subject-session pair so that thewhole dataset can be processed in parallel. You might need to personalize both scripts to run with new data. Most of the changes will be in the first lines of `submit_reconall_array.sh` where paths are set. 

<details><summary><b>Resources</b></summary>

- [recon-all wiki](https://surfer.nmr.mgh.harvard.edu/fswiki/recon-all)
- [Freesurfer docker image](https://hub.docker.com/r/freesurfer/freesurfer)

</details>

<details><summary><b>Example command</b></summary>
```
bash /home/ludoal/scratch/ChronicPainfMRI/preprocessing/submit_reconall_array.sh 
```
</details>


<details><summary><b>Outputs</b></summary>

</details>

## Fmriprep


<details><summary><b>Resources</b></summary>

</details>

<details><summary><b>Example command</b></summary>
  
</details>


<details><summary><b>Outputs</b></summary>

</details>

