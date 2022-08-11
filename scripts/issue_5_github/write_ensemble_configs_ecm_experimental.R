# Function's original information ----------------------------------------------
# 
# Writes config files for use in meta-analysis and returns a list of run ids.
# Given a pft.xml object, a list of lists as supplied by get.sa.samples, 
# a name to distinguish the output files, and the directory to place the files.
#
# param defaults pft
# 
# param ensemble.samples list of lists supplied by \link{get.ensemble.samples}
# 
# param settings list of PEcAn settings
# 
# param model name of model to be run, e.g. "ED2" or "SIPNET"
# 
# param clean remove old output first?
# 
# param write.to.db logical: Record this run in BETY?
# 

# @return list, containing $runs = data frame of runids, $ensemble.id = the 
# ensemble ID for these runs and $samples with ids and samples used for each tag.
# Also writes sensitivity analysis configuration files as a side effect


# Function's parameters --------------------------------------------------------
#write.ensemble.configs <- function(defaults, ensemble.samples, settings, model, 
#                                   clean = FALSE, write.to.db = TRUE,
#                                   restart=NULL) {

rm(list = ls())

# Working directory ------------------------------------------------------------
setwd('/home/carya')
getwd()

# 
options(scipen=999)

# Load packages ----------------------------------------------------------------
library(rlang)
library(dplyr)
library(PEcAn.all)
library(BioCro)
library(crayon)

# Load setting and data --------------------------------------------------------
source("~/gsoc_project_2022/scripts/issue_5_github/get_ensemble_samples_ecm.R")
source("~/gsoc_project_2022/scripts/load_configs_settings.R")
source("~/gsoc_project_2022/R/write.config.BIOCRO.R")

# Not sure if these are necessary 
load("./pecan_runs/pecan_run_salix/samples.Rdata")
load("./pecan_runs/pecan_run_salix/pft/salix/trait.data.Rdata")
load("./pecan_runs/pecan_run_salix/pft/salix/trait.mcmc.Rdata")

# Test original function -------------------------------------------------------
# PEcAn.uncertainty::write.ensemble.configs(defaults = settings$pfts,
#                                           ensemble.samples = ensemble.samples,
#                                           settings = settings,
#                                           model = settings$model)


# Specifying parameters --------------------------------------------------------
defaults <- settings$pfts

model <- settings$model$type

ensemble.samples

settings$run

clean <-  FALSE 

restart <- NULL

# First: General configuration, db, get workflow id ----------------------------

con <- NULL
my.write.config <- paste("write.config.", model, sep = "")
#my.write_restart <- paste0("write_restart.", model)

# If 1
if (is.null(ensemble.samples)) {
    cat(blue(paste0("\n if 1 ran \n ")))
    return(list(runs = NULL, ensemble.id = NULL))
}

## See if we need to write to DB -----------------------------------------------
write.to.db <- as.logical(settings$database$bety$write)

