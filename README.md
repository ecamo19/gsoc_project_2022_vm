
![Alt text](./gsoc_logo_2.png "Optional title ")

# [Sobol Variance Partitioning Implementation for PEcAn’s uncertainty module](https://summerofcode.withgoogle.com/programs/2022/projects/FzRn47Nh)

## Project description:

Quantifying precisely the degree of uncertainty in models predictions and acknowledging the existing data gaps still remains challenging given the immense variety of data sources that exist and the lack of open source tools that quantify the models' uncertainty. The PEcAn (Predictive Ecosystem global Analyzer) project is an open-source tool that aims to solve this problem by synthesizing multiple data sources for the improvement of model-data feedback. With this tool it is possible to use models for forecasting how an ecosystem might respond to climate change and also is possible to quantify the uncertainty around its predictions. However, currently PEcAn uses a method that do not explore the whole parameter space, giving an incomplete quantification of the uncertainty around important variables in models. Thus, it is necessary to develop new functionalities in PEcAn in order to improve the assessment of ecosystem models' uncertainties. The Sobol Variance Partitioning (SVP) is a method for accessing the degree of uncertainty in models that explore all the parameter space, improving the quantification of model uncertainties. In this project, we will focus on developing a new function within PEcAn that estimates the uncertainty components of a model taking into account higher-order parameter interactions using the SVP method.


## Repo structure

```bash
.
├── notebooks
│   ├── gsoc_first_week_of_work.html
│   ├── gsoc_first_week_of_work.Rmd
│   ├── how_to_run_pecan_rstudio.html
│   └── notebook_functions.Rmd
├── R
│   ├── run_write_configs_original.R
│   ├── sub_function_get_ensemble_samples_original.R
│   ├── sub_function_input_ens_gen_original.R
│   ├── sub_function_read_ensemble_output_original.R
│   └── sub_function_write_ensemble_configs_original.R
├── scripts
│   ├── basic_run.R                     # Generates post.distns.Rdata and prior.distns.Rdata needed in the run.write.configs function
│   ├── run_1.R
│   ├── run_1_tunnel.R
│   ├── run_2.R
│   └── run_2_work.R                    # Test script for running a PEcAn model
└── xml_files
    ├── pecan.CONFIGS_original.xml      # Reference file
    ├── pecan_run_2.xml                 # xml file used in run_2_work.R
    └── simple_biocro.xml               # xml file used in the basic_run.R

4 directories, 17 files

```

## Functions Inputs and Outputs 

__red color = code not running and/or outputs not found__

__blue color = code runs and/or outputs are available__

```mermaid
  graph TD;
      
      simple_biocro.xml-->basic_run.R;
      
      basic_run.R-->run.write.configs;
      basic_run.R-->model;
      
      
      run.write.configs-->output_1[updated settings with ensemble IDs for SA and ensemble analysis ];
      run.write.configs-->posterior.files[post.distns.Rdata or prior.distns.Rdata];
      output_1[updated settings with ensemble IDs for SA and ensemble analysis]-->get.ensemble.samples;
      
      posterior.files[post.distns.Rdata or prior.distns.Rdata]-->get_parameter_samples;
      
      input_get_ensemble_1[pft.samples]-->get.ensemble.samples;
      input_get_ensemble_2[env.samples]-->get.ensemble.samples;
      input_get_ensemble_3[ensemble.size]-->get.ensemble.samples;
      input_get_ensemble_4[param.names]-->get.ensemble.samples;
      
      get_parameter_samples-->input_get_ensemble_1[pft.samples];  
      get_parameter_samples-->input_get_ensemble_2[env.samples];
      get_parameter_samples-->input_get_ensemble_3[ensemble.size];
      get_parameter_samples-->input_get_ensemble_4[param.names];
      
      get.ensemble.samples-->output_get_ensemble[ensemble.samples, matrix of random samples from trait distributions];
      
      output_get_ensemble[ensemble.samples, matrix of random samples from trait distributions]-->write.ensemble.configs;
      model-->write.ensemble.configs;
      simple_biocro.xml-->write.ensemble.configs;
      
      write.ensemble.configs-->output_write_ensemble_1[$runs = data frame of runids];
      write.ensemble.configs-->output_write_ensemble_2[$ensemble.id = the ensemble ID for these runs];
      write.ensemble.configs-->output_write_ensemble_3[$samples with ids and samples used for each tag.];
      write.ensemble.configs-->output_write_ensemble_4[sensitivity analysis configuration files as a side effect];
      
      %% Blue color boxes
      
      style get_parameter_samples fill:#00758f
      style basic_run.R fill:#00758f
      style output_1 fill:#00758f
      style run.write.configs fill:#00758f
      style simple_biocro.xml fill:#00758f
      style posterior.files fill:#00758f
      
      style input_get_ensemble_1 fill:#00758f
      style input_get_ensemble_2 fill:#00758f
      style input_get_ensemble_3 fill:#00758f
      style input_get_ensemble_4 fill:#00758f
      style model fill:#00758f 
      style get.ensemble.samples fill:#00758f
       style output_get_ensemble fill:#00758f 
      
      %% Red color boxes  
      
     
      style write.ensemble.configs fill:#880808
      style output_write_ensemble_1 fill:#880808
      style output_write_ensemble_2 fill:#880808
      style output_write_ensemble_3 fill:#880808
      style output_write_ensemble_4 fill:#880808
      
```

## Code reproducibility

All code is develop by runing it on a virtual machine. This VM can be installed following [this instructions](https://pecanproject.github.io/pecan-documentation/master/install-vm.html#install-vm)







