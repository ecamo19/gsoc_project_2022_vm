
##' Reads output from model ensemble
##'
##' Reads output for an ensemble of length specified by \code{ensemble.size} and bounded by \code{start.year} 
##' and \code{end.year}
##' @title Read ensemble output
##' @return a list of ensemble model output 
##' @param ensemble.size the number of ensemble members run
##' @param pecandir specifies where pecan writes its configuration files
##' @param outdir directory with model output to use in ensemble analysis
##' @param start.year first year to include in ensemble analysis
##' @param end.year last year to include in ensemble analysis
##' @param variable target variables for ensemble analysis
##' @param ens.run.ids dataframe. Must contain a column named "id" giving the run IDs to be read.
##'   If NULL, will attempt to read IDs from a file named "samples.Rdata" in \code{pecandir}
##' @export
##' @author Ryan Kelly, David LeBauer, Rob Kooper
#--------------------------------------------------------------------------------------------------#
read.ensemble.output <- function(ensemble.size, pecandir, outdir, start.year, end.year, 
                                 variable, ens.run.ids = NULL) {
    if (is.null(ens.run.ids)) {
        samples.file <- file.path(pecandir, "samples.Rdata")
        if (file.exists(samples.file)) {
            load(samples.file)
            ens.run.ids <- runs.samples$ensemble
        } else {
            stop(samples.file, "not found required by read.ensemble.output")
        }
    }
    
    expr <- variable$expression
    variables <- variable$variables
    
    ensemble.output <- list()
    for (row in rownames(ens.run.ids)) {
        run.id <- ens.run.ids[row, "id"]
        PEcAn.logger::logger.info("reading ensemble output from run id: ", format(run.id, scientific = FALSE))
        
        for(var in seq_along(variables)){
            out.tmp <- PEcAn.utils::read.output(run.id, file.path(outdir, run.id), start.year, end.year, variables[var])
            assign(variables[var], out.tmp[[variables[var]]])
        }
        
        # derivation
        out <- eval(parse(text = expr))
        
        ensemble.output[[row]] <- mean(out, na.rm= TRUE) 
        
    }
    return(ensemble.output)
} # read.ensemble.output