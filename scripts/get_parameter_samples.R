# Code objective ---------------------------------------------------------------
# I am running this code for generating the env.samples.Rdata need it in the 
# get.parameters function 

getwd()
rm(list = ls())

# Load settings ----------------------------------------------------------------
source("~/gsoc_project_2022/scripts/load_settings.R")


# Get general info: extract pft names ------------------------------------------

# posterior.files Filenames for posteriors for drawing samples for ensemble and 
# sensitivity  analysis (e.g. post.distns.Rdata, or prior.distns.Rdata)

#get.parameter.samples <- function(settings, 
#                                  posterior.files = rep(NA, length(settings$pfts)), 
#                                  ens.sample.method = "uniform") 
    

posterior.files <-  load("./pecan_runs/pecan_run_salix/pft/salix/prior.distns.Rdata")

ens.sample.method = "uniform"
pfts      <- settings$pfts
num.pfts  <- length(settings$pfts)
pft.names <- list()
outdirs   <- list()
    
# Open database connection
con <- try(PEcAn.DB::db.open(settings$database$bety))
on.exit(try(PEcAn.DB::db.close(con), silent = TRUE), add = TRUE)
    
# If we fail to connect to DB then we set to NULL
if (inherits(con, "try-error"))  {
        con <- NULL
        PEcAn.logger::logger.warn("We were not able to successfully establish a connection with Bety ")
} else {
    print("success")
}


# First: loop for getting outdir -----------------------------------------------

for (i.pft in seq_along(pfts)) {
        pft.names[i.pft] <- settings$pfts[[i.pft]]$name
        
        ### If no PFT(s) are specified insert NULL to warn user
        if (length(pft.names) == 0) {
            pft.names[1] <- "NULL"
            print("step 1")
            print(pft.names)
        }
        
        ### Get output directory info
        if(!is.null(settings$pfts[[i.pft]]$outdir)){
            outdirs[i.pft] <- settings$pfts[[i.pft]]$outdir
            
            print("step 2:success")
            print(outdirs)
            
        } else { 
            outdirs[i.pft] <- unique(dbfile.check(type = "Posterior",
                                                  container.id = settings$pfts[[i.pft]]$posteriorid,con=con)$file_path)
            print("step 3")
            print(outdirs)
        }
        
}   


# Modify outdir that I get for reading Rdata from folder ----------------------
outdirs <- paste0("~/", outdirs)    
    
## Generate empty list arrays for output ---------------------------------------
trait.samples <- sa.samples <- ensemble.samples <- env.samples <- runs.samples <- param.names <- list()
    
# flag determining whether samples are independent (e.g. when params fitted individually)
independent <- TRUE

posterior.files

dir()

# Second: loop Load PFT priors and posteriors ----------------------------------

# for (i in seq_along(pft.names)) {
        
#rm(prior.distns, post.distns, trait.mcmc)
        
## Load posteriors -------------------------------------------------------------

# Method 1
if (!is.na(posterior.files[1])) {
  
    # Load specified file
    load(posterior.files[1])} else {print("Not loaded")}

# Method 2    
if (!exists("prior.distns") & exists("post.distns")){
    prior.distns <- post.distns 
    print("true")} else {print("Not loaded")}
  
# Method 3              
# Default to most recent posterior in the workflow, or the prior if there is none

fname <- file.path(outdirs[1], "post.distns.Rdata")
if(file.exists(fname)){
                print("true")
                load(fname)
                prior.distns <- post.distns
                } else {print("Not loaded")} 

# Method 4              
load(file.path(outdirs[1], "prior.distns.Rdata")) 

## Load trait mcmc data (if exists, either from MA or PDA) ---------------------

if (!is.null(settings$pfts[[1]]$posteriorid) && !inherits(con, "try-error")) {
    
            # first check if there are any files associated with posterior ids
            files <- PEcAn.DB::dbfile.check("Posterior",
                                            settings$pfts[[1]]$posteriorid, 
                                            con, settings$host$name, return.all = TRUE)
            
            
            # These line don't run
            tid <- grep("trait.mcmc.*Rdata", files$file_name)
            if (length(tid) > 0) {
                trait.mcmc.file <- file.path(files$file_path[tid], files$file_name[tid])
                ma.results <- TRUE
                load(trait.mcmc.file)
                
                # PDA samples are fitted together, to preserve correlations downstream let workflow know they should go together
                if(grepl("mcmc.pda", trait.mcmc.file)) independent <- FALSE 
                # NOTE: Global MA samples will also be together, right?
            # These linen don't run
                    
            } else{
                    PEcAn.logger::logger.info("No trait.mcmc file is associated with this posterior ID.")
                    ma.results <- FALSE
                    
            }} else if ("trait.mcmc.Rdata" %in% dir(unlist(outdirs[1]))) {
                        PEcAn.logger::logger.info("Defaulting to trait.mcmc file in the pft directory.")
                        ma.results <- TRUE
                        load(file.path(outdirs[1], "trait.mcmc.Rdata"))
                        print("File updated")
        } else {
            ma.results <- FALSE
        }

        
