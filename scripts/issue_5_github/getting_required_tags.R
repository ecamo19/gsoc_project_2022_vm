


if(!is.null(con)){
  
  required_tags <- dplyr::tbl(con, 'models') %>%
    dplyr::filter(.data$id == !!as.numeric(settings$model$id)) %>%
    
    dplyr::inner_join(dplyr::tbl(con, "modeltypes_formats"), 
                      by = c('modeltype_id')) %>%
    
    dplyr::collect() %>%
    
    dplyr::filter(.data$required == TRUE) %>%
    dplyr::pull(.data$tag)
  
  # Get input tags specified in the xml file 
  if(length(names(settings$run$inputs)) > 0){
    
      input_tags <-  c(names(settings$run$inputs))} 
  
      # Combine required_tags and input_tags  
      required_tags <- union(required_tags,input_tags)} else{
        
        required_tags <- c("met","parameters")}
  