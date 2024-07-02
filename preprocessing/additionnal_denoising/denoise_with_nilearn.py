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
    python denoise_with_nilearn.py --input <bold_file> --strategy <denoise_strategy> --mask <brain_mask_file> --output <output_file>

Arguments:
    input (str): Path to the BOLD file to be cleaned.
    strategy (str): Denoising strategy to be used (e.g., 'simple', 'comp_cor').
    mask (str): Path to the brain mask file in Nifti format.
    output (str): Complete path for the denoised file.

Example:
    python denoise_with_nilearn.py --input sub-02_task-rest_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz --strategy simple --mask sub-02_task-rest_space-MNI152NLin6Asym_desc-brain_mask.nii.gz --output sub-02_task-rest_denoised_bold.nii.gz
"""

import os
import argparse
import nibabel as nib
from nilearn.maskers import NiftiMasker
from nilearn.interfaces.fmriprep import load_confounds_strategy
import logging

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def validate_file(file_path, file_type):
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"{file_type} file not found: {file_path}")

def clean_bold_with_confounds(bold_file_path, denoise_strat, brain_mask_file, output_file):
    try:
        # Validate input files
        validate_file(bold_file_path, "BOLD")
        validate_file(brain_mask_file, "Brain mask")

        # Load the confounds based on the chosen denoising strategy
        confounds, _ = load_confounds_strategy(img_files=[bold_file_path], denoise_strategy=denoise_strat)

        bold_img = nib.load(bold_file_path)
        # Extract TR from the header of the BOLD file
        TR = bold_img.header['pixdim'][4]

        # Create a NiftiMasker object for time series extraction
        brain_masker = NiftiMasker(
            mask_img=brain_mask_file,
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
        time_series = brain_masker.fit_transform(bold_img, confounds=confounds)

        # Save the denoised nifti
        nii_img = brain_masker.inverse_transform(time_series)
        nii_affine = bold_img.affine
        nii_header = bold_img.header
        nii_img = nib.Nifti1Image(nii_img.get_fdata(), affine=nii_affine, header=nii_header)
        nib.save(nii_img, output_file)
        logging.info(f"Denoised file saved: {output_file}")

    except Exception as e:
        logging.error(f"An error occurred: {e}")

def main():
    # Setup logging
    setup_logging()
    
    # Create an argument parser instance
    parser = argparse.ArgumentParser(description="Clean BOLD data with confounds")

    # Define command-line arguments and their types
    parser.add_argument('--input', type=str, required=True, help='Path to the input BOLD file.')
    parser.add_argument('--mask', type=str, required=True, help='Path to the brain mask file.')
    parser.add_argument('--output', type=str, required=True, help='Complete path with filename of the denoised file.')
    parser.add_argument('--strategy', type=str, default='simple', help='Denoising strategy to use.')
    
    # Parse the provided command-line arguments
    args = parser.parse_args()

    # Call the cleaning function with parsed arguments
    clean_bold_with_confounds(args.input, args.strategy, args.mask, args.output)


if __name__ == "__main__":
    main()
