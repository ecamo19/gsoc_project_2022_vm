# Objective --------------------------------------------------------------------
# This script loads the settings file

# Change working directory to pecan run ----------------------------------------
setwd("~/gsoc_project_2022/")
getwd()

# Load packages ----------------------------------------------------------------
library(PEcAn.all)
library(devtools)
# Changes the color of a message
library(crayon)

# Load xml file  ---------------------------------------------------------------
settings <- read.settings("./pecan_runs/sipnet_for_comparing_not_input_specified/pecan.CONFIGS.xml")

print(PEcAn.settings::check.workflow.settings(settings))

# Configure settings -----------------------------------------------------------

# Modify xml
settings$ensemble$size <- 4

settings$ensemble$samplingspace$parameters$method <- 'lhc'

# Print wd ---------------------------------------------------------------------
cat(blue(paste0("\n Current working directory: ", getwd(), " \n")))

