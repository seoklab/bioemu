#!/bin/bash

set -euxo pipefail

# Check if conda environment is activated
if [ -z "$CONDA_DEFAULT_ENV" ]; then
    echo "Error: No Conda environment is currently activated."
    exit 1  # Exit with error code
fi

# Get the name of the current conda environment
current_env="$CONDA_DEFAULT_ENV"

# Check if the environment is "bioemu"
if [ "$current_env" != "bioemu" ]; then
    echo "Error: You are not in the 'bioemu' environment. Current environment is '$current_env'."
    exit 1  # Exit with error code
else
    echo "You are in the 'bioemu' environment."
fi

type wget 2>/dev/null || { echo "wget is not installed. Please install it using apt or yum." ; exit 1 ; }

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Set COLABFOLD_DIR to ~/.localcolabfold if dir not passed as first arg
COLABFOLD_DIR="${1:-"~/.localcolabfold"}"

echo "Setting up colabfold..."
mkdir -p ${COLABFOLD_DIR}
cd ${COLABFOLD_DIR}

# from install_colabbatch_linux.sh
#---------------
CURRENTPATH=`pwd`
COLABFOLDDIR="${CURRENTPATH}/localcolabfold"
mkdir "${COLABFOLDDIR}"

# source "${COLABFOLDDIR}/conda/etc/profile.d/conda.sh"
conda activate bioemu

# install ColabFold and Jaxlib
pip install --no-warn-conflicts \
    "colabfold[alphafold] @ git+https://github.com/seoklab/ColabFold@0d2bd511005000045a5d16e418a4d38d4eb4154c"
# "$COLABFOLDDIR/colabfold-conda/bin/pip" install --upgrade tensorflow

# # Download the updater
# chmod +x update_linux.sh
# cp update_linux.sh "${COLABFOLDDIR}"

pushd "${CONDA_PREFIX}/lib/python3.10/site-packages/colabfold"
# Use 'Agg' for non-GUI backend
sed -i -e "s#from matplotlib import pyplot as plt#import matplotlib\nmatplotlib.use('Agg')\nimport matplotlib.pyplot as plt#g" plot.py
# suppress warnings related to tensorflow
sed -i -e "s#from io import StringIO#from io import StringIO\nfrom silence_tensorflow import silence_tensorflow\nsilence_tensorflow()#g" batch.py
# remove cache directory
rm -rf __pycache__
popd

# # Download weights, run with sudo if required
# "${CONDA_PREFIX}/bin/python3" -m colabfold.download
# echo "Download of alphafold2 weights finished."
# echo "-----------------------------------------"
# echo "Installation of ColabFold finished."
# echo "Add ${COLABFOLDDIR}/colabfold-conda/bin to your PATH environment variable to run 'colabfold_batch'."
# echo -e "i.e. for Bash:\n\texport PATH=\"${COLABFOLDDIR}/colabfold-conda/bin:\$PATH\""
# echo "For more details, please run 'colabfold_batch --help'."
# #---------------


# Patch colabfold install
echo "Patching colabfold installation..."
patch ${CONDA_PREFIX}/lib/python3.10/site-packages/alphafold/model/modules.py ${SCRIPT_DIR}/modules.patch
patch ${CONDA_PREFIX}/lib/python3.10/site-packages/colabfold/batch.py ${SCRIPT_DIR}/batch.patch

echo "Colabfold installation complete!"