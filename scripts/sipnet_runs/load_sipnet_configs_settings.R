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
settings <- read.settings("./pecan_runs/PEcAn_99000000012/pecan.CONFIGS.xml")

print(PEcAn.settings::check.workflow.settings(settings))

# Configure settings -----------------------------------------------------------

# Modify xml
settings$ensemble$size <- 4

settings$ensemble$samplingspace$parameters$method <- 'lhc'

# Print wd ---------------------------------------------------------------------
cat(blue(paste0("\n Current working directory: ", getwd(), " \n")))

