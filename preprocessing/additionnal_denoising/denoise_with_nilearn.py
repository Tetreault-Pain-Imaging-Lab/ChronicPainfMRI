# -*- coding: utf-8 -*-
"""
Created on Thu Aug 17 10:30:21 2023

@author: ludoa
"""

"""
BOLD Data Cleaning Script

This script processes BOLD data using a specified denoising strategy
and brain mask. It uses the Nilearn library for masking and denoising operations.

Usage:
    python bold_data_cleaning.py <bold_file> <denoise_strategy> <brain_mask_file>

Arguments:
    bold_files (str): Path to the BOLD file to be cleaned. can be a list of files
    denoise_strategy (str): Denoising strategy to be used (e.g., 'simple', 'comp_cor').
    brain_mask_files (str): Path to the brain mask file in Nifti format. If bold_files is a list, this needs to be a list too
    output_files (str): Complete path for the denoised file

Example:
    python bold_data_cleaning.py sub-02_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz simple sub-02_task-rest_space-MNI152NLin6Asym_desc-brain_mask.nii.gz
"""

import os
import argparse
import nibabel as nib
from nilearn.maskers import NiftiMasker
from nilearn.interfaces.fmriprep import load_confounds_strategy


def clean_bold_with_confounds(bold_file_paths, denoise_strat, brain_mask_files, output_file):
    # Load the confounds based on the chosen denoising strategy
    confounds, _ = load_confounds_strategy(img_files=bold_file_paths, denoise_strategy=denoise_strat)

    if type(bold_file_paths) != list:
        bold_file_paths = [bold_file_paths]
        confounds = [confounds]
        brain_mask_files = [brain_mask_files]

    for index, bold_file in enumerate(bold_file_paths):
        bold_img = nib.load(bold_file)
        # Extract TR from the header of the BOLD file
        TR = bold_img.header['pixdim'][4]

        # Create a NiftiMasker object for time series extraction
        brain_masker = NiftiMasker(
            mask_img=brain_mask_files[index],
            detrend=True,
            standardize="zscore_sample",
            low_pass=0.4,
            high_pass=0.009,
            smoothing_fwhm=5,
            t_r=TR,
            memory="nilearn_cache",
            memory_level=1,
            verbose=0)

        # Extract and denoise time series
        time_series = brain_masker.fit_transform(bold_img, confounds=confounds[index])

        # Save the denoised nifti
        nii_img = brain_masker.inverse_transform(time_series)
        nii_affine = bold_img.affine
        nii_header = bold_img.header
        nii_img = nib.Nifti1Image(nii_img.get_fdata(), affine=nii_affine, header=nii_header)
        # print(nii_img.header['pixdim'])
        nib.save(nii_img, output_file)


def main():
    
    # Create an argument parser instance
    parser = argparse.ArgumentParser(description="Clean BOLD data with confounds")

    # Define command-line arguments and their types
    parser.add_argument("bold_files", type=str, help="Path to the BOLD files to clean")
    parser.add_argument("denoise_strategy", type=str, help="Denoising strategy to use")
    parser.add_argument("brain_mask_files", type=str, help="Path to the brain mask file")
    parser.add_argument("output_files", type=str, help="Complete path with filename of the denoised file")
    # Parse the provided command-line arguments
    args = parser.parse_args()

    # Call the cleaning function with parsed arguments
    clean_bold_with_confounds(args.bold_files, args.denoise_strategy, args.brain_mask_files, args.output_files)


if __name__ == "__main__":
    main()