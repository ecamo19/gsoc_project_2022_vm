# Code objective ---------------------------------------------------------------
# I am running this code for understanding how the pecan's get.ensemble.samples 
# function works

getwd()
rm(list = ls())

# Load settings and .RData -----------------------------------------------------
source("~/gsoc_project_2022/scripts/load_settings.R")
load("./pecan_runs/pecan_run_salix/samples.Rdata")
load("./pecan_runs/pecan_run_salix/pft/salix/trait.mcmc.Rdata")


# Function parameters ----------------------------------------------------------
# Get parameter values used in ensemble

# Returns a matrix of randomly or quasi-randomly sampled trait values 
# to be assigned to traits over several model runs.
# given the number of model runs and a list of sample distributions for traits
# The model run is indexed first by model run, then by trait

# number of runs in model ensemble

# @param ensemble.size number of runs in model ensemble

# @param pft.samples random samples from parameter distribution, 
# e.g. from a MCMC chain  

# @param env.samples env samples

# @param method the method used to generate the ensemble samples. Random 
# generators: uniform, uniform with latin hypercube permutation. Quasi-random 
# generators: halton, sobol, torus. Random generation draws random variates 
# whereas quasi-random generation is deterministic but well equidistributed. 
# Default is uniform. For small ensemble size with relatively large parameter 
# number (e.g ensemble size < 5 and # of traits > 5) use methods other than 
# halton. 

# @param param.names a list of parameter names that were fitted either by MA or 
# PDA, important argument, if NULL parameters will be resampled independently

# @param ... Other arguments passed on to the sampling method
 
# @return matrix of (quasi-)random samples from trait distributions



# get.ensemble.samples <- function(ensemble.size, pft.samples, env.samples, 
#                                 method = "uniform", param.names = NULL, ...) 

# Specifying parameters --------------------------------------------------------

# 10
ensemble.size <- settings$ensemble$size

# Not sure which file to use the trait.mcmc.RData or the trait.samples.RData
pft.samples <- trait.mcmc
names(pft.samples)

# env.samples <- ??

method <- "uniform"

param.names = NULL

# First: env.file --------------------------------------------------------------

ensemble.size <- as.numeric(ensemble.size)

if (ensemble.size <= 0) {
    ans <- NULL

    } else if (ensemble.size == 1) {
    
        ans <- PEcAn.utils::get.sa.sample.list(pft.samples, env.samples, 0.5)

        } else {
    
            pft.samples[[length(pft.samples) + 1]] <- env.samples
    
            names(pft.samples)[length(pft.samples)] <- "env"
    
            pft2col <- NULL
    
            for (i in seq_along(pft.samples)) {
        
                pft2col <- c(pft2col, rep(i, length(pft.samples[[i]])))
                
                }
    
        }    

total.sample.num <- sum(sapply(pft.samples, length))
random.samples <- NULL

# Second: Sampling methods -----------------------------------------------------

