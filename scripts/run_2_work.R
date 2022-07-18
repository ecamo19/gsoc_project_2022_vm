# Load packages ----------------------------------------------------------------
library(PEcAn.utils)
library(RCurl)
library(PEcAn.DB)
library(PEcAn.uncertainty)
library(PEcAn.remote)
library(PEcAn.settings)
library(PEcAn.BIOCRO)
library(PEcAn.all)
library(PEcAn.SIPNET)
library(DBI)
library(RPostgres)
library(PEcAn.data.atmosphere)

# ------------------------------------------------------------------------------
setwd('/home/carya')
getwd()

# Remote access ----------------------------------------------------------------
# These steps should be done a the beginning of each session 

# Step 1: Create tunnel in BASH
#ssh -nNf -o ControlMaster=yes -S /tmp/ecalder1_gsoc_5 ecalder1@geo.bu.edu


# Step 2: access tunnel
#scc_host <- list(name = "geo.bu.edu", tunnel = "/tmp/ecalder1_gsoc_6")

# Step 3: Test that is working
#PEcAn.remote::remote.execute.cmd(host = scc_host,
#                                 cmd = "echo", args = "Hello world")

# Read settings file -----------------------------------------------------------
settings <- PEcAn.settings::read.settings("./gsoc/xml_files/pecan_run_2.xml")

## Configure settings ----------------------------------------------------------
settings$outdir <- file.path('./pecan_runs/run_3/')
settings$ensemble$size <- 1
settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')
settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', settings$pfts$pft$name)
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

## Start ecosystem model runs --------------------------------------------------

if (PEcAn.utils::status.check("MODEL") == 0) {
    PEcAn.utils::status.start("MODEL")
    stop_on_error <- as.logical(settings[[c("run", "stop_on_error")]])
    if (length(stop_on_error) == 0) {
        # If we're doing an ensemble run, don't stop. If only a single run, we
        # should be stopping.
        if (is.null(settings[["ensemble"]]) ||
            as.numeric(settings[[c("ensemble", "size")]]) == 1) {
            stop_on_error <- TRUE
        } else {
            stop_on_error <- FALSE
        }
    }
    PEcAn.remote::runModule.start.model.runs(settings, 
                                             stop.on.error = stop_on_error)
    PEcAn.utils::status.end()
}

# Get results of model runs ----------------------------------------------------

if (PEcAn.utils::status.check("OUTPUT") == 0) {
    PEcAn.utils::status.start("OUTPUT")
    runModule.get.results(settings)
    PEcAn.utils::status.end()
}

## Run ensemble analysis on model output ---------------------------------------

if ("ensemble" %in% names(settings)
    && PEcAn.utils::status.check("ENSEMBLE") == 0) {
    PEcAn.utils::status.start("ENSEMBLE")
    runModule.run.ensemble.analysis(settings, TRUE)
    PEcAn.utils::status.end()
}

## Run sensitivity analysis and variance decomposition on model output ---------
if ("sensitivity.analysis" %in% names(settings)
    && PEcAn.utils::status.check("SENSITIVITY") == 0) {
    PEcAn.utils::status.start("SENSITIVITY")
    runModule.run.sensitivity.analysis(settings)
    PEcAn.utils::status.end()
}

## Run parameter data assimilation ----------------------------------------------
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

## Run benchmarking -------------------------------------------------------------
if ("benchmarking" %in% names(settings)
    && "benchmark" %in% names(settings$benchmarking)) {
    PEcAn.utils::status.start("BENCHMARKING")
    results <-
        papply(settings, function(x) {
            calc_benchmark(x, bety)
        })
    PEcAn.utils::status.end()
}

## Pecan workflow complete -----------------------------------------------------
if (PEcAn.utils::status.check("FINISHED") == 0) {
    PEcAn.utils::status.start("FINISHED")
    PEcAn.remote::kill.tunnel(settings)
    db.query(
        paste(
            "UPDATE workflows SET finished_at=NOW() WHERE id=",
            settings$workflow$id,
            "AND finished_at IS NULL"
        ),
        params = settings$database$bety
    )
    
    # Send email if configured
    if (!is.null(settings$email)
        && !is.null(settings$email$to)
        && (settings$email$to != "")) {
        sendmail(
            settings$email$from,
            settings$email$to,
            paste0("Workflow has finished executing at ", base::date()),
            paste0("You can find the results on ", settings$email$url)
        )
    }
    PEcAn.utils::status.end()
}
