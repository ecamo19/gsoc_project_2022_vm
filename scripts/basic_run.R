# Script's objective -----------------------------------------------------------

# The main objective of this script  is to generate the necessary inputs to run 
# the run.write.configs function 

# Remove previous pecan runs to avoid clutter ----------------------------------

# Shows files or directories in working directory 
remove_run <- list.files(path = "~/gsoc_project_2022/pecan_runs/",
                         pattern = "pecan_run_salix",
                         full.names = TRUE)

# Deletes the directory in working directory 
unlink(remove_run, recursive=TRUE)


# Clean environment ------------------------------------------------------------
rm(list = ls())

# Load packages ----------------------------------------------------------------
library(PEcAn.all)
library(PEcAn.BIOCRO)
library(PEcAn.utils)
library(RCurl)

# Working directory ------------------------------------------------------------
setwd('/home/carya')
getwd()

# Read settings file -----------------------------------------------------------
settings <- PEcAn.settings::read.settings("./gsoc_project_2022/xml_files/simple_biocro.xml")

# Configure settings -----------------------------------------------------------

# Get date
path <- paste0('gsoc_project_2022/pecan_runs/pecan_run_salix')

# Set output dir
settings$outdir <- file.path(path)

# Modify xml
settings$ensemble$size <- 10

settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')

settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', 
                                            settings$pfts$pft$name)

settings$ensemble$samplingspace$parameters$method <- 'lhc'
#settings$ensemble$ensemble.id <- 666

# PEcAn Workflow ---------------------------------------------------------------
settings <- PEcAn.settings::prepare.settings(settings, force = FALSE)

## Write pecan.CHECKED.xml -----------------------------------------------------
PEcAn.settings::write.settings(settings, outputfile = "pecan.CHECKED.xml")
PEcAn.settings::check.workflow.settings(settings)

## Do conversions --------------------------------------------------------------
settings <- PEcAn.workflow::do_conversions(settings)

##  Query the trait database for data and priors -------------------------------
settings <- runModule.get.trait.data(settings)

## Check db connection ---------------------------------------------------------
print(db.open(settings$database$bety))

## Run the PEcAn meta.analysis -------------------------------------------------
runModule.run.meta.analysis(settings)

## Write model specific configs ------------------------------------------------
if (PEcAn.utils::status.check("CONFIG") == 0){
    PEcAn.utils::status.start("CONFIG")
    settings <- PEcAn.workflow::runModule.run.write.configs(settings)
    PEcAn.settings::write.settings(settings, outputfile='pecan.CONFIGS.xml')
    PEcAn.utils::status.end()
} else if (file.exists(file.path(settings$outdir, 'pecan.CONFIGS.xml'))) {
    settings <- PEcAn.settings::read.settings(file.path(settings$outdir, 'pecan.CONFIGS.xml'))
}

if ((length(which(commandArgs() == "--advanced")) != 0) && (PEcAn.utils::status.check("ADVANCED") == 0)) {
    PEcAn.utils::status.start("ADVANCED")
    q();
}

## Start ecosystem model runs --------------------------------------------------
if (PEcAn.utils::status.check("MODEL") == 0) {
    PEcAn.utils::status.start("MODEL")
    PEcAn.remote::runModule.start.model.runs(settings, stop.on.error = FALSE)
    PEcAn.utils::status.end()
}

### Get results of model runs --------------------------------------------------
# Step for generating ensemble.output

if (PEcAn.utils::status.check("OUTPUT") == 0) {
    PEcAn.utils::status.start("OUTPUT")
    runModule.get.results(settings)
    PEcAn.utils::status.end()
}

## Run ensemble analysis on model output ---------------------------------------
if ('ensemble' %in% names(settings) & PEcAn.utils::status.check("ENSEMBLE") == 0) {
    PEcAn.utils::status.start("ENSEMBLE")
    runModule.run.ensemble.analysis(settings, TRUE)
    PEcAn.utils::status.end()
}

## Run sensitivity analysis on model output ------------------------------------
if ('sensitivity.analysis' %in% names(settings) & PEcAn.utils::status.check("SENSITIVITY") == 0) {
    PEcAn.utils::status.start("SENSITIVITY")
    runModule.run.sensitivity.analysis(settings)
    PEcAn.utils::status.end()
}

# End --------------------------------------------------------------------------
rm(list = ls())


