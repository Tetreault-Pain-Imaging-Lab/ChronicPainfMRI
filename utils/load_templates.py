# -*- coding: utf-8 -*-

# Called to download the complete templates needed for fmriprep


import templateflow.api as tflow

tflow.TF_S3_ROOT = 'http://templateflow.s3.amazonaws.com'

# To use different templates in fmriprep, add them here
tflow.get('MNI152NLin6Asym')
tflow.get('fsLR')
tflow.get('OASIS30ANTs')


          