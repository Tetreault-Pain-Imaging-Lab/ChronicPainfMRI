# TPIL fMRI study on Chronic lower back pain


## Dataset
...
See [here](https://github.com/Tetreault-Pain-Imaging-Lab/dataset_LongitudinalNoTreatement) for more information on the dataset's acquisition, outliers and BIDS formatting.

## How to use this repository

In order to use `run_fmriprep_cc.sh`, you need :

1. Freesurfer results ...
2. A freesurfer license.txt file
3. TemplateFlow installed with MNI152NLin2009cSym and fslr downloaded ...
4. Bids filter files (see bids_filter folder)
   


### Templateflow
locally ?
To install templateflow we recommend using datalad. To install datalad on a linux or a WSL plateform you can use this command :
```
sudo apt-get install datalad
``` 
Once you have datalad installed, you can install templateflow in the current directory using this command :
```
datalad install -r ///templateflow
```
This will not download 
