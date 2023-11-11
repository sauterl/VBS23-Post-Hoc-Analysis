#!/bin/bash

# Create a virtual environment and install requirements
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Install the kernel for jupyter notebooks
python -m ipykernel install --user --name vbs2023 --display-name "VBS2023"