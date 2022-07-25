#!/bin/bash
mkdir -p /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/SA-salix-leaf_respiration_rate_m2-0.159
cd /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/SA-salix-leaf_respiration_rate_m2-0.159
~/gsoc_project_2022/models/biocro.Rscript /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/SA-salix-leaf_respiration_rate_m2-0.159 /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/SA-salix-leaf_respiration_rate_m2-0.159
if [ $? -ne 0 ]; then
    echo ERROR IN MODEL RUN >&2
    exit 1
fi
cp  /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/run/SA-salix-leaf_respiration_rate_m2-0.159/README.txt /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-25/out/SA-salix-leaf_respiration_rate_m2-0.159/README.txt
