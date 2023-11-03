#!/bin/bash

# Download and extract team logs

# If team_logs.zip does not exist, download and extract it
if [ ! -d ../../data/logs/team_logs ]; then
    wget -L https://github.com/sauterl/VBS23-Post-Hoc-Analysis/releases/download/logs/team_logs.zip
    unzip team_logs.zip -d ../../data/logs
    rm team_logs.zip
fi

# Create a virtual environment and install requirements
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Install the kernel for jupyter notebooks
python -m ipykernel install --user --name vbs2023 --display-name "VBS2023"