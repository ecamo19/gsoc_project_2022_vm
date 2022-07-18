# Script objective -------------------------------------------------------------

# The main objective of this script  is to generate the post.distns.Rdata and 
# prior.distns.Rdata needed in the run.write.configs function 

# Load packages ----------------------------------------------------------------
library(PEcAn.all)

# Working directory ------------------------------------------------------------
setwd('/home/carya')
getwd()

# Read settings file -----------------------------------------------------------
#settings <- PEcAn.settings::read.settings("./gsoc_project_2022/xml_files/simple.xml")
settings <- PEcAn.settings::read.settings("./gsoc_project_2022/xml_files/simple_biocro.xml")


## Configure settings ----------------------------------------------------------

# Get date
path <- paste0('gsoc_project_2022/pecan_runs/run_', Sys.Date())

settings$outdir <- file.path(path)
settings$outdir

settings$database$bety$write
settings$database$bety$write <- FALSE

settings$ensemble$size <- 100

settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')

settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', 
                                      settings$pfts$pft$name)

settings$ensemble$samplingspace$parameters$method <- 'lhc'

# PEcAn Workflow ---------------------------------------------------------------
settings <- PEcAn.settings::prepare.settings(settings, force = FALSE)


## Write pecan.CHECKED.xml -----------------------------------------------------
PEcAn.settings::write.settings(settings, outputfile = "pecan.CHECKED.xml")

## Do conversions --------------------------------------------------------------
settings <- PEcAn.workflow::do_conversions(settings)

##  Query the trait database for data and priors -------------------------------
settings <- runModule.get.trait.data(settings)

## Run the PEcAn meta.analysis -------------------------------------------------
runModule.run.meta.analysis(settings)

## Write model specific configs ------------------------------------------------
runModule.run.write.configs(settings)

## Start ecosystem model runs --------------------------------------------------
debugonce(runModule.start.model.runs)
PEcAn.remote::runModule.start.model.runs(settings,stop.on.error = TRUE)
settings$database$bety$write

# Get results of model runs ----------------------------------------------------

if (PEcAn.utils::status.check("OUTPUT") == 0) {
    PEcAn.utils::status.start("OUTPUT")
    runModule.get.results(settings)
    PEcAn.utils::status.end()
}

## Run ensemble analysis on model output ---------------------------------------





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


