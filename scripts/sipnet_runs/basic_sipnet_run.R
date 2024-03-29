# Script's objective -----------------------------------------------------------

# The main objective of this script  is to generate the necessary inputs to run 
# the run.write.configs function 

# Remove previous pecan runs to avoid clutter ----------------------------------

# Shows files or directories in working directory 
remove_run <- list.files(path = "/data/workflows/",
                         pattern = "PEcAn_",
                         full.names = TRUE)

# Deletes the directory in working directory 
unlink(remove_run, recursive=TRUE)


# Clean environment ------------------------------------------------------------
rm(list = ls())

# Read settings file -----------------------------------------------------------
setwd("/home/carya/")

settings <- PEcAn.settings::read.settings("./gsoc_project_2022/xml_files/v4_sipnet.xml")

# Configure settings -----------------------------------------------------------

# Modify xml
settings$ensemble$size <- 4

settings$ensemble$samplingspace$parameters$method <- 'lhc'

# PEcAn Workflow ---------------------------------------------------------------

## Load required libraries ------------------------------------------------------
library("PEcAn.all")
library("RCurl")


# Open and read in settings file for PEcAn run.
settings 

# Check for additional modules that will require adding settings
if ("benchmarking" %in% names(settings)) {
    library(PEcAn.benchmark)
    settings <- papply(settings, read_settings_BRR)
}

if ("sitegroup" %in% names(settings)) {
    if (is.null(settings$sitegroup$nSite)) {
        settings <- PEcAn.settings::createSitegroupMultiSettings(settings,
                                                                 sitegroupId = settings$sitegroup$id
        )
    } else {
        settings <- PEcAn.settings::createSitegroupMultiSettings(
            settings,
            sitegroupId = settings$sitegroup$id,
            nSite = settings$sitegroup$nSite
        )
    }
    # zero out so don't expand a second time if re-reading
    settings$sitegroup <- NULL
}

# Update/fix/check settings.
# Will only run the first time it's called, unless force=TRUE

settings <-
    PEcAn.settings::prepare.settings(settings, force = FALSE)

## Write pecan.CHECKED.xml -----------------------------------------------------
PEcAn.settings::write.settings(settings, outputfile = "pecan.CHECKED.xml")


## Do conversions --------------------------------------------------------------
settings <- PEcAn.workflow::do_conversions(settings)

## Check db connection ---------------------------------------------------------
print(db.open(settings$database$bety))

## Query the trait database for data and priors --------------------------------
if (PEcAn.utils::status.check("TRAIT") == 0) {
    PEcAn.utils::status.start("TRAIT")
    settings <- PEcAn.workflow::runModule.get.trait.data(settings)
    PEcAn.settings::write.settings(settings,
                                   outputfile = "pecan.TRAIT.xml"
    )
    PEcAn.utils::status.end()
} else if (file.exists(file.path(settings$outdir, "pecan.TRAIT.xml"))) {
    settings <- PEcAn.settings::read.settings(file.path(settings$outdir, "pecan.TRAIT.xml"))
}


## Run the PEcAn meta.analysis ------------------------------------------------- 
if (!is.null(settings$meta.analysis)) {
    if (PEcAn.utils::status.check("META") == 0) {
        PEcAn.utils::status.start("META")
        PEcAn.MA::runModule.run.meta.analysis(settings)
        PEcAn.utils::status.end()
    }
}

## Write model specific configs ------------------------------------------------
if (PEcAn.utils::status.check("CONFIG") == 0) {
    
    PEcAn.utils::status.start("CONFIG")
    
    settings <-
        PEcAn.workflow::runModule.run.write.configs(settings)
    
    PEcAn.settings::write.settings(settings, outputfile = "pecan.CONFIGS.xml")
    PEcAn.utils::status.end()
    
} else if (file.exists(file.path(settings$outdir, "pecan.CONFIGS.xml"))) {
    
    settings <- PEcAn.settings::read.settings(file.path(settings$outdir, 
                                                        "pecan.CONFIGS.xml"))
}


## Start ecosystem model runs --------------------------------------------------

PEcAn.remote::runModule.start.model.runs(settings)

### Get results of model runs --------------------------------------------------

if (PEcAn.utils::status.check("OUTPUT") == 0) {
    
    PEcAn.utils::status.start("OUTPUT")
    
    runModule.get.results(settings)
    
    PEcAn.utils::status.end()
}

## Run ensemble analysis on model output ---------------------------------------
if ("ensemble" %in% names(settings) && PEcAn.utils::status.check("ENSEMBLE") == 0) {
    
    PEcAn.utils::status.start("ENSEMBLE")
    
    runModule.run.ensemble.analysis(settings, TRUE)
    
    PEcAn.utils::status.end()
}

## Run sensitivity analysis and variance decomposition on model output ---------
if ("sensitivity.analysis" %in% names(settings) && PEcAn.utils::status.check("SENSITIVITY") == 0) {
    
    PEcAn.utils::status.start("SENSITIVITY")
    
    runModule.run.sensitivity.analysis(settings)
    
    PEcAn.utils::status.end()
}

## Run parameter data assimilation ---------------------------------------------
if ("assim.batch" %in% names(settings)) {
    
    if (PEcAn.utils::status.check("PDA") == 0) {
    
            PEcAn.utils::status.start("PDA")
        
            settings <-
                PEcAn.assim.batch::runModule.assim.batch(settings)
            
            PEcAn.utils::status.end()
    }
}

## Run state data assimilation -------------------------------------------------
if ("state.data.assimilation" %in% names(settings)) {
    
    if (PEcAn.utils::status.check("SDA") == 0) {
    
            PEcAn.utils::status.start("SDA")
            
            settings <- sda.enfk(settings)
            
            PEcAn.utils::status.end()
    }
}

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

# Generate a copy of the run and save it to the gsoc folder --------------------


if (length(dir("/data/workflows/")) == 1){
    
    file <- list.files(path = "/data/workflows/",
                       pattern = "PEcAn_",
                       full.names = TRUE)
    
    file.copy(from = file, 
              to = "/home/carya/gsoc_project_2022/pecan_runs", 
              overwrite = TRUE, 
              recursive = TRUE, 
              copy.mode = TRUE)
    } else {
    
        print("More than 1 file in the folder, select which one to copy")}






