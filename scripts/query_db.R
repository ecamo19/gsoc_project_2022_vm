con <- try(PEcAn.DB::db.open(settings$database$bety))

# on.exit(try(PEcAn.DB::db.close(con), silent = TRUE), add = TRUE)


# Check data available  --------------------------------------------------------
DBI::dbListTables(con)


# Query db ---------------------------------------------------------------------

dplyr::tbl(con, "pfts") %>% 
    filter(modeltype_id == 7)  
    head(.,20)
    # dplyr::filter(.data$site_id == !!settings$run$site$id) %>%
    # dplyr::inner_join(dplyr::tbl(con, "cultivars_pfts"), 
    #                   by = "cultivar_id") %>%
    # 
    # dplyr::inner_join(dplyr::tbl(con, "pfts"), 
    #                   by = c("pft_id" = "id")) %>%
    # dplyr::collect()