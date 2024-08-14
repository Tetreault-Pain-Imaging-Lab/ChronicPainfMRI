# BIDS Filter

This folder contains `fmripreps_bids_filter.json` files, which are used by [fMRIPrep](https://fmriprep.org) to specify and process only certain files from your dataset.
The `fmripreps_bids_filter.json` files allow you to define criteria to filter your BIDS-compliant dataset. This is particularly useful when you want to focus on specific sessions, tasks, or data types without processing the entire dataset.
Here, we want to run fmriprep one session at a time because we don't have the same amount of subjects every session which caused a crash. We use a different bids filter file for every visit. 
The files present in this folder are specific to our analysis. To run the fmriprep on new data, you should create your own bids filters but keep the same name structure : 

`fmripreps_bids_filter_{SESSION TAG}.json` for longitudinal data

`fmripreps_bids_filter.json` for cross-sectionnal data


## Example of a BIDS Filter File

Below is an example of a `fmripreps_bids_filter_{SESSION TAG}.json` file:

```json
{
    "fmap": {"datatype": "fmap", "session": "v1", "acquisition": "rest", "direction": "AP", "suffix": "epi"},
    "bold": {"datatype": "func", "session": "v1", "task": "rest", "suffix": "bold"},
    "t1w": {"datatype": "anat", "session": "v1", "suffix": "T1w"}
}

```

## How to Create a BIDS Filter File

see [here](https://fmriprep.org/en/latest/faq.html#how-do-i-select-only-certain-files-to-be-input-to-fmriprep) for more information about bids_filters for fmriprep

1. Identify the Criteria:
    - Determine the specific data you want to include in your fMRIPrep processing.
    - Criteria can include datatype (e.g., func, anat, fmap), session (e.g., v1), task (e.g., rest), acquisition parameters (e.g., direction: AP), and suffixes (e.g., bold, T1w, epi).

2. Structure the JSON File:
    - Use a JSON editor or a plain text editor to create your file.
    - Follow the structure shown in the example above, including key-value pairs for each criterion. Each key (e.g., "fmap", "bold", "t1w") should correspond to a section of your dataset.
      
3. Save the File:
    - Save your file with the name fmripreps_bids_filter.json.
    - Place the file in the bids_filter folder of your version of the repository.
