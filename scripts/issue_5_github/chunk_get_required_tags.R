
if(!is.null(con)){
  
  required_tags <- dplyr::tbl(con, 'models') %>%
    dplyr::filter(.data$id == !!as.numeric(settings$model$id)) %>%
    
    dplyr::inner_join(dplyr::tbl(con, "modeltypes_formats"), 
                      by = c('modeltype_id')) %>%
    
    dplyr::collect() %>%
    
    dplyr::filter(.data$required == TRUE) %>%
    dplyr::pull(.data$tag)
  
  # Get input tags specified in the <input></input> xml file 
  if(length(names(settings$run$inputs)) > 0){
    
      input_tags <-  c(names(settings$run$inputs))} 
  
      # Combine required_tags and input_tags  
      required_tags <- union(required_tags,input_tags)
      
      } else{
        
        required_tags <- c("met","parameters")
      }




# This code works by modifying the PEcAn.CONFIG --------------------------------

#required_tags_test <- names(settings$run$inputs)

required_tags %>%
  
  purrr::walk(function(r_tag){
    
    # if 6
    if (is.null(samples[[r_tag]]) & r_tag!="parameters"){ 
      
      samples[[r_tag]]$samples <<- rep(settings$run$inputs[[tolower(r_tag)]]$path, 
                                       settings$ensemble$size)
      
      }
    cat(blue(paste0("\n if 6 ran \n ")))
  })

print(samples)



# # This code works by modifying the PEcAn.CONFIG ------------------------------
# required_tags_test <- names(settings$run$inputs)
# required_tags_test
# class(required_tags_test)
# samples <- list()
# samples
# 
# for(each_tag in required_tags_test){
# 
#   samples[[each_tag]]$samples <- rep(settings$run$inputs[[tolower(each_tag)]]$path, 
#                                    settings$ensemble$size)
# }              
# samples
# settings$run$inputs
# settings$run$inputs$veg$path2
# 


