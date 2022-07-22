# Script objective -------------------------------------------------------------

# The main objective of this script  is to generate the post.distns.Rdata and 
# prior.distns.Rdata needed in the run.write.configs function 

rm(list = ls())

# Load packages ----------------------------------------------------------------
library(PEcAn.all)
library(PEcAn.BIOCRO)

# Working directory ------------------------------------------------------------
setwd('/home/carya')
getwd()

# Read settings file -----------------------------------------------------------
#settings <- PEcAn.settings::read.settings("./gsoc_project_2022/xml_files/simple.xml")
settings <- PEcAn.settings::read.settings("./gsoc_project_2022/xml_files/simple_biocro.xml")


## Configure settings ----------------------------------------------------------

# Get date
path <- paste0('gsoc_project_2022/pecan_runs/run_', Sys.Date())

# Set output dir
settings$outdir <- file.path(path)

# Modify settings
settings$ensemble$size <- 100

settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')

settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', 
                                            settings$pfts$pft$name)

settings$ensemble$samplingspace$parameters$method <- 'lhc'

# PEcAn Workflow ---------------------------------------------------------------

settings <- PEcAn.settings::prepare.settings(settings, force = FALSE)

settings$host$runid
#write.config.BIOCRO(defaults = settings$pfts)

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
#debugonce(start.model.runs)
start.model.runs(settings, settings$database$bety$write, stop.on.error = TRUE)

#debugonce(runModule.start.model.runs)
#PEcAn.remote::runModule.start.model.runs(settings,stop.on.error = TRUE)

### Get results of model runs --------------------------------------------------
get.results(settings)

## Run ensemble analysis on model output ---------------------------------------
runModule.run.ensemble.analysis(settings)


## Run benchmarking ------------------------------------------------------------
if ("benchmarking" %in% names(settings)
    && "benchmark" %in% names(settings$benchmarking)) {
    PEcAn.utils::status.start("BENCHMARKING")
    results <-
        papply(settings, function(x) {
            calc_benchmark(x, bety)
        })
    PEcAn.utils::status.end()
}


