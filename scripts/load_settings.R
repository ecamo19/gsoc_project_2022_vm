# Objective --------------------------------------------------------------------
# This script loads the settings file 



# Change working directory to pecan run ----------------------------------------
setwd('~/gsoc_project_2022/pecan_runs')
print(paste0("Current working directory: ",getwd()))

# Load packages ----------------------------------------------------------------
library(PEcAn.all)
library(devtools)

# Load xml file  ---------------------------------------------------------------
settings <- read.settings("./run_2022-07-25/pecan.CONFIGS.xml")

print(PEcAn.settings::check.workflow.settings(settings))

# Configure settings -----------------------------------------------------------

#path <- paste0('gsoc_project_2022/pecan_runs/ensemble_run')

# Set output dir
#settings$outdir <- file.path(path)

# Modify xml
settings$ensemble$size <- 10

#settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')

#settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', 
#                                      settings$pfts$pft$name)

settings$ensemble$samplingspace$parameters$method <- 'lhc'