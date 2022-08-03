# Code objective ---------------------------------------------------------------

# I am running this code for understanding how the pecan's get.ensemble.samples 
# function works

getwd()
rm(list = ls())

# Load settings and .RData -----------------------------------------------------
source("~/gsoc_project_2022/scripts/load_configs_settings.R")

load("./pecan_runs/pecan_run_salix/my_samples.Rdata")
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

# Object created for running the first section Adding env.samples to pft.samples
pft.samples_2 <- trait.mcmc

# Check names
names(pft.samples)

# This object is created by the get_parameter_function, here is an empty 
# list
env.samples 

method <- "uniform"

param.names = NULL

# First: Adding env.samples to pft.samples  ------------------------------------

ensemble.size <- as.numeric(ensemble.size)

if (ensemble.size <= 0) {
    ans <- NULL

    } else if (ensemble.size == 1) {
    
        ans <- PEcAn.utils::get.sa.sample.list(pft.samples_2, env.samples, 0.5)
        
        # Most of the code starts after this else
        
        } else { # closes in line 238
    
            # This code just add a empty list env at the end of pft.samples 
            # since we don't have any env.Rdata. In our case is an empty list
            # appended in the trait.mcmc
            
            pft.samples_2[[length(pft.samples_2) + 1]] <- env.samples
    
            names(pft.samples_2)[length(pft.samples_2)] <- "env"
    
            pft2col <- NULL
    
            for (i in seq_along(pft.samples_2)) {
        
                pft2col <- c(pft2col, rep(i, length(pft.samples_2[[i]])))
                
                }
    
        } # delete, closes line 83 and line ~239

# total.sample.num: 4 chains * 6 traits = 24
total.sample.num <- sum(sapply(pft.samples, length))
random.samples <- NULL

# Second: Get a random sample methods ------------------------------------------

# From all the values in pft.samples get a matrix with random values 
# (sampled following method) of size ensemble.size*total.sample.num 
# (here 6 pft*4 chains)


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

# This is the output: 
random.samples

# Third: Get Ensemble Samples --------------------------------------------------

# Test Difference between ensemble.names ?
ensemble.samples <- list()
col.i <- 0

## First loop ------------------------------------------------------------------

# This first loop returns n-empty matrices(6 here) of size ensemble.size*nchains 
# (10*4 = 40) and 6 vectors of size ensemble.size (10 here)

# Do not include env.samples if this is a empty object, because if included, 
# the code below will produce length(pft.samples) + 1 empty matrices being the 
# last one a matrix with no cols

for (pft.i in seq(pft.samples)) {

  # Generate empty matrices and add them to the empty ensemble.samples
  ensemble.samples[[pft.i]] <- matrix(nrow = ensemble.size, 
                                      
                                      # Number of chains
                                      ncol = length(pft.samples[[pft.i]]))
  
  #print(ensemble.samples[[pft.i]])
  
  # Get vector of values of size ensemble.size that will be used as 
  # indices aka object[same.i]
  # meaning we want to keep MCMC samples together
  
  if(length(pft.samples[[pft.i]]) > 0 & !is.null(param.names)){ 
    
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
      
      same.i <- round(c(PEcAn.emulator::lhc(t(matrix(0:1, ncol = 1, nrow = 2)), 
                                            ensemble.size) * 
                                             length(pft.samples[[pft.i]][[1]])))
      
    } else if (method == "uniform") {
      
      same.i <- sample.int(length(pft.samples[[pft.i]][[1]]), ensemble.size)
      
    } else {
      
      PEcAn.logger::logger.info("Method ", method, " has not been implemented 
                                                     yet, using uniform random 
                                                     sampling")
      
      same.i <- sample.int(length(pft.samples[[pft.i]][[1]]), ensemble.size)
      }  
  }
    #print(same.i)
    
#} # Delete "}" for running the loop fully, First loop + Second loop 

# First loop works, returns empty matrices with vectors    
 
## Second loop -----------------------------------------------------------------
  for (trait.i in seq(pft.samples[[pft.i]])) {
    
    col.i <- col.i + 1
    
    # keeping samples
    if(isTRUE(names(pft.samples[[pft.i]])[trait.i] %in% param.names[[pft.i]]) && # Line added for avoiding Error in if () { : argument is of length zero
       names(pft.samples[[pft.i]])[trait.i] %in% param.names[[pft.i]]) {
      
      # Get the value of pft.samples in chain n from pft iand add it to 
      # ensemble.samples   
      ensemble.samples[[pft.i]][, trait.i] <- pft.samples[[pft.i]][[trait.i]][same.i]
      
    } else{
      
          # Get the quantile of pft.samples in chain n from pft i and add it 
          # to ensemble.sample
          ensemble.samples[[pft.i]][, trait.i] <- stats::quantile(pft.samples[[pft.i]][[trait.i]],random.samples[, col.i])
          }
   
  } # End of second loop # end trait
  
  # Convert matrix to data frame
  ensemble.samples[[pft.i]] <- as.data.frame(ensemble.samples[[pft.i]])
  
# Colnames to each column
  colnames(ensemble.samples[[pft.i]]) <- names(pft.samples[[pft.i]])
  
} # closes loop, First loop + Second loop # end pft

# Check ensemble results

names(ensemble.samples) <- names(pft.samples)
ensemble.samples
#ans <- ensemble.samples


#} # the closes the else in line 83

#return(ans)
#ans

#} # closes the function get.ensemble.samples


# Create dataframe -------------------------------------------------------------
as.data.frame(ensemble.samples) %>% 
  tibble::add_column(ensemble_number = seq(1,nrow(.))) %>% 
  tidyr::pivot_longer(!ensemble_number, names_to = "input", 
                      values_to = "value_sampled") %>%  
  
  # Find the last dot in the string and separate into two columns what is in the 
  # left and in the right of that dot
  tidyr::separate(input, into = c("input", "chain_number"), sep = "\\.(?=\\w+$)")

  
# Clean environment ------------------------------------------------------------
rm(list=setdiff(ls(), "ensemble.samples"))
cat(crayon::blue(paste0("\n Ensemble samples dataframe created \n")))


# End --------------------------------------------------------------------------



