function [LL, model_var] = model_hbi_RL_outcome_initSmall_blockdistSmall(param, data, idx_free, param_default, isSim)

if nargin<5
    isSim = 0;
end

nBlock = numel(data);

% parameter
idx_param = 0;
idx_param = idx_param + 1;
if idx_free(idx_param)==1
    nd_beta  = param(idx_param);
    beta    = exp(nd_beta);
    beta    = beta + 0.001; % [0.001, inf]
else
    beta = param_default(idx_param);
end

idx_param = idx_param + 1;
if idx_free(idx_param)==1
    nd_alpha  = param(idx_param); % normally-distributed alpha
    alpha     = 1/(1+exp(-nd_alpha)); % alpha (transformed to be between zero and one)
    alpha     = (alpha*(1-0.001)) + 0.001; % [0.001, 1]
else
    alpha = param_default(idx_param);
end

dist_block = NaN(1,nBlock);
for b = 1:nBlock
    idx_param = idx_param + 1;
    if idx_free(idx_param)==1
        nd_R_dist  = param(idx_param);
        R_dist    = exp(nd_R_dist);
        R_dist    = R_dist + 0.001; % [0.001, inf]
        R_dist    = -1*R_dist;
    else
        R_dist = param_default(idx_param);
    end
    dist_block(b) = R_dist;
end


LL = 0;
for b = 1:nBlock
    
    R_dist = dist_block(b);
    
    %%%%% outcome %%%%%
    large_reward = max(data{b}.win_loss);
    small_reward = min(data{b}.win_loss);
    
    trial_outcome = data{b}.trial_amt_outcome;
    
    idx_small = (trial_outcome==small_reward);
    trial_outcome(idx_small) = large_reward + R_dist;
    
    small_sv = large_reward + R_dist;
    
    nTrial_total = size(trial_outcome,1);
    
    trial_subject_choice = data{b}.trial_subject_choice;
    trial_pair_stim = data{b}.trial_pair_stim;
    list_stim = data{b}.list_stim;
    nStim = numel(list_stim);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% model simulation %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    stim_ev = ones(1, nStim)*small_sv;
    trial_ev = NaN(nTrial_total, nStim);
    trial_pe = NaN(nTrial_total, 1);
    trial_p_choice = zeros(nTrial_total, 2);
    trial_model_choice = zeros(nTrial_total, 2);
    
    if sum(trial_subject_choice(:))==0
        
        model_var{b} = data{b};
        model_var{b}.LL_block = NaN;
        model_var{b}.stim_ev = stim_ev;
        model_var{b}.trial_ev = trial_ev;
        model_var{b}.trial_pe = trial_pe;
        model_var{b}.trial_p_choice = trial_p_choice;
        model_var{b}.trial_model_choice = trial_model_choice;
        
        continue
    end
    
    for t = 1:nTrial_total
        
        idx_stim_1 = (list_stim==trial_pair_stim(t,1));
        idx_stim_2 = (list_stim==trial_pair_stim(t,2));
        
        trial_ev(t,idx_stim_1) = stim_ev(1,idx_stim_1);
        trial_ev(t,idx_stim_2) = stim_ev(1,idx_stim_2);
        
        ev_1 = stim_ev(1, idx_stim_1);
        ev_2 = stim_ev(1, idx_stim_2);
        
        % p_choice
        p_choice_1 = 1./(1+exp(-beta*(ev_1-ev_2)));
        p_choice_2 = 1-p_choice_1;
        trial_p_choice(t,:) = [p_choice_1, p_choice_2];
        
        
        % generate choice
        prob_rand = rand(1);
        if prob_rand<p_choice_1
            idx_choice = 1;
        else
            idx_choice = 2;
        end
        trial_model_choice(t,idx_choice) = 1;
        
        % use subject_choice or model_choice
        if isSim==1
            current_choice = find(trial_model_choice(t,:)==1);
        elseif isSim==0
            current_choice = find(trial_subject_choice(t,:)==1);
        end
        
        % outcome
        outcome = trial_outcome(t,current_choice);
        
        % PE & update
        if ~isnan(outcome)
            
            if current_choice==1
                current_ev = ev_1;
            elseif current_choice==2
                current_ev = ev_2;
            end
            PE = outcome - current_ev;
            trial_pe(t,1) = PE;
            update = alpha*PE;
            
            if t<nTrial_total
                if current_choice==1
                    stim_ev(1,idx_stim_1) = stim_ev(1,idx_stim_1) + update;
                elseif current_choice==2
                    stim_ev(1,idx_stim_2) = stim_ev(1,idx_stim_2) + update;
                end
            end
            
        end
        
    end
    
    % log-likelihood
    trial_p_choice(trial_p_choice==0) = eps;
    trial_p_choice(trial_p_choice==1) = 1-eps;
    if isSim==1
        LL_block = sum(sum(log(trial_p_choice).*trial_model_choice));
    elseif isSim==0
        LL_block = sum(sum(log(trial_p_choice).*trial_subject_choice));
    end
    LL = LL + LL_block;
    
    % model_var
    model_var{b} = data{b};
    model_var{b}.LL_block = LL_block;
    model_var{b}.stim_ev = stim_ev;
    model_var{b}.trial_ev = trial_ev;
    model_var{b}.trial_pe = trial_pe;
    model_var{b}.trial_p_choice = trial_p_choice;
    model_var{b}.trial_model_choice = trial_model_choice;
    
end



