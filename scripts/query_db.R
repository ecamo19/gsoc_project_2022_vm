# Load settings  ---------------------------------------------------------------
source("./scripts/load_configs_settings.R")


# Connect to db ----------------------------------------------------------------

con <- try(PEcAn.DB::db.open(settings$database$bety))

# on.exit(try(PEcAn.DB::db.close(con), silent = TRUE), add = TRUE)

# Check data available  --------------------------------------------------------
DBI::dbListTables(con)


# Query db ---------------------------------------------------------------------

dplyr::tbl(con, "sites") 
    print(n = 10)


dplyr::tbl(con, "inputs_runs") %>% 
    print(n = 100)
    arrange()
    dplyr::select(name) %>% 
    head(11)
    
    select(city,state)
    
dplyr::tbl(con, 'sites') %>% 
    dplyr::filter(id == 1118) 
    
    dplyr::inner_join(dplyr::tbl(con, "modeltypes_formats"), 
                      by = c('modeltype_id')) 
    
    dplyr::collect() %>%
    
    dplyr::filter(.data$required == TRUE) %>%
    dplyr::pull(.data$tag) 


dplyr::tbl(con, "models")   %>% 
    filter(model_name == "BioCro")  
    head(.,20)
    # dplyr::filter(.data$site_id == !!settings$run$site$id) %>%
    # dplyr::inner_join(dplyr::tbl(con, "cultivars_pfts"), 
    #                   by = "cultivar_id") %>%
    # 
    # dplyr::inner_join(dplyr::tbl(con, "pfts"), 
    #                   by = c("pft_id" = "id")) %>%
    # dplyr::collect()