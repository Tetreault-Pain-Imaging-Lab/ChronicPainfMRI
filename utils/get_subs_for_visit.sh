#!/bin/bash

# This scripts looks into the data_path and for missing subject files (outliers)
# for a given session and returns a .txt file containing a space seperated list 
# of participant labels to use as the --participant-label argument in fmriprep. 
# All pariticipants that are missing the BOLD or T1 files necessary are not added to the list to prevent fmriprep from crashing. 

# Usage :
#     example : bash utils/get_subs_for_visit.sh '/home/ludoal/scratch/tpil_data/BIDS_longitudinal/data_raw_for_test' v1 

data_path="$1"
ses="$2"
sub_num=""

for sub_folder in "$data_path"/sub* ; do
    subID=$(basename $sub_folder)
    sub_num=$(echo "$subID" | cut -d '-' -f 2)

    search_folder="$sub_folder/ses-$ses"

    # Check for func, anat and fmap folder
    if [ -d "$search_folder/func" ] ||  [ -d "$search_folder/anat" ] || [ -d "$search_folder/fmap" ]; then
        sub_nums="$sub_nums $sub_num"
    fi


done

    # Printing all valid subject numbers to file 
    echo $sub_nums 
  
