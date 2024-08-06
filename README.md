# 
#  <img src="assets/logo.png" alt="logo" width="50"/>   ChronicPainfMRI  
**ChronicPainfMRI** is a repository that aims to facilitate the reproduction of the fMRI processing and analysis we did in our lab, on different datasets. It contains code to easily run the same pipelines we normally use and with the same options. One of the strong points of this repository is that it allows to easily run fmriprep on longitudinal data.

The dataset we originally used to develop this repository includes 27 chronic low back pain patients and 25 controls scanned at three timepoints (0, 2, and 4 months) between April 2021 and July 2022. For detailed dataset and acquisition information, refer to our [dataset documentation](https://github.com/Tetreault-Pain-Imaging-Lab/dataset_LongitudinalNoTreatement).



## Repository Usage             

<img src="assets/diag_setup.png" alt="diagram1" width="500"/>   
   
### Forking the Repository for personal use
If you would like to use and customize this repository for your own purposes, we recommend forking it. Forking allows you to have your own version of this project that you can modify and maintain independently of the original codebase. Here’s how you can fork this repository:

Create a Fork: Simply click the “Fork” button at the top-right corner of this repository's GitHub page. This action will create a copy of this repository in your own GitHub account.

Clone Your Fork: After forking, clone the forked repository to your local machine to make your changes. You can do this by running:

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY
```

You could also simply clone this repository on your Compute Canada account and start using it directly, which is fine if you want to customize it but you don't want multiple versions of this repository

### Running on Compute Canada

To use this repository on Compute Canada, here's some helpful guidance:
- **Data Management**: Place your data in the scratch directory, run scripts there, and transfer results elsewhere only after processing.
    (When moving results folder be carefull of symlinks. For example, the results folder of tractoflow contains symlinks that points to files in the work folder. To copy        and paste results from one directory to another you can use the rsync command.)
  
    Copy and paste results (replacing symlinks with actual files):
    ```bash
    rsync -rL user@graham.alliancecan.ca:/home/user/scratch/data/2024-05-27_tractoflow/results /home/user/projects/tpil_data/2024-05-27_tractoflow/
    ```
    Preserving symlinks (the links must point to accessible files)
    ```bash
    rsync -rl user@graham.alliancecan.ca:/home/user/scratch/data/2024-05-27_tractoflow/results /home/user/scratch/data/2024-05-27_tractoflow/
    ```

- **Tool Installation**: Install tools like `tractoflow` and the `scilus` container in a persistent directory (e.g., *projects* directory). Use the `install_tools_cc.sh` to install them in one step.

- **Ressources allocation**:When submitting jobs on a cluster, you have to allocate ressources trough the SLURMS parameters. To monitor jobs and see what ressources it uses, Narval and Beluga have a portal that helps you visualise ressources usage for tasks :[Narval](https://portail.narval.calculquebec.ca), [Beluga](https://portail.beluga.calculquebec.ca).
Portals for the other clusters might be available now.

         ### SLURM Parameters Info
         
         - **--nodes**: Number of nodes to allocate. Generally depends on the number of subjects and available cores per task.  
           If you have more subjects than cores (e.g., 38 subjects and 32 cpus-per-task), consider requesting an additional node.
         
         - **--cpus-per-task**: Number of CPUs to allocate per task. Choose based on your cluster's available configurations.  
           For example, Beluga allows 32, 40, or 64 CPUs per task.  
           More information: [Beluga Node Characteristics](https://docs.computecanada.ca/wiki/B%C3%A9luga/en#Node_Characteristics)
         
         - **--mem**: Memory allocation per node. Setting this to 0 allocates all available memory on the node.  
           Adjust based on expected memory usage.
         
         - **--time**: Maximum job runtime. Adjust based on your pipeline's expected duration.
         
         - **--mail-user**: Email address for job notifications.
         
         - **--mail-type**: Conditions under which to send job status emails (BEGIN, END, FAIL, REQUEUE, ALL).
         
         - **--output**: Path to the output log file for the SLURM job. `%A` is the job ID.

     For more info on how to run jobs on Compute Canada see their [wiki page](https://docs.alliancecan.ca/wiki/Running_jobs)


## Config file
To run the anlysis on a new dataset, you need to create your config file. In this file you will set all the variables that the pipelines need to run on a new dataset. Use the `config_ex.sh` file as a template. Here is all the variables you need to set in this file :

| **Variable**           | **Description**                                                                                                                               |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `REPOS_DIR`            | Path where the ChronicPainDWI repository is installed/cloned on your Compute Canada account.                                                  |
| `TOOLS_PATH`           | Directory containing tools like the sclilus lab container and nextflow tools. Recommended to place in `/user/projects` to prevent purging.   |
| `BIDS_DIR`             | Path to the raw BIDS formatted dataset. Contains subject folders and essential files like `participants.tsv`, `participants.json`, and `dataset_description.json`. |
| `OUTPUT_DIR`           | Directory where results are stored, organized by the pipeline that generated them. (i.e. tractoflow outputs will be placed in `$OUTPUT_DIR/tractoflow`)                                                         |
| `MAIL`                 | Email address for job notifications. Optional; remove `#SBATCH --mail` lines if not needed.                                                  |
| `SLURM_OUT`            | Path for storing SLURM job output logs.                                                                                                       |
| `tractoflow_ressources`| SLURM parameters for the `run_tractoflow_cc.sh` script, including job name, time, nodes, CPUs per task, memory, output log path, and email notifications. |
| `rbx_ressources`       | SLURM parameters for the `run_rbx_cc.sh` script, including job name, time, nodes, CPUs per task, memory, output log path, and email notifications. |
| `tractometry_ressources`| SLURM parameters for the `run_tractometry_cc.sh` script, including job name, time, nodes, CPUs per task, memory, output log path, and email notifications. |
| `nb_points`            | (optional) Number of points used in `run_tractometry_cc.sh`. If this variables is empty, 20 points will be used by default                     |
| `QC_ressources`        | SLURM parameters for the `run_dmriqc_cc.sh` script, including nodes, CPUs per task, memory, time, and output log path.                            |


Creating multiple config file with evocative names can allow you to quickly switch between two dataset or two configurations of your data without changing anything in the other scripts. After creating this file you can run any other script of this repository this way:

```bash
bash some_script_path your_config_file_path
```
If you only use one config file you can name it `config_ex.sh`, since it is the file that will be used as default if no config file is specified as argument when calling a script. Or you could change the `DEFAULT_CONFIG_FILE="config_ex.sh" ` line in all the scripts to use your config file by default.

## Analysis Workflow

<img src="assets/diag_analysis.png" alt="diagram2" width="500"/>   

### Preprocessing and tractogram generation

In the [tractoflow](https://github.com/Tetreault-Pain-Imaging-Lab/ChronicPainDWI/tree/main/preprocessing) folder you will find scripts and information to run the first steps of the analysis. The main tool used for this part is [TractoFlow](https://tractoflow-documentation.readthedocs.io/en/latest/index.html) which does the preprocessing of the DWI files and generates tractograms.


### Bundle segmentation 

The second step is bundle segmentation. In the [bundleseg](https://github.com/Tetreault-Pain-Imaging-Lab/ChronicPainDWI/tree/main/bundleseg) folder are scripts and information for the segmentation of the bundles computed using TractoFlow. The main tool used for this part is  the [RecobundlesX pipeline](https://github.com/scilus/rbx_flow) 


### Tractometry 

The third step is tractometry which is done using another scilus lab tool : [tractometry_flow](https://github.com/scilus/tractometry_flow) We encontered an issue with tractometry_flow that might be fixed eventually, but be aware that some bundles might have too few streamlines and this can lead to the pipeline crashing. To resolve this you can remove the bundles that cause the issue from your data.




