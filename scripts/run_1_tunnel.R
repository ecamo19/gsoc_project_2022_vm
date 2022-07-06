
# Load packages ----------------------------------------------------------------
library(PEcAn.utils)
library(RCurl)
library(PEcAn.DB)
library(PEcAn.uncertainty)
library(PEcAn.settings)
library(PEcAn.BIOCRO)
library(PEcAn.all)
library(PEcAn.SIPNET)

# Remote access ----------------------------------------------------------------

# These steps should be done a the beginning of each session 

# Step 1: Create tunnel in BASH
# ssh -nNf -o ControlMaster=yes -S /tmp/ecalder1_gsoc_1 ecalder1@geo.bu.edu


# Step 2: access tunnel
scc_host <- list(name = "geo.bu.edu", tunnel = "/tmp/ecalder1_gsoc_tunnel_1")

# Step 3: Test that is working
PEcAn.remote::remote.execute.cmd(host = scc_host,
                                  cmd = "echo", args = "Hello world")



# # Step 4: Delete add the end of the session
# ssh -S /path/to/socket/file <hostname> -O exit

# Read settings file -----------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
if (is.na(args[1])){
    settings <- PEcAn.settings::read.settings("/home/carya/gsoc/xml_files/pecan_tunnel.xml") 
} else {
    settings.file <- args[1]
    settings <- PEcAn.settings::read.settings(settings.file)
}

# Prepare settings -------------------------------------------------------------
settings <- PEcAn.settings::prepare.settings(settings, force = TRUE)

PEcAn.remote::remote.execute.R(settings,verbose = T,user = "ecalder1",
                               script = "prepare.settings",
                               host = scc_host)

PEcAn.remote::remote.execute.R(settings,
                               host = scc_host,
                               script = "PEcAn.remote::runModule.start.model.run")
    
    

PEcAn.remote::runModule.start.model.runs(settings = settings)

# Configure settings -----------------------------------------------------------
settings$outdir <- file.path('/projectnb/dietzelab/ecalder1/Site_Outputs/Harvard/April15/PEcAn_test')
settings$ensemble$size <- 10
settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')
settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', settings$pfts$pft$name)
settings$ensemble$samplingspace$parameters$method <- 'lhc'

# Write settings ---------------------------------------------------------------
PEcAn.remote::remote.execute.R(user = "ecalder1",
                               host = scc_host,
                               script = settings)


PEcAn.settings::write.settings(settings, outputfile = "pecan.CHECKED.xml")
settings <- PEcAn.workflow::do_conversions(settings)
PEcAn.remote::remote.execute.R(user = "ecalder1",
                               host = scc_host,
                               script = settings)


# Test get trait data function -------------------------------------------------
settings <- PEcAn.workflow::runModule.get.trait.data(settings)

if (PEcAn.utils::status.check("TRAIT") == 0){
    PEcAn.utils::status.start("TRAIT")
    settings <- PEcAn.workflow::runModule.get.trait.data(settings)
    PEcAn.settings::write.settings(settings, outputfile='pecan.TRAIT.xml')
    PEcAn.utils::status.end()
} else if (file.exists(file.path(settings$outdir, 'pecan.TRAIT.xml'))) {
    settings <- PEcAn.settings::read.settings(file.path(settings$outdir, 'pecan.TRAIT.xml'))
}

# Run meta analysis ------------------------------------------------------------
PEcAn.MA::runModule.run.meta.analysis(settings)

# Run model --------------------------------------------------------------------
settings <- PEcAn.workflow::runModule.run.write.configs(settings)
PEcAn.remote::runModule.start.model.runs(settings, stop.on.error = TRUE)
PEcAn.remote::start.model.runs(settings)
PEcAn.remote::fqdn()

# Run ensemble -----------------------------------------------------------------

# if ('ensemble' %in% names(settings) & PEcAn.utils::status.check("ENSEMBLE") == 0) {
#     PEcAn.utils::status.start("ENSEMBLE")
#     runModule.run.ensemble.analysis(settings, TRUE)
#     PEcAn.utils::status.end()
# }
# 
runModule.run.ensemble.analysis(settings, TRUE)
