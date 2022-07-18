#!/bin/bash
mkdir -p /home/carya/./gsoc_project_2022/pecan_runs/run_2022-07-07/out/99000000922
cd /home/carya/./gsoc_project_2022/pecan_runs/run_2022-07-07/run/99000000922
 /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-07/run/99000000922 /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-07/out/99000000922
if [ $? -ne 0 ]; then
    echo ERROR IN MODEL RUN >&2
    exit 1
fi
cp  /home/carya/./gsoc_project_2022/pecan_runs/run_2022-07-07/run/99000000922/README.txt /home/carya/./gsoc_project_2022/pecan_runs/run_2022-07-07/out/99000000922/README.txt
