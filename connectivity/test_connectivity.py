import os

# Set the NILEARN_DATA environment variable to the desired path
cahe_path='/home/ludoal/scratch/cache'
os.environ['NILEARN_DATA'] = cahe_path
os.environ['NILEARN_CACHE'] = cahe_path

import numpy as np
from nilearn import datasets, plotting
from nilearn.connectome import ConnectivityMeasure
from nilearn.maskers import NiftiMapsMasker
from nilearn import plotting

# Load a BOLD file
bold_file = '/home/ludoal/scratch/tpil_data/BIDS_longitudinal/2024-06-28_fmriprep/results/sub-002/ses-v1/func/sub-002_ses-v1_task-rest_space-MNI152NLin2009cSym_desc-preproc_bold_denoised.nii.gz'

print("Loading the probabilistic atlas...")
# Load a probabilistic atlas

atlas = datasets.fetch_atlas_msdl()
# Loading atlas image stored in 'maps'
atlas_filename = atlas["maps"]
# Loading atlas data stored in 'labels'
labels = atlas["labels"]

print("Atlas loaded.")

print("Extracting time series from the BOLD file...")
# Extract time series from the BOLD file using the atlas
masker = NiftiMapsMasker(
    maps_img=atlas_filename,
    standardize="zscore_sample",
    standardize_confounds="zscore_sample",
    memory="nilearn_cache",
    verbose=5,
)
time_series = masker.fit_transform(bold_file)
print("Time series extracted.")

print("Generating connectivity matrix...")
# Generate a connectivity matrix
connectivity_measure = ConnectivityMeasure(
    kind="correlation",
    standardize="zscore_sample",
)
connectivity_matrix  = connectivity_measure.fit_transform([time_series])[0]

# Mask out the major diagonal
np.fill_diagonal(connectivity_matrix, 0)
plotting.plot_matrix(
    connectivity_matrix, labels=labels, colorbar=True, vmax=0.8, vmin=-0.8, output_file='connectivity_matrix_plot.png'
)

print("Connectivity matrix generated.")

# print("Finding node coordinates...")
# # Get node coordinates
# node_coords = atlas.region_coords
# print("Node coordinates found.")

# print("Creating interactive connectivity visualization...")
# # Create an interactive connectivity visualization
# view = plotting.view_connectome(connectivity_matrix , node_coords=node_coords, edge_threshold="80%")
# view.save_as_html('connectome_visualization.html')
# print("Visualization saved as connectome_visualization.html")
