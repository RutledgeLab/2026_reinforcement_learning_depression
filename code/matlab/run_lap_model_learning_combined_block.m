function run_lap_model_learning_combined_block(model_name, version_data, list_block, subno)

% add path
addpath('../cbm-master/codes');

% versoin_data
if nargin<2
    version_data = '';
end
fprintf('%s\n',version_data);

if nargin<3
    list_block = [];
end

% sublist
sublist = textread(sprintf('sublist_%s', version_data), '%s');
if nargin==4
    sublist = sublist(subno);
end
nSub = numel(sublist);

% amount & prob
win_loss = [30,10];
list_prob = [0.75, 0.25];

% list_block
if isempty(list_block)
    switch version_data
        case {'depression_denseSampling_remote'}
            list_block = [1:7];
        case {'community_remote'}
            list_block = [1:6];
        case {'depression_monthly_remote'}
            list_block = [1:5];

    end
end

% list_block
block_reliability = '';
blockname = sprintf('_block_%d-%d', min(list_block), max(list_block));

nBlock = numel(list_block);

% list_stim
list_stim = [1,2];
nStim = numel(list_stim);

% model_name
model_name_block = sprintf('%s%s', model_name, blockname);
fprintf('<%s>\n', model_name_block);

% directory
dirData = fullfile('../../data/organizedData', version_data);
dirModel = fullfile('../../data/modelData', version_data, 'learning', model_name_block);
mkdir(dirModel);

