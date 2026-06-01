function run_hbi_model_learning_combined_block(model_name, version_data, list_block)

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
nSub = numel(sublist);

% end
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

%%%%% aggregate %%%%%
% models for individuals
model_lap_block = ['lap', model_name_block(4:end)];
dirModel_lap = fullfile('../../data/modelData', version_data, 'learning', model_lap_block);
fcbm_lap = fullfile(dirModel_lap, sprintf('mle_%s_group.mat', model_lap_block));

fname_subjects = cell(nSub,1);
for s = 1:nSub
    subname = sublist{s};
    fname_subjects{s} = fullfile(dirModel_lap, sprintf('mle_%s_%s.mat', model_lap_block, subname));
end
cbm_lap_aggregate(fname_subjects, fcbm_lap);


% load beta
switch model_name
    case {'hbi_RL_outcomeSmall_initSmall_distSmall_combined';
            'hbi_RL_outcomeSmall_initSmall_blockdistSmall'}

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
clear data_subject model_info
for s = 1:nSub

    % subname
    subname = sublist{s};

    % load data
    filename = sprintf('%s_subjectData_%s.mat', version_data, subname);
    filename = fullfile(dirData, filename);
    load(filename);

    clear data
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

    data_subject{s} = data;

end % end of subject

%%%%% model fitting %%%%%
switch model_name
    case {'hbi_RL_outcome_initSmall_combined'}

        % parameter info
        nameParameter = {'beta', 'alpha'};
        idx_free = [1, 1];
        param_default = [NaN, NaN];

        % model
        mleModel = @(x, data) model_hbi_RL_outcome_initSmall_combined (x, data, idx_free, param_default);

    case {'hbi_RL_outcomeSmall_initSmall_distSmall_combined'}

        % parameter info
        nameParameter = {'N/A', 'alpha', 'R_dist'};
        idx_free = [0, 1, 1];
        param_default = [param_beta, NaN, NaN];

        % model
        mleModel = @(x, data) model_hbi_RL_outcome_initSmall_distSmall_combined(x, data, idx_free, param_default);

    case {'hbi_RL_outcomeSmall_initSmall_blockdistSmall'}

        % block dist
        block_dist = cell(1,nBlock);
        for b = 1:nBlock
            block_dist{b} = sprintf('Rdist_b%d', list_block(b));
        end

        % parameter info
        nameParameter = ['N/A', 'alpha', block_dist];
        idx_free = [0, 1, ones(1,nBlock)];
        param_default = [param_beta, NaN, NaN(1,nBlock)];

        % model
        mleModel = @(x, data) model_hbi_RL_outcome_initSmall_blockdistSmall(x, data, idx_free, param_default);

end % end of model

% fitting
cbm = cbm_hbi(data_subject, {mleModel}, {fcbm_lap});

% generate model_var
model_info.sublist = sublist;
model_info.nSub = nSub;
model_info.nameParameter = nameParameter(idx_free==1);
model_info.idx_free = idx_free(idx_free==1);
model_info.nFree = sum(idx_free);
model_info.list_block = list_block;


model_info.nTrial_per_subject = NaN(nSub,1);
for s = 1:nSub
    filename = fname_subjects{s};
    subject_fit = load(filename); % subject_fit.cbm
    model_info.nTrial_per_subject(s,1) = subject_fit.cbm.model_info.nTrial;

end

