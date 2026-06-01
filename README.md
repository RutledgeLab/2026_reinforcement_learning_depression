# Longitudinal computational phenotyping reveals a stable marker for depression symptoms

## data: data/organizedData (currently only a few example participants)
- **community_remote**: non-depressed participants
- **depression_denseSampling_remote**: depressed participants in dense sampling period
- **depression_monthly_remote**: depressed participants in monthly follow-up period

## code: code/matlab
- **scid_info.mat**: scid information for depressed participants
- **group_combined_behavior_summary**: summarize results and generate figures in the paper
- **run_lap_model_learning_combined_block**: computational model of learning (1st stage: running on each participant)
- **run_hbi_model_learning_combined_block**: computational model of learning (2nd stage: hierarchial fitting based on 1st state estimation)
- **run_lap_model_happiness_rating_combined_block**: computational model of happiness (1st stage: running on each participant)
- **run_hbi_model_happiness_rating_combined_block**: computational model of happiness (2nd stage: hierarchial fitting based on 1st state estimation)
- **model_hbi_RL_XXX**: model files for learning
- **model_hbi_happiness_XXX**: model file for happiness
- **fig_setting_default**: default setting file for figures

## System requirements
- MATLAB (tested on R2020b) (https://www.mathworks.com/)
  - Optimization Toolbox
  - Statistics and Machine Learning Toolbox
  - HBI toolbox (https://doi.org/10.1371/journal.pcbi.1007043) for model fitting

## Instruction for use
### Computational models of learning
Two steps:
1. run_lap_model_learning_combined_block(model_name, version_data)
2. run_hbi_model_learning_combined_block(model_name, version_data)
- model_name: must run "RL_outcome_initSmall_combined" first to generate inverse temperature for the following two models
  - "RL_outcome_initSmall_combined"
  - "RL_outcomeSmall_initSmall_distSmall_combined"
  - "RL_outcomeSmall_initSmall_blockdistSmall"
- version_data:
  - "community_remote"
  - "depression_denseSampling_remote"
  - "depression_monthly_remote"

### Computatoinal models of happiness
Two steps:
1. run_lap_model_happiness_rating_combined_block(model_name, version_data)
2. run_hbi_model_happiness_rating_combined_block(model_name, version_data)
- model_name: must run the learning model "RL_outcomeSmall_initSmall_distSmall_combined" first to generate trial-by-trial V and PE
  - "happy_p_ppe_hbiRL_distSmall_combined"
- version_data:
  - "community_remote"
  - "depression_denseSampling_remote"
  - "depression_monthly_remote"

### Summary and figures
- run "group_combined_behavior_summary" section by section to show the results