switch model_name
    case {'lap_RL_outcomeSmall_initSmall_distSmall_combined'
            'lap_RL_outcomeSmall_initSmall_blockdistSmall'}

        ref_model = 'hbi_RL_outcome_initSmall_combined';
        ref_model_block = sprintf('%s%s', ref_model, blockname);

        filename = fullfile('../../data/modelData', version_data,...
            'learning', ref_model_block,...
            sprintf('mle_%s_group', ref_model_block));
        load(filename); % cbm

        param_beta = cbm.model_info.group.parameter(1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% model fitting %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%
for s = 1:nSub

    % subname
    subname = sublist{s};
    fprintf('Processing %d/%d, %s...\n', s, nSub, subname);

    % load data
    filename = sprintf('%s_subjectData_%s.mat', version_data, subname);
    filename = fullfile(dirData, filename);
    load(filename);

    clear model_info data data_subject
    for b = 1:nBlock

        idx_block = list_block(b);
        data{b}.blockno = idx_block;

        % current_task_data
        current_task_data = subjectData.task{idx_block};

        % organize data
        choice = current_task_data.choice;
        outcome = current_task_data.outcome;
        amt_outcome = current_task_data.amt_outcome;
        nTrial_all = numel(choice);

        nTrial = numel(choice);


        % data for model fitting
        trial_outcome = NaN(nTrial, nStim);
        trial_outcome(choice==1,1) = outcome(choice==1);
        trial_outcome(choice==2,2) = outcome(choice==2);
        data{b}.trial_outcome = trial_outcome;

        trial_amt_outcome = NaN(nTrial, nStim);
        trial_amt_outcome(choice==1,1) = amt_outcome(choice==1);
        trial_amt_outcome(choice==2,2) = amt_outcome(choice==2);
        data{b}.trial_amt_outcome = trial_amt_outcome;

        trial_idx_sensitivity = double(outcome==1);
        data{b}.trial_idx_sensitivity = trial_idx_sensitivity;

        trial_idx_senSmall = double(outcome==0);
        data{b}.trial_idx_senSmall = trial_idx_senSmall;

        trial_subject_choice = zeros(nTrial, nStim);
        trial_subject_choice(choice==1,1) = 1;
        trial_subject_choice(choice==2,2) = 1;
        data{b}.trial_subject_choice = trial_subject_choice;

        trial_subject_choice_pre = [[0,0];trial_subject_choice([1:end-1],:)];
        data{b}.trial_subject_choice_pre = trial_subject_choice_pre;

        data{b}.list_stim = list_stim;
        data{b}.trial_pair_stim = repmat(list_stim, nTrial, 1);

        data{b}.win_loss = win_loss;
        data{b}.list_prob = list_prob;


    end % end of block


    data_subject{1} = data;

    %%%%% model fitting %%%%%
    switch model_name
        case {'lap_RL_outcome_initSmall_combined'}

            % parameter info
            nameParameter = {'beta', 'alpha'};
            idx_free = [1, 1];
            param_default = [NaN, NaN];
            nParam = numel(idx_free);
            v = 6.25;
            prior_param = struct('mean', zeros(nParam,1), 'variance', v); % normalized space

            % model
            mleModel = @(x, data) model_hbi_RL_outcome_initSmall_combined (x, data, idx_free, param_default);


        case {'lap_RL_outcomeSmall_initSmall_distSmall_combined'}

            % parameter info
            nameParameter = {'N/A', 'alpha', 'R_dist'};
            idx_free = [0, 1, 1];
            param_default = [param_beta, NaN, NaN];
            nParam = numel(idx_free);
            v = 6.25;
            prior_param = struct('mean', zeros(nParam,1), 'variance', v); % normalized space

            % model
            mleModel = @(x, data) model_hbi_RL_outcome_initSmall_distSmall_combined(x, data, idx_free, param_default);

        case {'lap_RL_outcomeSmall_initSmall_blockdistSmall'}

            % block dist
            block_dist = cell(1,nBlock);
            for b = 1:nBlock
                block_dist{b} = sprintf('Rdist_b%d', list_block(b));
            end

            % parameter info
            nameParameter = ['N/A', 'alpha', block_dist];
            idx_free = [0, 1, ones(1,nBlock)];
            param_default = [param_beta, NaN, NaN(1,nBlock)];
            nParam = numel(idx_free);
            v = 6.25;
            prior_param = struct('mean', zeros(nParam,1), 'variance', v); % normalized space

            % model
            mleModel = @(x, data) model_hbi_RL_outcome_initSmall_blockdistSmall(x, data, idx_free, param_default);

    end % end of model

    % fitting
    cbm = cbm_lap(data_subject, mleModel, prior_param);

    % generate model_var
    x_bestfit = cbm.output.parameters;
    [LL, model_var] = mleModel(x_bestfit, data_subject{1});
    LL_model = LL;

    LL_null = 0;
    nTrial_fitting = 0;
    for b = 1:nBlock
        if ~isnan(model_var{b}.LL_block)
            LL_null = LL_null + log(0.5)*nTrial; % LL of random-choice model
            nTrial_fitting = nTrial_fitting + nTrial;
        end
    end
    pseudo_r2 = 1 - LL_model/LL_null; % McFadden???s R^2

    model_info.LL_model = LL_model;
    model_info.LL_null = LL_null;
    model_info.pseudo_r2 = pseudo_r2;

    % save variable
    model_info.nTrial = nTrial_fitting;
    model_info.nameParameter = nameParameter(idx_free==1);
    model_info.idx_free = idx_free(idx_free==1);
    model_info.nFree = sum(idx_free);

    % transform the parameters back
    clear param_real
    param_real = x_bestfit;
    switch model_name
        case {'lap_RL_outcome_initSmall_combined'}

            % beta
            param_real(1) = exp(x_bestfit(1));
            param_real(1) = param_real(1) + 0.001;

            % alpha
            param_real(2) = 1./(1+exp(-x_bestfit(2)));
            param_real(2) = param_real(2)*(1-0.001) + 0.001;

        case {'lap_RL_outcomeSmall_initSmall_distSmall_combined'}

            param_real(1) = exp(x_bestfit(1));
            param_real(1) = param_real(1) + 0.001;

            param_real(2) = 1./(1+exp(-x_bestfit(2)));
            param_real(2) = param_real(2)*(1-0.001) + 0.001;

            param_real(3) = exp(x_bestfit(3));
            param_real(3) = param_real(3) + 0.001;
            param_real(3) = -1*param_real(3);

        case {'lap_RL_outcomeSmall_initSmall_blockdistSmall'}
            param_real(1) = exp(x_bestfit(1));
            param_real(1) = param_real(1) + 0.001;

            param_real(2) = 1./(1+exp(-x_bestfit(2)));
            param_real(2) = param_real(2)*(1-0.001) + 0.001;

            param_real(3:end) = exp(x_bestfit(3:end));
            param_real(3:end) = param_real(3:end) + 0.001;
            param_real(3:end) = -1*param_real(3:end);

            for b = 1:nBlock

                if sum(data{b}.trial_subject_choice(:))==0
                    param_real(2+b) = NaN;
                end

            end


    end
    model_info.parameter = param_real(idx_free==1);

    model_info.model_var = model_var;
    model_info.list_block = list_block;

    cbm.model_info = model_info;

    % output
    fittingFile = fullfile(dirModel, sprintf('mle_%s_%s', model_name_block, subname));
    save(fittingFile,'cbm');

end % end of subject






