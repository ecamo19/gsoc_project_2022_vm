
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

getwd()
setwd("~/gsoc/")
# Remote access ----------------------------------------------------------------

# These steps should be done a the beginning of each session 

# Step 1: Create tunnel in BASH
ssh -nNf -o ControlMaster=yes -S /tmp/ecalder1_gsoc_5 ecalder1@geo.bu.edu


# Step 2: access tunnel
scc_host <- list(name = "geo.bu.edu", tunnel = "/tmp/ecalder1_gsoc_3")

# Step 3: Test that is working
PEcAn.remote::remote.execute.cmd(host = scc_host,
                                  cmd = "echo", args = "Hello world")


# # Step 4: Delete add the end of the session
# ssh -S /path/to/socket/file <hostname> -O exit

# Read settings file -----------------------------------------------------------

#settings <- PEcAn.settings::read.settings("/home/carya/gsoc/xml_files/pecan_web_test_local.xml") 
settings <- PEcAn.settings::read.settings("/home/carya/gsoc/xml_files/pecan_web_test_tunnel.xml") 


# Configure settings -----------------------------------------------------------
#settings$outdir <- file.path('./gsoc/pecan_runs/run_1/')
settings$ensemble$size <- 5
settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')
settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', settings$pfts$pft$name)
settings$ensemble$samplingspace$parameters$method <- 'lhc'

# Prepare settings -------------------------------------------------------------
settings <- PEcAn.settings::prepare.settings(settings, force = TRUE)


# Write settings ---------------------------------------------------------------
PEcAn.settings::write.settings(settings, outputfile = "pecan.CHECKED.xml")
settings <- PEcAn.workflow::do_conversions(settings)


# Test get trait data function -------------------------------------------------
settings <- PEcAn.workflow::runModule.get.trait.data(settings)


# Run meta analysis ------------------------------------------------------------
PEcAn.MA::runModule.run.meta.analysis(settings)
 
# Run model --------------------------------------------------------------------
#settings <- PEcAn.workflow::runModule.run.write.configs(settings)
#PEcAn.remote::runModule.start.model.runs(settings, stop.on.error = TRUE) 

# Run ensemble -----------------------------------------------------------------

# if ('ensemble' %in% names(settings) & PEcAn.utils::status.check("ENSEMBLE") == 0) {
#     PEcAn.utils::status.start("ENSEMBLE")
#     runModule.run.ensemble.analysis(settings, TRUE)
#     PEcAn.utils::status.end()
# }

#runModule.run.ensemble.analysis(settings, TRUE)
