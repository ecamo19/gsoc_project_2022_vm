#!/bin/bash
mkdir -p /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/ENS-00028-753
cd /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/ENS-00028-753
~/gsoc_project_2022/models/biocro.Rscript /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/ENS-00028-753 /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/ENS-00028-753
if [ $? -ne 0 ]; then
    echo ERROR IN MODEL RUN >&2
    exit 1
fi
cp  /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/ENS-00028-753/README.txt /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/ENS-00028-753/README.txt
