#!/bin/bash
mkdir -p /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/SA-median
cd /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/SA-median
~/gsoc_project_2022/models/biocro.Rscript /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/SA-median /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/SA-median
if [ $? -ne 0 ]; then
    echo ERROR IN MODEL RUN >&2
    exit 1
fi
cp  /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/SA-median/README.txt /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/SA-median/README.txt