% transform the parameters back
switch model_name
    case {'hbi_RL_outcome_initSmall_combined'}

        % group
        x_bestfit = cbm.output.group_mean{1};
        for s = 1:nSub
            [LL, model_var] = mleModel(x_bestfit, data_subject{s});
            LL_model = LL;

            LL_null = 0;
            for b = 1:nBlock
                if ~isnan(model_var{b}.LL_block)
                    LL_null = LL_null + log(0.5)*nTrial; % LL of random-choice model
                end
            end
            pseudo_r2 = 1 - LL_model/LL_null; % McFadden???s R^2

            model_info.group.LL_model(s,1) = LL_model;
            model_info.group.LL_null(s,1) = LL_null;
            model_info.group.pseudo_r2(s,1) = pseudo_r2;
            model_info.group.model_var{s,1} = model_var;
        end

        clear param_real
        param_real = x_bestfit;

        % beta
        param_real(1) = exp(x_bestfit(1));
        param_real(1) = param_real(1) + 0.001;

        % alpha
        param_real(2) = 1./(1+exp(-x_bestfit(2)));
        param_real(2) = param_real(2)*(1-0.001) + 0.001;

        model_info.group.parameter = param_real(idx_free==1);

        % subject
        x_bestfit = cbm.output.parameters{1};
        for s = 1:nSub
            [LL, model_var] = mleModel(x_bestfit(s,:), data_subject{s});
            LL_model = LL;

            LL_null = 0;
            for b = 1:nBlock
                if ~isnan(model_var{b}.LL_block)
                    LL_null = LL_null + log(0.5)*nTrial; % LL of random-choice model
                end
            end
            pseudo_r2 = 1 - LL_model/LL_null; % McFadden???s R^2

            model_info.subject.LL_model(s,1) = LL_model;
            model_info.subject.LL_null(s,1) = LL_null;
            model_info.subject.pseudo_r2(s,1) = pseudo_r2;
            model_info.subject.model_var{s,1} = model_var;
        end

        clear param_real
        param_real = x_bestfit;

        % beta
        param_real(:,1) = exp(x_bestfit(:,1));
        param_real(:,1) = param_real(:,1) + 0.001;

        % alpha
        param_real(:,2) = 1./(1+exp(-x_bestfit(:,2)));
        param_real(:,2) = (param_real(:,2)*(1-0.001)) + 0.001;

        model_info.subject.parameter = param_real(:,idx_free==1);

    case {'hbi_RL_outcomeSmall_initSmall_distSmall_combined'}

        % group
        x_bestfit = cbm.output.group_mean{1};
        for s = 1:nSub
            [LL, model_var] = mleModel(x_bestfit, data_subject{s});
            LL_model = LL;

            LL_null = 0;
            for b = 1:nBlock
                if ~isnan(model_var{b}.LL_block)
                    LL_null = LL_null + log(0.5)*nTrial; % LL of random-choice model
                end
            end
            pseudo_r2 = 1 - LL_model/LL_null; % McFadden???s R^2

            model_info.group.LL_model(s,1) = LL_model;
            model_info.group.LL_null(s,1) = LL_null;
            model_info.group.pseudo_r2(s,1) = pseudo_r2;
            model_info.group.model_var{s,1} = model_var;
        end

        clear param_real
        param_real = x_bestfit;
        param_real(1) = exp(x_bestfit(1));
        param_real(1) = param_real(1) + 0.001;

        param_real(2) = 1./(1+exp(-x_bestfit(2)));
        param_real(2) = param_real(2)*(1-0.001) + 0.001;

        param_real(3) = exp(x_bestfit(3));
        param_real(3) = param_real(3) + 0.001;
        param_real(3) = -1*param_real(3);

        model_info.group.parameter = param_real(idx_free==1);

        % subject
        x_bestfit = cbm.output.parameters{1};
        for s = 1:nSub
            [LL, model_var] = mleModel(x_bestfit(s,:), data_subject{s});
            LL_model = LL;

            LL_null = 0;
            for b = 1:nBlock
                if ~isnan(model_var{b}.LL_block)
                    LL_null = LL_null + log(0.5)*nTrial; % LL of random-choice model
                end
            end
            pseudo_r2 = 1 - LL_model/LL_null; % McFadden???s R^2

            model_info.subject.LL_model(s,1) = LL_model;
            model_info.subject.LL_null(s,1) = LL_null;
            model_info.subject.pseudo_r2(s,1) = pseudo_r2;
            model_info.subject.model_var{s,1} = model_var;
        end

        clear param_real
        param_real = x_bestfit;
        param_real(:,1) = exp(x_bestfit(:,1));
        param_real(:,1) = param_real(:,1) + 0.001;

        param_real(:,2) = 1./(1+exp(-x_bestfit(:,2)));
        param_real(:,2) = (param_real(:,2)*(1-0.001)) + 0.001;

        param_real(:,3) = exp(x_bestfit(:,3));
        param_real(:,3) = param_real(:,3) + 0.001;
        param_real(:,3) = -1*param_real(:,3);

        model_info.subject.parameter = param_real(:,idx_free==1);

    case {'hbi_RL_outcomeSmall_initSmall_blockdistSmall'}

        % group
        x_bestfit = cbm.output.group_mean{1};
        for s = 1:nSub
            [LL, model_var] = mleModel(x_bestfit, data_subject{s});
            LL_model = LL;

            LL_null = 0;
            for b = 1:nBlock
                if ~isnan(model_var{b}.LL_block)
                    LL_null = LL_null + log(0.5)*nTrial; % LL of random-choice model
                end
            end
            pseudo_r2 = 1 - LL_model/LL_null; % McFadden???s R^2

            model_info.group.LL_model(s,1) = LL_model;
            model_info.group.LL_null(s,1) = LL_null;
            model_info.group.pseudo_r2(s,1) = pseudo_r2;
            model_info.group.model_var{s,1} = model_var;
        end

        clear param_real
        param_real = x_bestfit;
        param_real(1) = exp(x_bestfit(1));
        param_real(1) = param_real(1) + 0.001;

        param_real(2) = 1./(1+exp(-x_bestfit(2)));
        param_real(2) = param_real(2)*(1-0.001) + 0.001;

        param_real(3:end) = exp(x_bestfit(3:end));
        param_real(3:end) = param_real(3:end) + 0.001;
        param_real(3:end) = -1*param_real(3:end);

        model_info.group.parameter = param_real(idx_free==1);

        % subject
        x_bestfit = cbm.output.parameters{1};
        for s = 1:nSub
            [LL, model_var] = mleModel(x_bestfit(s,:), data_subject{s});
            LL_model = LL;

            LL_null = 0;
            for b = 1:nBlock
                if ~isnan(model_var{b}.LL_block)
                    LL_null = LL_null + log(0.5)*nTrial; % LL of random-choice model
                end
            end
            pseudo_r2 = 1 - LL_model/LL_null; % McFadden???s R^2

            model_info.subject.LL_model(s,1) = LL_model;
            model_info.subject.LL_null(s,1) = LL_null;
            model_info.subject.pseudo_r2(s,1) = pseudo_r2;
            model_info.subject.model_var{s,1} = model_var;
        end

        clear param_real
        param_real = x_bestfit;
        param_real(:,1) = exp(x_bestfit(:,1));
        param_real(:,1) = param_real(:,1) + 0.001;

        param_real(:,2) = 1./(1+exp(-x_bestfit(:,2)));
        param_real(:,2) = (param_real(:,2)*(1-0.001)) + 0.001;

        param_real(:,3:end) = exp(x_bestfit(:,3:end));
        param_real(:,3:end) = param_real(:,3:end) + 0.001;
        param_real(:,3:end) = -1*param_real(:,3:end);


        % replace parameter to NaN for the blocks with no data
        for s = 1:nSub
            for b = 1:nBlock
                if sum(data_subject{s}{b}.trial_subject_choice(:))==0
                    param_real(s,2+b) = NaN;
                end
            end
        end

        model_info.subject.parameter = param_real(:,idx_free==1);


end
cbm.model_info = model_info;

% output
fittingFile = fullfile(dirModel, sprintf('mle_%s_group', model_name_block));
save(fittingFile,'cbm');

