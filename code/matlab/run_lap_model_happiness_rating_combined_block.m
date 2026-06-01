function run_lap_model_happiness_rating_combined_block(model_name, version_data, list_block, subno)

% add path
addpath('../cbm-master/codes');

% happiness_type
happiness_type = 'raw';

% versoin_data
if nargin<3
    list_block = [];
end

% sublist
sublist_all = textread(sprintf('sublist_%s', version_data), '%s');
nSub_all = numel(sublist_all);
if nargin==5
    sublist = sublist_all(subno);
else
    sublist = sublist_all;
end
nSub = numel(sublist);

% amount & prob
win_loss = [30,10];
list_prob = [0.75, 0.25];

amt_win = max(win_loss);
amt_loss = min(win_loss);
amt_mean = mean(win_loss);

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

% learning model
switch model_name
    case {'lap_happy_p_ppe_hbiRL_distSmall_combined'}
        learning_model = 'hbi_RL_outcomeSmall_initSmall_distSmall_combined';

end

% model_name
model_name_block = sprintf('%s%s', model_name, blockname);
learning_model_block = sprintf('%s%s', learning_model, blockname);
fprintf('<%s, %s>\n', model_name_block, happiness_type);

% directory
dirData = fullfile('../../data/organizedData', version_data);
dirLR = fullfile('../../data/modelData', version_data, 'learning', learning_model_block);
dirModel = fullfile('../../data/modelData', version_data, 'happiness', happiness_type, model_name_block);
mkdir(dirModel);

