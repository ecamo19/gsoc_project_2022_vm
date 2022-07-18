#!/bin/bash
mkdir -p /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-18/out/ENS-00025-76
cd /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-18/run/ENS-00025-76
 /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-18/run/ENS-00025-76 /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-18/out/ENS-00025-76
if [ $? -ne 0 ]; then
    echo ERROR IN MODEL RUN >&2
    exit 1
fi
cp  /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-18/run/ENS-00025-76/README.txt /home/carya/gsoc_project_2022/pecan_runs/run_2022-07-18/out/ENS-00025-76/README.txt
