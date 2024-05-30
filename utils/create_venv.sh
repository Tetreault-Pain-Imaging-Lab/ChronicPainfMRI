#!/bin/bash

module load python
ENVDIR='/home/ludoal/ENV/templateflow'
virtualenv --no-download $ENVDIR
source $ENVDIR/bin/activate
pip install --no-index --upgrade pip
export TEMPLATEFLOW_HOME='/home/ludoal/projects/def-pascalt-ab/ludoal/dev_tpil/tools/templateflow'
pip install -v -r requirements.txt
rm -rf $ENVDIR

ls $TEMPLATEFLOW_HOME