# Preprocessing

When processing longitudinal data, we need to run a different instance of fmriprep on each visit and we need to run freesurfer seperately befohand. The first script to run is `run_freesurfer_cc.sh`, then you can lauch `run_fmriprep_cc.sh`.

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


<details><summary><b>Resources</b></summary>

- [recon-all wiki](https://surfer.nmr.mgh.harvard.edu/fswiki/recon-all)
- [Freesurfer docker image](https://hub.docker.com/r/freesurfer/freesurfer)

</details>

<details><summary><b>Example command</b></summary>
  
```bash
bash /home/ludoal/scratch/ChronicPainfMRI/preprocessing/run_freesurfer_cc.sh 
```
</details>



## Fmriprep

<details><summary><b>Resources</b></summary>

</details>

<details><summary><b>Example command</b></summary>

```bash 
sbatch /home/ludoal/scratch/ChronicPainfMRI/preprocessing/run_fmriprep_cc.sh
```

</details>


