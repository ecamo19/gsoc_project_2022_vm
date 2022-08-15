#' Function for generating samples based on sampling method, parent or etc
#'
#' @param settings list of PEcAn settings
#' @param method Method for sampling - For now looping or sampling with replacement is implemented
#' @param parent_ids This is basically the order of the paths that the parent is sampled.See Details.
#'
#' @return For a given input/tag in the pecan xml and a method, this function returns a list with $id showing the order of sampling and $samples with samples of that input.
#' @details If for example met was a parent and it's sampling method resulted in choosing the first, third and fourth samples, these are the ids that need to be sent as
#' parent_ids to this function.
#' @export
#'
#' @examples
#' \dontrun{input.ens.gen(settings,"met","sampling")}
#'
input.ens.gen <- function(settings, input, method = "sampling", parent_ids = NULL) {
  
  #-- reading the dots and exposing them to the inside of the function
  samples <- list()
  samples$ids <- c()
  #
  if (is.null(method)) return(NULL)
  # parameter is exceptional it needs to be handled spearatly
  if (input == "parameters") return(NULL)
  
  #-- assing the sample ids based on different scenarios
  input_path <- settings$run$inputs[[tolower(input)]]$path
  if (!is.null(parent_ids)) {
    samples$ids <- parent_ids$ids
    out.of.sample.size <- length(samples$ids[samples$ids > length(input_path)])
    #sample for those that our outside the param size - forexample, parent id may send id number 200 but we have only100 sample for param
    samples$ids[samples$ids %in% out.of.sample.size] <- sample(
      seq_along(input_path),
      out.of.sample.size,
      replace = TRUE)
  } else if (tolower(method) == "sampling") {
    samples$ids <- sample(
      seq_along(input_path),
      settings$ensemble$size,
      replace = TRUE)
  } else if (tolower(method) == "looping") {
    samples$ids <- rep_len(
      seq_along(input_path),
      length.out = settings$ensemble$size)
  }
  #using the sample ids
  samples$samples <- input_path[samples$ids]
  
  return(samples)
}