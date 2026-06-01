# Longitudinal computational phenotyping reveals a stable marker for depression symptoms

## data
## data/organizedData (currently only a few example participants)
- community_remote: non-depressed participants
- depression_denseSampling_remote: depressed participants in dense sampling period
- depression_monthly_remote: depressed participants in monthly follow-up period

## code
## code/matlab
- scid_info.mat: scid information for depressed participants
- group_combined_behavior_summary.m: summarize results and generate figures in the paper
- run_lap_model_learning_combined_block.m: computational model of learning (1st stage: running on each participant)
- run_hbi_model_learning_combined_block.m: computational model of learning (2nd stage: hierarchial fitting based on 1st state estimation)
- run_lap_model_happiness_rating_combined_block.m: computational model of happiness (1st stage: running on each participant)
- run_hbi_model_happiness_rating_combined_block.m: computational model of happiness (2nd stage: hierarchial fitting based on 1st state estimation)
- model_hbi_RL_XXX: model files for learning
- model_hbi_happiness_XXX: model file for happiness
- fig_setting_default.m: default setting file for figures

## modeling
Models were fitted through HBI toolbox (https://doi.org/10.1371/journal.pcbi.1007043).