## When no ma for a trait, sample from prior -----------------------------------
## Trim all chains to shortest mcmc chain, else 20000 samples

# Get name        
pft.name <- unlist(pft.names[1])

priors <- rownames(prior.distns)
        
if (exists("trait.mcmc")) {
            param.names[[1]] <- names(trait.mcmc)
            names(param.names)[1] <- pft.name
            
            samples.num <- min(sapply(trait.mcmc, function(x) nrow(as.matrix(x))))
            
            # report which traits use MA results, which use priors
            if (length(param.names[[1]]) > 0) {
                PEcAn.logger::logger.info("PFT", pft.names[1], "has MCMC samples for:\n",
                                          paste0(param.names[[1]], collapse = "\n "))
            }
            if (!all(priors %in% param.names[[1]])) {
                PEcAn.logger::logger.info("PFT", pft.names[1], "will use prior distributions for:\n", 
                                          paste0(priors[!priors %in% param.names[[1]]], collapse = "\n "))
            }
        #} else {
        #    param.names[[1]] <- list()
        #    samples.num <- 20000
        #    PEcAn.logger::logger.info("No MCMC results for PFT", pft.names[i])
        #    PEcAn.logger::logger.info("PFT", pft.names[i], "will use prior distributions for", 
        #                              priors)
        }
        
PEcAn.logger::logger.info("using ", samples.num, "samples per trait")

## Ensemble sampling method ----------------------------------------------------

if (ens.sample.method == "halton") {
            q_samples <- randtoolbox::halton(n = samples.num, dim = length(priors))
            print("Halton used")
            
        } else if (ens.sample.method == "sobol") {
            q_samples <- randtoolbox::sobol(n = samples.num, dim = length(priors), scrambling = 3)
            print("sobol used")
        
        } else if (ens.sample.method == "torus") {
            q_samples <- randtoolbox::torus(n = samples.num, dim = length(priors))
            print("torus used")
            
        } else if (ens.sample.method == "lhc") {
            q_samples <- PEcAn.emulator::lhc(t(matrix(0:1, ncol = length(priors), nrow = 2)), samples.num)
            print("lhc used")
            
        } else if (ens.sample.method == "uniform") {
            q_samples <- matrix(stats::runif(samples.num * length(priors)),
                                samples.num, 
                                length(priors))
            print("uniform used")
            
        } else {
            PEcAn.logger::logger.info("Method ", ens.sample.method, " has not been implemented yet, using uniform random sampling")
            # uniform random
            q_samples <- matrix(stats::runif(samples.num * length(priors)),
                                samples.num, 
                                length(priors))
        }

##  Get trait samples  ---------------------------------------------------------

for (prior in priors) {
  
            if (prior %in% param.names[[1]]) {
                samples <- trait.mcmc[[prior]] %>% purrr::map(~ .x[,'beta.o']) %>% unlist() %>% as.matrix()
                
            } else {
                samples <- PEcAn.priors::get.sample(prior.distns[prior, ], samples.num, q_samples[ , priors==prior])
            }
            trait.samples[[pft.name]][[prior]] <- samples
        }


# Third ------------------------------------------------------------------------

# if samples are independent, set param.names to NULL
# this is important for downstream, when param.names is not NULL MCMC will be sampled accordingly
if(independent){
        param.names <- NULL
    }


## Sensitivity samples ---------------------------------------------------------

if ("sensitivity.analysis" %in% names(settings)) {
        
        ## Get info on the quantiles to be run in the sensitivity analysis (if requested)
        quantiles <- get.quantiles(settings$sensitivity.analysis$quantiles)
        
        ## Get info on the years to run the sensitivity analysis (if requested)
        sa.years <- data.frame(sa.start = settings$sensitivity.analysis$start.year, 
                               sa.end = settings$sensitivity.analysis$end.year)
        
        PEcAn.logger::logger.info("\n Selected Quantiles: ", vecpaste(round(quantiles, 3)))
        
        ### Generate list of sample quantiles for SA run
        sa.samples <- get.sa.sample.list(pft = trait.samples, env = env.samples, 
                                         quantiles = quantiles)
}

## Ensemble samples ------------------------------------------------------------

if ("ensemble" %in% names(settings)) {
    
        if (settings$ensemble$size == 1) {
            ## run at median if only one run in ensemble
            ensemble.samples <- get.sa.sample.list(pft = trait.samples, env = env.samples, 
                                                   quantiles = 0.5)
            #if it's not there it's one probably
            if (is.null(settings$ensemble$size)) settings$ensemble$size <- 1
            print("ensemble size greater than 1")
            
        } else if (settings$ensemble$size > 1) {
            
            ## subset the trait.samples to ensemble size using Halton sequence
            ensemble.samples <- get.ensemble.samples(settings$ensemble$size, trait.samples, 
                                                     env.samples, ens.sample.method, param.names)
        }
    }
    
# save samples -----------------------------------------------------------------
save(ensemble.samples, trait.samples, sa.samples, runs.samples, env.samples, 
         file = file.path(settings$outdir, "samples.Rdata"))

# get.parameter.samples



