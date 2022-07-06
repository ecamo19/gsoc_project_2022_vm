# Load packages ----------------------------------------------------------------
library(PEcAn.all)

# Working directory ------------------------------------------------------------
setwd('/home/carya')
getwd()

# Read settings file -----------------------------------------------------------
settings <- PEcAn.settings::read.settings("./gsoc_project_2022/xml_files/simple.xml")

## Configure settings ----------------------------------------------------------

# Get date
path <- paste0('./gsoc_project_2022/pecan_runs/run_', Sys.Date())

settings$outdir <- file.path(path)

settings$ensemble$size <- 100

settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')

settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', 
                                      settings$pfts$pft$name)

settings$ensemble$samplingspace$parameters$method <- 'lhc'

# PEcAn Workflow ---------------------------------------------------------------
settings <- PEcAn.settings::prepare.settings(settings, force = FALSE)

PEcAn.DB::db.open(settings$database$bety)

## Write pecan.CHECKED.xml -----------------------------------------------------
PEcAn.settings::write.settings(settings, outputfile = "pecan.CHECKED.xml")

## Do conversions --------------------------------------------------------------
settings <- PEcAn.workflow::do_conversions(settings)

##  Query the trait database for data and priors -------------------------------
if (PEcAn.utils::status.check("TRAIT") == 0) {
    PEcAn.utils::status.start("TRAIT")
    settings <- PEcAn.workflow::runModule.get.trait.data(settings)
    PEcAn.settings::write.settings(settings,
                                   outputfile = "pecan.TRAIT.xml"
    )
    PEcAn.utils::status.end()
} else if (file.exists(file.path(settings$outdir, "pecan.TRAIT.xml"))) {
    settings <- 
        PEcAn.settings::read.settings(file.path(settings$outdir, "pecan.TRAIT.xml"))
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
    settings <- 
        PEcAn.settings::read.settings(file.path(settings$outdir, "pecan.CONFIGS.xml"))
}

if ((length(which(commandArgs() == "--advanced")) != 0)
    && (PEcAn.utils::status.check("ADVANCED") == 0)) {
    PEcAn.utils::status.start("ADVANCED")
    q()
}


