# KIS Log Analysis - VBS 2023
This repo provides a good code base for extracting and analyzing the logs from the different teams that participated to [VBS 2023](https://videobrowsershowdown.org/).

Hopefully, this repo will help to analyze also the logs from the future versions of VBS.

## Data Preparation
First of all, run the following command. This will prepare the python virtual environment.
```
cd src/python
./prepare.sh
source venv/bin/activate
```

## Run the notebooks
Move into `src/python` path (if not already there), and run the following:
```
jupyter notebook
```

Then, select the kernel named `VBS2023` before running any notebook.

**NOTE**: for correctly running the notebooks, be sure your jupyter notebook is rooted in `src/python`, otherwise you will encounter some issues.

## Generating CSVs from raw logs
The processed csv files are already inside the `data/processed/kis-logs` directory. However, there may be the case in which you need to recompute them from the raw files.

In such a case, you have to run the following:
```
./process_logs.sh
```

This script will extract log data from 2023 teams and will process them putting the resulting CSVs in `data/processed/kis-logs` directory.

Notice that some raw data are collected from the local logs of the systems, others from the public [run file](https://github.com/lucaro/VBS-Archive/tree/main/2023) of the [DRES](https://github.com/dres-dev/DRES) server.

## Contributors

Lucia Vadicamo - [lucia.vadicamo@isti.cnr.it](mailto:lucia.vadicamo@isti.cnr.it)

Nicola Messina - [nicola.messina@isti.cnr.it](mailto:nicola.messina@isti.cnr.it)

Ladislav Peška - [ladislav.peska@matfyz.cuni.cz](mailto:Ladislav.Peska@matfyz.cuni.cz)
