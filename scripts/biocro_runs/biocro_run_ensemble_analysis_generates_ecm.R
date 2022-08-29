# Objective --------------------------------------------------------------------
# This script is for running the run.ensemble.analysis function inside 
# run.ensemble.analysis.R file

rm(list = ls())

# Load functions settings file -------------------------------------------------
source("~/gsoc_project_2022/scripts/load_settings.R")


# Load packages ----------------------------------------------------------------
library(PEcAn.all)
library(devtools)

# Load xml file  ---------------------------------------------------------------
settings <- read.settings("./run_2022-07-25/pecan.CONFIGS.xml")
PEcAn.settings::check.workflow.settings(settings)

# Configure settings -----------------------------------------------------------

#path <- paste0('gsoc_project_2022/pecan_runs/ensemble_run')

# Set output dir
#settings$outdir <- file.path(path)

# Modify xml
settings$ensemble$size <- 10

#settings$database$dbfiles <- file.path(settings$outdir, 'dbfiles')

#settings$pfts$pft$outdir <- file.path(settings$outdir, 'pft', 
#                                      settings$pfts$pft$name)

settings$ensemble$samplingspace$parameters$method <- 'lhc'

# Run ensemble analysis on model output ----------------------------------------

suppressWarnings(ens.ids <- as.numeric(sub("ensemble.samples.", "", 
                                           sub(".Rdata", "", 
                                               dir(settings$outdir, 
                                                   "ensemble.samples")))))

## Get config variables -------------------------------------------------------- 
ens.ids

start.year <- settings$ensemble$start.year
end.year <- settings$ensemble$end.year
ensemble.id <-  NULL
variable <- NULL

## Get variable name -----------------------------------------------------------
if ("variable" %in% names(settings$ensemble)) {
        var <- which(names(settings$ensemble) == "variable")
        for (i in seq_along(var)) {
            variable[i] <- settings$ensemble[[var[i]]]
        }
}

variable
variables <- variable

## Convert variables ------------------------------------------------------------

# converted to gC/m2/s
cflux <- c("GPP", "NPP", "NEE", "TotalResp", "AutoResp", "HeteroResp", 
           "DOC_flux", "Fire_flux") 

# kgH20 m-2 s-1
wflux <- c("Evap", "TVeg", "Qs", "Qsb", "Rainf")
        
variables <- PEcAn.utils::convert.expr(variable)
variable.ens <- variables$variable.eqn
variable.fn <- variables$variable.drv
        
units <- paste0(variable.fn, " (", mstmipvar(variable.fn, silent=TRUE)$units, ")")
        
## Load parsed model results ---------------------------------------------------

# Reads ensemble.output file 
fname <- ensemble.filename(settings, 
                                   "ensemble.output", 
                                   "Rdata", 
                                   all.var.yr = FALSE,
                                   ensemble.id = ensemble.id, 
                                   variable = variable.fn, 
                                   start.year = start.year, 
                                   end.year = end.year)
        
load(fname)
my.dat = unlist(ensemble.output)

## Generate ensemble figures  --------------------------------------------------
ensemble.results <- list()

## Boxplots and histogram

fname <- ensemble.filename(settings,
                  "ensemble.analysis",
                  "pdf",
                  all.var.yr = FALSE,
                  ensemble.id = ensemble.id,
                  variable = variable.fn,
                  start.year = start.year,
                  end.year = end.year)

pdf(file = fname, width = 13, height = 6)
par(mfrow = c(1, 2), mar = c(4, 4.8, 1, 2))  # B, L, T, R

hist(my.dat,xlab=units,
     main="",cex.axis=1.1,cex.lab=1.4,col="grey85")

boxplot(my.dat,ylab=units,
        boxwex=0.6,col="grey85", cex.axis=1.1,range=2,
        pch=21,cex=1.4, bg="black",cex.lab=1.5)

## Time series plot 
## NEED THE ENSEMBLE.TS FILE, Currently not found

plot.timeseries = TRUE

fname <- ensemble.filename(settings, "ensemble.ts", "pdf",
                               all.var.yr = FALSE, 
                               ensemble.id = ensemble.id, 
                               variable = variable.fn,
                               start.year = start.year, 
                               end.year = end.year)

pdf(fname, width = 12, height = 9)

ensemble.ts.analysis <- ensemble.ts(read.ensemble.ts(settings, variable = variable))
    dev.off()
    
fname <- ensemble.filename(settings, "ensemble.ts.analysis", "Rdata", 
                               all.var.yr = FALSE, 
                               ensemble.id = ensemble.id,
                               variable = variable.fn, 
                               start.year = start.year, 
                               end.year = end.year)

save(ensemble.ts.analysis, file = fname)

# End --------------------------------------------------------------------------










