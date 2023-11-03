#!/bin/bash

source venv/bin/activate

# Process local raw logs provided by the various teams, except vitrivr-vr and CVHunter, which provided their own csv files
python preprocess.py --config config_vbs2023.yaml

# Convert vitrivr_vr
python scripts/vbs2023/vitrivr_vr_to_pandas.py \
   --input_file ../../data/logs/team_logs/vitrivr-vr/result_log_ranks_vitrivr_vr.csv \
   --output_path ../../data/processed/kis-logs \
   --config config_vbs2023.yaml

# Convert CVHunter
python scripts/vbs2023/cvhunter_to_pandas.py \
   --input_files ../../data/logs/team_logs/CVHunter/CVHunter_filtered_data.csv ../../data/logs/team_logs/CVHunter/CVHunter_filtered_data_marine.csv \
   --output_path ../../data/processed/kis-logs \
   --config config_vbs2023.yaml