# If 2
if(write.to.db){
    
    cat(blue(paste0("\n if 2 ran\n ")))
    
    # Open connection to database so we can store all run/ensemble information
    con <-
        try(PEcAn.DB::db.open(settings$database$bety))
    on.exit(try(PEcAn.DB::db.close(con), silent = TRUE), add = TRUE)
    
    # If we fail to connect to DB then we set to NULL
    if (inherits(con, "try-error"))  {
        con <- NULL
        PEcAn.logger::logger.warn("We were not able to successfully 
                                  establish a connection with Bety ")
    }
}

## Get the workflow id ---------------------------------------------------------

# If 3 
if (!is.null(settings$workflow$id)) {
    
    cat(blue(paste0("\n if 3 ran \n ")))
    workflow.id <- settings$workflow$id
    print(workflow.id)
    
} else {
    workflow.id <- -1
}


# Second: Generating ensembles ------------------------------------------------- 

# met/param/soil/veg/... for all ensambles  

## If this is a new fresh run --------------------------------------------------

### Get ensemble.id -------------------------------------------------------------

if (is.null(restart)){
    
    # If 4
    
    # create an ensemble id
    if(!is.null(con) && write.to.db){
        
        cat(blue(paste0("\n if 4 ran \n ")))
        
        # write ensemble first
        ensemble.id <- PEcAn.DB::db.query(paste0(
            "INSERT INTO ensembles (runtype, workflow_id) ",
            "VALUES ('ensemble', ", format(workflow.id, scientific = FALSE), ")",
            "RETURNING id"), con = con)[['id']]
        
        for (pft in defaults) {
            PEcAn.DB::db.query(paste0(
                "INSERT INTO posteriors_ensembles (posterior_id, ensemble_id) ",
                "values (", pft$posteriorid, ", ", ensemble.id, ")"), con = con) }
        
    } else {
        ensemble.id <- NA
    }
    
    ### Tags required the model ------------------------------------------------
    # Lets first find out what tags are required for this model
    
    # If 5: get the tags that the model MUST have 
    if (!is.null(con)){
        cat(blue(paste0("\n if 5 ran \n ")))
        
        required_tags <- dplyr::tbl(con, 'models') %>%
            dplyr::filter(.data$id == !!as.numeric(settings$model$id)) %>%
            
            dplyr::inner_join(dplyr::tbl(con, "modeltypes_formats"), 
                              by = c('modeltype_id')) %>%
            
            dplyr::collect() %>%
            
            dplyr::filter(.data$required == TRUE) %>%
            dplyr::pull(.data$tag)
        
    } else {
        
        required_tags <- c("met","parameters")
        
    }
    
    # now looking into the xml
    samp <- settings$ensemble$samplingspace
    
    # finding who has a parent
    parents <- lapply(samp,'[[', 'parent')
    
    # order parents based on the need of who has to be first
    order <- names(samp)[lapply(parents, function(tr) which(names(samp) %in% tr)) 
                         %>% unlist()] 
    
    # new ordered sampling space
    samp.ordered <- samp[c(order, names(samp)[!(names(samp) %in% order)])]
    
    # performing the sampling
    samples <- list()
    
    # for 1 run $met$ids here
    for(i in seq_along(samp.ordered)){
        
        # do I have a parent ?
        myparent <- samp.ordered[[i]]$parent 
        
        # call the function responsible for generating the ensemble
        samples[[names(samp.ordered[i])]] <- input.ens.gen(settings = settings,
                                                           input = names(samp.ordered)[i],
                                                           method = samp.ordered[[i]]$method,
                                                           
                                                           # if I have parent then give me their ids - this is 
                                                           # where the ordering matters making sure the parent 
                                                           # is done before it's asked
                                                           parent_ids = if(!is.null(myparent)) samples[[myparent]] 
                                                           
        )
        print(samples) # delete
        cat(blue(paste0("\n For 1 ran \n ")))
    } 
    
    # if there is a tag required by the model but it is not specified in the xml 
    # then I replicate n times the first element 
    
    required_tags %>%
        
        purrr::walk(function(r_tag){
            
            # if 6
            if (is.null(samples[[r_tag]]) & r_tag!="parameters") 
                
                samples[[r_tag]]$samples <<- rep(settings$run$inputs[[tolower(r_tag)]]$path[1], 
                                                 settings$ensemble$size)
            cat(blue(paste0("\n if 6 ran \n ")))
        })
    
    # Reading the site.pft specific tags from xml
    # Returns character(0)
    
    # HERE defined.pfts site.pfts.vec but dont consider the character(0)
    # 
    site.pfts.vec <- settings$run$site$site.pft %>% unlist %>% as.character
    
    # If 7
    if (!is.null(site.pfts.vec)) {
        
        # find the name of pfts defined in the body of pecan.xml
        defined.pfts <-
            settings$pfts %>% purrr::map('name') %>% unlist %>% as.character
        
        # subset ensemble samples based on the pfts that are specified in the 
        # site and they are also sampled from.
        cat(blue(paste0("\n if 7 ran \n ")))
        
        # If 8
        if(length(which(site.pfts.vec %in% defined.pfts)) > 0){
            ensemble.samples <-
                ensemble.samples[site.pfts.vec[which(site.pfts.vec %in% defined.pfts)]]
            
            cat(blue(paste0("\n if 8 ran \n ")))
        }
        
        # If 9
        # warn if there is a pft specified in the site but it's not defined in the pecan xml.
        if(length(which(!(site.pfts.vec %in% defined.pfts))) > 0){
            PEcAn.logger::logger.warn(
                paste0(
                    "The following pfts are specified for the siteid ",
                    settings$run$site$id ,
                    
                    " but they are not defined as a pft in pecan.xml:",
                    site.pfts.vec[which(!(site.pfts.vec %in% defined.pfts))],
                    collapse = ",")
            )
            
            cat(blue(paste0("\n if 9 ran \n ")))
        }
    }
    
    # If 10
    # if no ensemble piece was in the xml I replicate n times the first element in params
    if (is.null(samp$parameters)){            
        samples$parameters$samples <- ensemble.samples %>% 
            purrr::map(~.x[rep(1, settings$ensemble$size), ])
        
        cat(blue(paste0("\n if 10 ran \n ")))
    }
    
    # This where we handle the parameters - ensemble.samples is already 
    # generated in run.write.config and it's sent to this function as arg - 
    
    # If 11
    if(is.null(samples$parameters$samples)){ 
        samples$parameters$samples <- ensemble.samples
        
        cat(blue(paste0("\n if 11 ran \n ")))
    }
    
    
    # Third: -------------------------------------------------------------------
    # find all inputs that have an id
    inputs <- names(settings$run$inputs)
    
    # met id? # This step is necessary
    inputs <- inputs[grepl(".id$", inputs)]
    runs <- data.frame()
    
    for (i in seq_len(settings$ensemble$size)) {
        
        if (!is.null(con) && write.to.db) {
            
            paramlist <- paste("ensemble=", i, sep = "")
            
            # inserting this into the table and getting an id back
            run.id <- PEcAn.DB::db.query(paste0(
                
                "INSERT INTO runs (model_id, site_id, start_time, finish_time, outdir, ensemble_id, parameter_list) ",
                "values ('", 
                settings$model$id, "', '", 
                settings$run$site$id, "', '", 
                settings$run$start.date, "', '", 
                settings$run$end.date, "', '", 
                settings$run$outdir, "', ", 
                ensemble.id, ", '", 
                paramlist, "') ",
                "RETURNING id"), con = con)[['id']]
            # associate inputs with runs
            
            if(!is.null(inputs)) {
                for (x in inputs) {
                    PEcAn.DB::db.query(paste0("INSERT INTO inputs_runs (input_id, run_id) ",
                                              "values (", settings$run$inputs[[x]], ", ", run.id, ")"), 
                                       con = con)
                }
            }
            
        } else{
            run.id <- PEcAn.utils::get.run.id("ENS", PEcAn.utils::left.pad.zeros(1, 5), 
                                              site.id = settings$run$site$id)
        }
        runs[i, "id"] <- run.id    
        
        # create folders (cleaning up old ones if needed)
        if (clean) {
            unlink(file.path(settings$rundir, run.id))
            unlink(file.path(settings$modeloutdir, run.id))
        }
        
        dir.create(file.path(settings$rundir, run.id), recursive = TRUE)
        dir.create(file.path(settings$modeloutdir, run.id), recursive = TRUE)
        
        # write run information to disk (README.txt inside each folder)
        cat("runtype     : ensemble\n",
            "workflow id : ", format(workflow.id, scientific = FALSE), "\n",
            "ensemble id : ", format(ensemble.id, scientific = FALSE), "\n",
            "run         : ", i, "/", settings$ensemble$size, "\n",
            "run id      : ", format(run.id, scientific = FALSE), "\n",
            "pft names   : ", as.character(lapply(settings$pfts, function(x) x[["name"]])), "\n",
            "model       : ", model, "\n",
            "model id    : ", format(settings$model$id, scientific = FALSE), "\n",
            "site        : ", settings$run$site$name, "\n",
            "site  id    : ", format(settings$run$site$id, scientific = FALSE), "\n",
            "met data    : ", samples$met$samples[[i]], "\n",
            "start date  : ", settings$run$start.date, "\n",
            "end date    : ", settings$run$end.date, "\n",
            "hostname    : ", settings$host$name, "\n",
            "rundir      : ", file.path(settings$host$rundir, run.id), "\n",
            "outdir      : ", file.path(settings$host$outdir, run.id), "\n",
            file = file.path(settings$rundir, run.id, "README.txt"))
        
        # changing the structure of input tag to what the 
        # models are expecting
        for(input_i in seq_along(settings$run$inputs)){
            
            input_tag <- names(settings$run$inputs)[[input_i]]
            
            if (!is.null(samples[[input_tag]]))
                settings$run$inputs[[input_tag]][["path"]] <-
                    samples[[input_tag]][["samples"]][[i]]
        }
        
        #Error in write.config.BIOCRO(defaults = list(pft = list(name = "salix",  : 
        #                                                            could not find function "write.config.BIOCRO"
        
        do.call(my.write.config, args = list(defaults = defaults, 
                                             trait.values = lapply(samples$parameters$samples, 
                                                                   function(x, n) { x[n, , drop=FALSE] }, n=i), # this is the params
                                             settings = settings, 
                                             run.id = run.id))
        cat(format(run.id, scientific = FALSE), file = file.path(settings$rundir, "test_runs.txt"), sep = "\n", append = TRUE)
        
    }
    #return(invisible(
    list(runs = runs, ensemble.id = ensemble.id, samples = samples)
    #))
} 