# Typically, ... is used for passing additional arguments on to a subsequent 
# function.    
    
    
if (method == "halton") {
        PEcAn.logger::logger.info("Using ", method, "method for sampling")
        random.samples <- randtoolbox::halton(n = ensemble.size, 
                                              dim = total.sample.num, ...)
        
        ## force as a matrix in case length(samples)=1
        random.samples <- as.matrix(random.samples)

    } else if (method == "sobol") {
        PEcAn.logger::logger.info("Using ", method, "method for sampling")
        random.samples <- randtoolbox::sobol(n = ensemble.size, 
                                             dim = total.sample.num, 
                                             scrambling = 3, ...)
        
        ## force as a matrix in case length(samples)=1
        random.samples <- as.matrix(random.samples)
        
    } else if (method == "torus") {
        PEcAn.logger::logger.info("Using ", method, "method for sampling")
        random.samples <- randtoolbox::torus(n = ensemble.size, 
                                             dim = total.sample.num, ...)
        
        ## force as a matrix in case length(samples)=1
        random.samples <- as.matrix(random.samples)
        
    } else if (method == "lhc") {
        PEcAn.logger::logger.info("Using ", method, "method for sampling")
        random.samples <- PEcAn.emulator::lhc(t(matrix(0:1, 
                                                       ncol = total.sample.num,
                                                       nrow = 2)), 
                                              ensemble.size)
        
    } else if (method == "uniform") {
        PEcAn.logger::logger.info("Using ", method, "random sampling")
        # uniform random
        random.samples <- matrix(stats::runif(ensemble.size * total.sample.num),
                                 ensemble.size, 
                                 total.sample.num)
        
    } else {
        PEcAn.logger::logger.info("Method ", method, " has not been implemented 
                                  yet, using uniform random sampling")
        # uniform random
        random.samples <- matrix(stats::runif(ensemble.size * total.sample.num),
                                 ensemble.size, 
                                 total.sample.num)
    }
    

# Third: Get Ensemble Samples --------------------------------------------------

ensemble.samples <- list()

col.i <- 0
same.i

# Test Difference between ensemble.names = NULL and Not NULL 
# Remember that ensembles.names are generated in the get.parameter.samples


# First loop -------------------------------------------------------------------

for (pft.i in seq(pft.samples)) {
    
    # Generate a empty matrix
    ensemble.samples[[1]] <- matrix(nrow = ensemble.size, 
                                        
                                        # number of mcmc chains
                                        ncol = length(pft.samples[[1]]))
    
    # Meaning we want to keep MCMC samples together
    if(length(pft.samples[[pft.i]]) > 0 & !is.null(param.names)){ print(TRUE)} 
        
        if (method == "halton") {
            
            same.i <- round(randtoolbox::halton(ensemble.size) * 
                                length(pft.samples[[pft.i]][[1]]))
            
        } else if (method == "sobol") {
            
            same.i <- round(randtoolbox::sobol(ensemble.size, scrambling = 3) * 
                                length(pft.samples[[pft.i]][[1]]))
            
        } else if (method == "torus") {
            same.i <- round(randtoolbox::torus(ensemble.size) * 
                                length(pft.samples[[pft.i]][[1]]))
            
        } else if (method == "lhc") {
            same.i <- round(c(PEcAn.emulator::lhc(t(matrix(0:1, ncol = 1, 
                                                           nrow = 2)), 
                                                  ensemble.size) * 
                                  length(pft.samples[[pft.i]][[1]])))
            
        } else if (method == "uniform") {
            same.i <- sample.int(length(pft.samples[[1]][[1]]), 
                                 ensemble.size)
            
        } else {
            PEcAn.logger::logger.info("Method ", method, 
                                      " has not been implemented yet, using 
                                      uniform random sampling")
            # uniform random
            same.i <- sample.int(length(pft.samples[[pft.i]][[1]]), 
                                 ensemble.size)
        }
        
}
  


## -----------------------------------------------------------------------------
    for (trait.i in seq(pft.samples[[pft.i]])) {
        col.i <- col.i + 1
        
        if(names(pft.samples[[pft.i]])[trait.i] %in% param.names[[pft.i]]){ # keeping samples
            ensemble.samples[[pft.i]][, trait.i] <- pft.samples[[pft.i]][[trait.i]][same.i]
            
        } else{
            ensemble.samples[[pft.i]][, trait.i] <- stats::quantile(pft.samples[[pft.i]][[trait.i]],
                                                                    random.samples[, col.i])
        }
    }  # end trait
    
    ensemble.samples[[pft.i]] <- as.data.frame(ensemble.samples[[pft.i]])
    colnames(ensemble.samples[[pft.i]]) <- names(pft.samples[[pft.i]])
}  # end pft

names(ensemble.samples) <- names(pft.samples)
ans <- ensemble.samples
}
return(ans)
} 