% load learning model
clear model_info_learning
if ~strcmp(learning_model, '')

    clear param_all

    filename = sprintf('mle_%s_group', learning_model_block);
    filename = fullfile(dirLR, filename);
    load(filename); % cbm

    for s = 1:nSub
        model_info_learning{s,1}.model_var = cbm.model_info.subject.model_var{subno};
    end

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

    clear model_info data
    for b = 1:nBlock

        idx_block = list_block(b);

        % current_task_data
        current_task_data = subjectData.task{idx_block};

        % organize data
        choice = current_task_data.choice;
        outcome = current_task_data.outcome;
        amt_outcome = current_task_data.amt_outcome;

        nTrial = numel(choice);

        data{b}.trialno_per_block = [1:nTrial]';
        data{b}.trialno_per_session = [1:nTrial]' + (b-1)*nTrial;

        idx_period = ([1:nTrial]'>=nTrial/2)+1;
        data{b}.idx_period = idx_period;

        % happiness
        happiness_raw = current_task_data.happiness;
        happiness_zscore = current_task_data.zscore_happiness;

        happiness_raw = happiness_raw*100;
        

        rating_trialno = find(~isnan(happiness_raw));
        nRating = numel(rating_trialno);

        rating_happiness_raw = happiness_raw(rating_trialno);
        %         rating_happiness_zscore = happiness_zscore(rating_trialno);
        rating_happiness_zscore = zscore(rating_happiness_raw);

        switch happiness_type
            case {'raw'}
                rating_happiness_data = rating_happiness_raw;
            case {'zscore'}
                rating_happiness_data = rating_happiness_zscore;
        end
        trial_happiness_data = NaN(nTrial,1);
        trial_happiness_data(rating_trialno) = rating_happiness_data;

        data{b}.choice = choice;
        data{b}.outcome = outcome;
        data{b}.amt_outcome = amt_outcome;

        data{b}.rating_happiness_data = rating_happiness_data;
        data{b}.trial_happiness_data = trial_happiness_data;
        data{b}.rating_trialno = rating_trialno;

        % data for model fitting
        trial_outcome = zeros(nTrial, 1);
        trial_outcome(outcome==1) = 1;
        trial_outcome(outcome==0) = -1;
        data{b}.trial_outcome = trial_outcome;

        trial_amt_outcome = amt_outcome;
        data{b}.trial_amt_outcome = trial_amt_outcome;

        trial_idx_sensitivity = double(outcome==1);
        data{b}.trial_idx_sensitivity = trial_idx_sensitivity;

        trial_win = zeros(nTrial, 1);
        trial_loss = zeros(nTrial, 1);
        trial_win(outcome==1) = 1;
        trial_loss(outcome==0) = -1;

        data{b}.trial_win = trial_win;
        data{b}.trial_loss = trial_loss;

        trial_good_win = zeros(nTrial,1);
        idx_select = (choice==1)&(outcome==1);
        trial_good_win(idx_select) = 1;
        data{b}.trial_good_win = trial_good_win;

        trial_good_loss = zeros(nTrial,1);
        idx_select = (choice==1)&(outcome==0);
        trial_good_loss(idx_select) = -1;
        data{b}.trial_good_loss = trial_good_loss;

        trial_bad_win = zeros(nTrial,1);
        idx_select = (choice==2)&(outcome==1);
        trial_bad_win(idx_select) = 1;
        data{b}.trial_bad_win = trial_bad_win;

        trial_bad_loss = zeros(nTrial,1);
        idx_select = (choice==2)&(outcome==0);
        trial_bad_loss(idx_select) = -1;
        data{b}.trial_bad_loss = trial_bad_loss;

        % learning variables
        if ~strcmp(learning_model, '')

            trial_subject_choice = model_info_learning{s,1}.model_var{b}.trial_subject_choice;

            trial_pe = model_info_learning{s,1}.model_var{b}.trial_pe;

            % ev
            ev_chosen = sum(trial_subject_choice.*trial_prob_ev,2);
            mean_ev_chosen = mean(ev_chosen);

            trial_ev = ev_chosen - mean_ev_chosen;
            data{b}.trial_ev = trial_ev;

            data{b}.trial_pe = trial_pe;

            idx_pos = (trial_pe>=0);
            trial_pe_pos = zeros(nTrial,1);
            trial_pe_pos(idx_pos) = trial_pe(idx_pos);

            idx_neg = (trial_pe<0);
            trial_pe_neg = zeros(nTrial,1);
            trial_pe_neg(idx_neg) = trial_pe(idx_neg);

            data{b}.trial_pe_pos = trial_pe_pos;
            data{b}.trial_pe_neg = trial_pe_neg;

        end



    end % end of block

    data_subject{1} = data;


    %%%%% model fitting %%%%%
    switch model_name
        case {'lap_happy_p_ppe_hbiRL_distSmall_combined'}

            % block constants
            block_constant = cell(1,nBlock);
            for b = 1:nBlock
                block_constant{b} = sprintf('b0_b%d', list_block(b));
            end

            % parameter info
            nameParameter = ['gamma',...
                block_constant,...
                'beta_p', 'beta_ppe',...
                'sigma'];

            idx_free = [1,...
                ones(1,nBlock),...
                1, 1,...
                1];
            nParameter = numel(nameParameter);
            param_default = NaN(1,nParameter);
            v = 6.25;
            prior_param = struct('mean', zeros(nParameter,1), 'variance', v); % normalized space

            % model
            mleModel = @(x, data) model_hbi_happy_ev_rpe_combined(x, data, idx_free, param_default);

    end % end of model

    % fitting
    cbm = cbm_lap(data_subject, mleModel, prior_param);

    % generate model_var
    x_bestfit = cbm.output.parameters;
    data = data_subject{1};
    [LL, model_var] = mleModel(x_bestfit, data);
    nTrial_fitting = 0;
    sse = 0;
    sstotal = 0;
    for b = 1:nBlock
        if isempty(data{b}.rating_happiness_data)
            x_bestfit(1+b) = NaN;
            continue
        else
            sstotal = sum((data{b}.rating_happiness_data-mean(data{b}.rating_happiness_data)).^2) + sstotal;
            nTrial_fitting = nTrial_fitting + numel(model_var{b}.rating_happiness_data);
            sse = model_var{b}.sse + sse;
        end
    end
    r2 = 1-sse/sstotal;

    LL_model = LL;
    

    model_info.LL_model = LL_model;    
    model_info.sse = sse;
    model_info.r2 = r2;


    for b = 1:nBlock
        if isempty(data{b}.rating_trialno) | any(isnan(data{b}.rating_happiness_data))
            x_bestfit(1+b) = NaN;
        end
    end

    % save variable
    model_info.nTrial = nTrial_fitting;
    model_info.nameParameter = nameParameter(idx_free==1);
    model_info.idx_free = idx_free(idx_free==1);
    model_info.nFree = sum(idx_free);

    %%%%% transform the parameters back %%%%%
    clear param_real
    param_real = x_bestfit;
    idx_param = 0;

    idx_param = idx_param + 1;
    param_real(idx_param) = 1./(1+exp(-x_bestfit(idx_param))); % gamma

    for b = 1:nBlock
        idx_param = idx_param + 1;
        param_real(idx_param) = 100./(1+exp(-x_bestfit(idx_param))); % baseline
    end

    idx_param = idx_param + 1; % beta_p
    idx_param = idx_param + 1; % beta_ppe

    % sigma
    param_real(end) = exp(x_bestfit(end)) + 0.001;

    

    model_info.parameter = param_real(idx_free==1);
    model_info.model_var = model_var;
    model_info.list_block = list_block;
    cbm.model_info = model_info;


    % output
    fittingFile = fullfile(dirModel, sprintf('mle_%s_%s_%s', happiness_type, model_name_block, subname));
    save(fittingFile,'cbm');

end % end of subject


