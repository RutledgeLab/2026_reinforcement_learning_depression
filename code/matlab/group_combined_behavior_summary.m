function group_combined_behavior_summary_manuscript()

%%%%% list_version %%%%%
% version_data, list_block, list_prob, list_outcome, nSurvey_max
list_version = {
    'depression_denseSampling_remote',      [1:7], [0.75, 0.25], [30,10], 2;
    'community_remote',                     [1:6], [0.75, 0.25], [30,10], 3;
    'depression_monthly_remote',            [1:5], [0.75, 0.25], [30,10], 5;
    % 'depression_denseSampling_practice',    [1],   [0.75, 0.25], [30,10], 0;
    % 'community_practice',                   [1],   [0.75, 0.25], [30,10], 0;
    };
nVersion = size(list_version,1);

% directory
dirFig = fullfile('../../figures/manuscript');
mkdir(dirFig);

% list_outcome
list_outcome = [1, 0];
nOutcome = numel(list_outcome);

% list_stim
list_stim = [1, 2];
nStim = numel(list_stim);

% list_model_learning
list_model_learning = {
    'hbi_RL_outcomeSmall_initSmall_distSmall_combined';
    'hbi_RL_outcomeSmall_initSmall_blockdistSmall';
    'hbi_RL_outcomeSmall_initSmall_blockparam';
    };
nModel_learning = numel(list_model_learning);


% list_model_happiness
list_model_happiness = {
    'hbi_happy_p_ppe_hbiRL_distSmall_combined'; % pre-fit distSmall RL model on behavior


            % 'happy_p_ppe_hbiRL_outcomeSmall_initSmall_distSmall_combined'; % pre-fit distSmall RL model on behavior
            % 'happy_p_ppe_reRLsmall_distSmall_combined'; % happiness model while modeling distSmall in a RL

    };
nModel_happiness = numel(list_model_happiness);


clear allData
for v = 1:nVersion
    
    % version_data
    version_data = list_version{v,1};
    
    list_block = list_version{v,2};
    list_prob = list_version{v,3};
    win_loss = list_version{v,4};
    nSurvey_max = list_version{v,5};
    
    nBlock = numel(list_block);
    
    
    allData{v}.version_data = version_data;
    allData{v}.list_block = list_block;
    allData{v}.win_loss = win_loss;
    allData{v}.list_prob = list_prob;
    
    % sublist
    sublist = textread(sprintf('sublist_%s', version_data), '%s');
    nSub = numel(sublist);
    allData{v}.sublist = sublist;
    
    % directory
    dirData = fullfile('../../data/organizedData', version_data);

    % demo
    switch version_data
        case {'depression_monthly_remote'}
            dirData_demo = fullfile('../../data/organizedData', 'depression_denseSampling_remote');
    end
    
    %%%%%%%%%%%%%%%%%%%%
    %%%%% analysis %%%%%
    %%%%%%%%%%%%%%%%%%%%
    for s = 1:nSub

        % subname
        subname = sublist{s};

        % load demo
        switch version_data
            case {'depression_monthly_remote'}
                filename = sprintf('%s_subjectData_%s.mat', 'depression_denseSampling_remote', subname);
                filename = fullfile(dirData_demo, filename);
                load(filename);
                clear subjectData_demo
                subjectData_demo = subjectData;
        end
        
        % load data
        filename = sprintf('%s_subjectData_%s.mat', version_data, subname);
        filename = fullfile(dirData, filename);
        load(filename);

        % subID
        allData{v}.subID{s,1} = subjectData.info.subID;

        % timestamp
        allData{v}.timestamp{s,:} = subjectData.info.phq_timestamp_minmax;

        %%%%%%%%%%%%%%%%%%%%%%%
        %%%%% task: fruit %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%
        for b = 1:nBlock
            
            current_task_data = subjectData.task{b};
            
            % organize data
            choice = current_task_data.choice;
            outcome = current_task_data.outcome;
            
            nTrial_block = numel(choice);
            
            allData{v}.behavior.choice(s,:,b) = choice;
            allData{v}.behavior.outcome(s,:,b) = outcome;
            
           

            %%%%% happiness %%%%%
            happiness_raw = current_task_data.happiness;
            happiness_raw = happiness_raw*100;
            allData{v}.behavior.happiness(s,:,b) = happiness_raw;

            allData{v}.behavior.happiness_mean(s,b) = nanmean(happiness_raw);
            allData{v}.behavior.happiness_sd(s,b) = nanstd(happiness_raw);

            if all(isnan(happiness_raw))
                allData{v}.behavior.happiness_backfilled(s,:,b) = NaN(1,nTrial_block);
                allData{v}.behavior.happiness_interp(s,:,b) = NaN(1,nTrial_block);
            else
                allData{v}.behavior.happiness_backfilled(s,:,b) = fillmissing(happiness_raw,'next');
                ratingno = find(~isnan(happiness_raw));
                allData{v}.behavior.happiness_interp(s,:,b) = interp1(ratingno, happiness_raw(ratingno), [1:nTrial_block]);
            end

            %%%%% p(good) %%%%%
            choice_notnan = choice(~isnan(choice));
            if isempty(choice_notnan)
                pGood = NaN;
            else
                isGood = double(choice_notnan==1);
                pGood = mean(isGood);
            end
            allData{v}.behavior.choice_pGood_average(s,b) = pGood;


            %%%%% p(stay) %%%%%
            choice_notnan = choice(~isnan(choice));
            if isempty(choice_notnan)
                pStay = NaN;
            else
                isStay = double(choice_notnan(2:end)==choice_notnan(1:end-1));
                pStay = mean(isStay);
            end
            allData{v}.behavior.choice_pStay_average(s,b) = pStay;
            
            %%%%% p(good) trajectory %%%%%
            if any(isnan(choice))
                isGood = NaN(nTrial_block,1);
            else
                isGood = double(choice==1);
            end
            p_good_smooth = smooth(isGood, 5);
            allData{v}.behavior.choice_isGood(s,:,b) = isGood;
            allData{v}.behavior.choice_pGood_smooth(s,:,b) = p_good_smooth;
            
            %%%%% p(stay) trajectory %%%%%
            if any(isnan(choice))
                isStay = NaN(nTrial_block,1);
                p_stay_smooth = NaN(nTrial_block,1);
            else
                isStay = double(choice(2:end)==choice(1:end-1));
                p_stay_smooth = smooth(isStay, 5);
                p_stay_smooth = [p_stay_smooth; NaN];
                isStay = [isStay; NaN];
            end
            allData{v}.behavior.choice_isStay(s,:,b) = isStay;
            allData{v}.behavior.choice_pStay_smooth(s,:,b) = p_stay_smooth;
            
            %%%%% p(stay)/happiness: win vs loss %%%%%
            idx = 0;
            for i = 1:nOutcome
                
                idx = idx + 1;
                idx_select = (outcome==list_outcome(i));
                trialno_select = find(idx_select);
                trialno_select(trialno_select>=nTrial_block) = [];
                trialno_select_next = trialno_select + 1;
                
                isStay = choice(trialno_select_next)==choice(trialno_select);
                pStay = mean(isStay);
                
                allData{v}.behavior.choice_pStay_outcome(s,idx,b) = pStay;
                allData{v}.behavior.happiness_outcome(s,idx,b) = nanmean(happiness_raw(trialno_select));
                
            end
            
            %%%%% p(stay)/happiness: good vs bad %%%%%
            idx = 0;
            for j = 1:nStim

                idx = idx + 1;
                idx_select = (choice==list_stim(j));
                trialno_select = find(idx_select);
                trialno_select(trialno_select>=nTrial_block) = [];
                trialno_select_next = trialno_select + 1;

                isStay = choice(trialno_select_next)==choice(trialno_select);
                pStay = mean(isStay);

                allData{v}.behavior.choice_pStay_stim(s,idx,b) = pStay;

            end
            
            %%%%% p(stay)/happiness: good/bad X win/loss %%%%%
            idx = 0;
            for j = 1:nStim
                for i = 1:nOutcome

                    idx = idx + 1;

                    idx_select = (choice==list_stim(j)) & (outcome==list_outcome(i));
                    trialno_select = find(idx_select);
                    trialno_select(trialno_select>=nTrial_block) = [];
                    trialno_select_next = trialno_select + 1;

                    isStay = choice(trialno_select_next)==choice(trialno_select);
                    pStay = mean(isStay);

                    allData{v}.behavior.choice_pStay_stim_outcome(s,idx,b) = pStay;

                end
            end
            
        end % end of block
        
        %%%%% life satisfactation %%%%%
        switch version_data
            case {'depression_monthly_remote'}
                allData{v}.questionnaire.life_satisfaction(s,1) = subjectData_demo.demographics.life;
            otherwise
                allData{v}.questionnaire.life_satisfaction(s,1) = subjectData.demographics.life;

        end
        
        %%%%% questionnaire %%%%%
        for i = 1:nSurvey_max
            
            allData{v}.questionnaire.PHQ_total(s,i) = subjectData.questionnaire.PHQ{i}.score_total;
            allData{v}.questionnaire.GAD_total(s,i) = subjectData.questionnaire.GAD{i}.score_total;
            allData{v}.questionnaire.MASQ_anhedonic_depression(s,i) = subjectData.questionnaire.MASQ{i}.score_anhedonic_depression;
            allData{v}.questionnaire.AMI_behavioral(s,i) = subjectData.questionnaire.AMI{i}.score_behavioral;
            
            allData{v}.questionnaire.PHQ_item(s,:,i) = subjectData.questionnaire.PHQ{i}.score_item;
            allData{v}.questionnaire.GAD_item(s,:,i) = subjectData.questionnaire.GAD{i}.score_item;
            allData{v}.questionnaire.MASQ_anhedonic_depression_item(s,:,i) = subjectData.questionnaire.MASQ{i}.score_anhedonic_depression_item;
            allData{v}.questionnaire.AMI_behavioral_item(s,:,i) = subjectData.questionnaire.AMI{i}.score_behavioral_item;
            
            allData{v}.questionnaire.PHQ_distress(s,i) = subjectData.questionnaire.PHQ{i}.score_distress;
            allData{v}.questionnaire.GAD_distress(s,i) = subjectData.questionnaire.GAD{i}.score_distress;
            
        end
        
        %%%%% demographics %%%%%
        switch version_data
            case {'depression_monthly_remote'}
                allData{v}.demographics.age(s,1) = subjectData_demo.demographics.age;
                allData{v}.demographics.gender(s,1) = subjectData_demo.demographics.gender_code;
                allData{v}.demographics.education(s,1) = subjectData_demo.demographics.education_year;
            otherwise
                allData{v}.demographics.age(s,1) = subjectData.demographics.age;
                allData{v}.demographics.gender(s,1) = subjectData.demographics.gender_code;
                allData{v}.demographics.education(s,1) = subjectData.demographics.education_year;
        end
                
        %%%%% diagnosis: PHQ %%%%
        %  if 5 or more of the 9 depressive symptom criteria have been 
        % present at least “more than half the days” [score 2] in the past 2 weeks, 
        % and 1 of the symptoms is depressed mood or anhedonia.
        
        for i = 1:nSurvey_max
            
            phq_item = allData{v}.questionnaire.PHQ_item(s,:,i);
            diagnosis_phq = NaN;
            if ~isnan(sum(phq_item))
                diagnosis_phq = ((phq_item(1)>=2) | (phq_item(2)>=2)) & (sum(phq_item>=2)>=5);
            end
            allData{v}.demographics.diagnosis_phq(s,i) = double(diagnosis_phq);
            
        end

        %  if 5 or more of the 9 depressive symptom criteria have been 
        % present at least “Several days” [score 1] in the past 2 weeks, 
        % and either depressed mood or anhedonia has been present at least
        % "More than half the days" [score 2] in the past 2 weeks.
        
        for i = 1:nSurvey_max
            
            phq_item = allData{v}.questionnaire.PHQ_item(s,:,i);
            diagnosis_phq = NaN;
            if ~isnan(sum(phq_item))
                diagnosis_phq = ((phq_item(1)>=2) | (phq_item(2)>=2)) & (sum(phq_item>=1)>=5);
            end
            allData{v}.demographics.diagnosis_phq_lowcutoff(s,i) = double(diagnosis_phq);
            
        end

        %%%%% phq: redcap %%%%%
        if v==1

            % prescreen
            phq_item = subjectData.phq8_redcap.prescreen;
            allData{v}.phq8_redcap.prescreen_item(s,:) = phq_item;
            allData{v}.phq8_redcap.prescreen_total(s,:) = sum(phq_item);

            diagnosis_phq = NaN;
            if ~isnan(sum(phq_item))
                diagnosis_phq = ((phq_item(1)>=2) | (phq_item(2)>=2)) & (sum(phq_item>=2)>=5);
            end
            allData{v}.demographics.diagnosis_phq_prescreen(s,1) = double(diagnosis_phq);

            % prescreen: lowcutoff
            phq_item = subjectData.phq8_redcap.prescreen;
            allData{v}.phq8_redcap.prescreen_item(s,:) = phq_item;
            allData{v}.phq8_redcap.prescreen_total(s,:) = sum(phq_item);

            diagnosis_phq = NaN;
            if ~isnan(sum(phq_item))
                diagnosis_phq = ((phq_item(1)>=2) | (phq_item(2)>=2)) & (sum(phq_item>=1)>=5);
            end
            allData{v}.demographics.diagnosis_phq_lowcutoff_prescreen(s,1) = double(diagnosis_phq);



            % scid
            phq_item = subjectData.phq8_redcap.scid;
            allData{v}.phq8_redcap.scid_item(s,:) = phq_item;
            allData{v}.phq8_redcap.scid_total(s,:) = sum(phq_item);

            diagnosis_phq = NaN;
            if ~isnan(sum(phq_item))
                diagnosis_phq = ((phq_item(1)>=2) | (phq_item(2)>=2)) & (sum(phq_item>=2)>=5);
            end
            allData{v}.demographics.diagnosis_phq_scid(s,1) = double(diagnosis_phq);

            % scid: lowcutoff
            phq_item = subjectData.phq8_redcap.scid;
            allData{v}.phq8_redcap.scid_item(s,:) = phq_item;
            allData{v}.phq8_redcap.scid_total(s,:) = sum(phq_item);

            diagnosis_phq = NaN;
            if ~isnan(sum(phq_item))
                diagnosis_phq = ((phq_item(1)>=2) | (phq_item(2)>=2)) & (sum(phq_item>=1)>=5);
            end
            allData{v}.demographics.diagnosis_phq_lowcutoff_scid(s,1) = double(diagnosis_phq);
            
        end

        %%%%% app_life %%%%%
        if v==1
            
            allData{v}.app_life.med_ssri(s,1) = subjectData.app_life.med_ssri;
            allData{v}.app_life.med_snri(s,1) = subjectData.app_life.med_snri;
            allData{v}.app_life.med_ndri(s,1) = subjectData.app_life.med_ndri;
            allData{v}.app_life.smoke_100(s,1) = subjectData.app_life.smoke_100;
            allData{v}.app_life.smoke_current(s,1) = subjectData.app_life.smoke_current;

        else

            allData{v}.app_life.med_ssri(s,1) = NaN;
            allData{v}.app_life.med_snri(s,1) = NaN;
            allData{v}.app_life.med_ndri(s,1) = NaN;
            allData{v}.app_life.smoke_100(s,1) = NaN;
            allData{v}.app_life.smoke_current(s,1) = NaN;

        end
        
        %%%%% timegap %%%%%
        allData{v}.messageTime(s,1) = NaT;
        allData{v}.messageCheck(s,1) = NaN;
        allData{v}.task_timegap(s,:) = NaN(1,nBlock);
        if v==1 | v==3
            
            % message check
%             allData{v}.messageCheck(s,1) = subjectData.info.messageCheck;
            
            % message time
            messageTime = subjectData.info.messageTime;
            allData{v}.messageTime(s,1) = messageTime;
            for b = 1:nBlock
                
                task_timestamp = subjectData.task{b}.timestamp;
                timegap = timeofday(task_timestamp) - timeofday(messageTime);
                allData{v}.task_timegap(s,b) = minutes(timegap); % convert to minutes
            end
        end
        
                
    end % end of subject
    
end % end of version

% allData;
% save('r01_data.mat', 'allData');


%%%%% check performance %%%%%
% v = 2;
% x = mean(allData{v}.behavior.choice_isGood(:,[1:30],1),2);
% [numel(x), nanmean(x), nanstd(x,0,1)./sqrt(numel(x))]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%
%%%%% model %%%%%
%%%%%%%%%%%%%%%%%
%%%%% learning %%%%%
for v = 1:nVersion
    
    % version_data
    version_data = list_version{v,1};
    list_block = list_version{v,2};
    
    nBlock = numel(list_block);
    
    blockname = sprintf('block_%d-%d', min(list_block), max(list_block));
    
    % sublist
    sublist = textread(sprintf('sublist_%s', version_data), '%s');
    nSub = numel(sublist);
    
    for m = 1:nModel_learning
        
        % load model
        model_name = sprintf('%s_%s', list_model_learning{m}, blockname);
        dirModel_learning = fullfile('../../data/modelData', version_data, 'learning', model_name);
        
        %%%%% hbi %%%%%
        % load model
        filename = sprintf('mle_%s_group.mat', model_name);
        filename = fullfile(dirModel_learning, filename);
        load(filename); % cbm
        
        % model info
        allData{v}.model_learning{m}.model_name = model_name;
        allData{v}.model_learning{m}.parameter_name = cbm.model_info.nameParameter;
        allData{v}.model_learning{m}.parameter = cbm.model_info.subject.parameter;
        allData{v}.model_learning{m}.pseudo_r2 = cbm.model_info.subject.pseudo_r2;
        
        nParam = cbm.model_info.nFree;
        nTrial = cbm.model_info.nTrial_per_subject;
        LL_model = cbm.model_info.subject.LL_model;
        
        allData{v}.model_learning{m}.aic = 2*nParam - 2*LL_model;
        allData{v}.model_learning{m}.bic = nParam*log(nTrial) - 2*LL_model;
        
        allData{v}.model_learning{m}.model_var = cbm.model_info.subject.model_var;
        
        % model prediction
        for s = 1:nSub
            for b = 1:nBlock
                
                choice_pGood = cbm.model_info.subject.model_var{s}{b}.trial_p_choice(:,1);
                allData{v}.model_learning{m}.choice_pGood(s,:,b) = choice_pGood;
                
            end % end of block
        end % end of subject
        
    end % end of model
    
end



%%%%% happiness %%%%%
happiness_type = 'raw';
for v = 1:nVersion

    % version_data
    version_data = list_version{v,1};
    list_block = list_version{v,2};

    nBlock = numel(list_block);

    blockname = sprintf('block_%d-%d', min(list_block), max(list_block));

    % sublist
    sublist = textread(sprintf('sublist_%s', version_data), '%s');
    nSub = numel(sublist);

    for m = 1:nModel_happiness

        % model_name
        model_name = sprintf('%s_%s', list_model_happiness{m}, blockname);

        % dirModel
        dirModel_happiness = fullfile('../../data/modelData', version_data, 'happiness', happiness_type, model_name);

        %%%%% hbi %%%%%
        % load model
        filename = sprintf('mle_%s_%s_group.mat', happiness_type, model_name);
        filename = fullfile(dirModel_happiness, filename);
        load(filename); % cbm

        % model info
        allData{v}.model_happiness_raw{m}.model_name = model_name;
        allData{v}.model_happiness_raw{m}.parameter_name = cbm.model_info.nameParameter;
        allData{v}.model_happiness_raw{m}.parameter = cbm.model_info.subject.parameter;
        allData{v}.model_happiness_raw{m}.r2 = cbm.model_info.subject.r2;

        nParam = cbm.model_info.nFree;

        for s = 1:nSub

            % subname
            subname = sublist{s};

            sd_residual = cbm.model_info.subject.parameter(s,end);

            LL_model = cbm.model_info.subject.LL_model(s);

            % constant model
            model_var = cbm.model_info.subject.model_var{s};
            nBlock = numel(model_var);
            subject_happiness_data = [];
            for b = 1:nBlock
                rating_happiness_data = model_var{b}.rating_happiness_data;
                if all(~isnan(rating_happiness_data))
                    subject_happiness_data = [subject_happiness_data; rating_happiness_data];
                end
            end
            nTrial_fitting = numel(subject_happiness_data);
            subject_happiness_residual = subject_happiness_data - mean(subject_happiness_data);
            LL_null = sum(log(normpdf(subject_happiness_residual, 0, sd_residual)));
            
            pseudo_r2 = 1 - LL_model/LL_null;
            allData{v}.model_happiness_raw{m}.pseudo_r2(s,1) = pseudo_r2;
            
            % allData{v}.model_happiness_raw{m}.aic(s,1) = 2*nParam + nTrial*log(mse_model);
            % allData{v}.model_happiness_raw{m}.bic(s,1) = nParam*log(nTrial) + nTrial*log(mse_model);

            allData{v}.model_happiness_raw{m}.aic = 2*nParam - 2*LL_model;
            allData{v}.model_happiness_raw{m}.bic = nParam*log(nTrial_fitting) - 2*LL_model;


            for b = 1:nBlock

                trial_happiness_pred = cbm.model_info.subject.model_var{s}{b}.trial_happiness_pred;
                allData{v}.model_happiness_raw{m}.trial_happiness_pred(s,:,b) = trial_happiness_pred;

                trial_happiness_data = cbm.model_info.subject.model_var{s}{b}.trial_happiness_data;
                allData{v}.model_happiness_raw{m}.trial_happiness_data(s,:,b) = trial_happiness_data;

                trial_happiness_residual = NaN(size(trial_happiness_data));
                rating_trialno = find(~isnan(trial_happiness_data));
                rating_happiness_residual = cbm.model_info.subject.model_var{s}{b}.rating_happiness_residual;
                trial_happiness_residual(rating_trialno) = rating_happiness_residual;

                allData{v}.model_happiness_raw{m}.trial_happiness_residual(s,:,b) = trial_happiness_residual;
                allData{v}.model_happiness_raw{m}.happiness_residual_sd(s,b) = nanstd(rating_happiness_residual);
                allData{v}.model_happiness_raw{m}.happiness_pred_sd(s,b) = nanstd(trial_happiness_pred(rating_trialno));

            end % end of block


        end % end of subject
    end % end of model

end


% for v = 1:nVersion
% 
%     % version_data
%     version_data = list_version{v,1};
% 
%     list_block = list_version{v,2};
%     nBlock = numel(list_block);
% 
%     blockname = sprintf('block_%d-%d', min(list_block), max(list_block));
% 
%     % sublist
%     sublist = textread(sprintf('sublist_%s', version_data), '%s');
%     nSub = numel(sublist);
% 
%     for m = 1:nModel_happiness
% 
%         % model_name
%         model_name = sprintf('%s_%s', list_model_happiness{m}, blockname);
% 
%         % dirModel
%         dirModel_happiness = fullfile('../../data/modelData', version_data, 'happiness', happiness_type, model_name);
% 
% 
%         for s = 1:nSub
% 
%             % subname
%             subname = sublist{s};
% 
%             % load model
%             filename = sprintf('mle_%s_%s_%s.mat', happiness_type, model_name, subname);
%             filename = fullfile(dirModel_happiness, filename);
%             load(filename); % model_info
% 
%             % model info
%             allData{v}.model_happiness_raw{m}.model_name = model_name;
%             allData{v}.model_happiness_raw{m}.r2(s,1) = model_info.r2;
%             allData{v}.model_happiness_raw{m}.parameter(s,:) = model_info.parameter;
% 
%             nParam = model_info.nFree;
%             nTrial = nBlock-1;
%             mse_model = model_info.sse/nTrial;
% 
%             allData{v}.model_happiness_raw{m}.aic(s,1) = 2*nParam + nTrial*log(mse_model);
%             allData{v}.model_happiness_raw{m}.bic(s,1) = nParam*log(nTrial) + nTrial*log(mse_model);
% 
% 
%             for b = 1:nBlock
% 
%                 allData{v}.model_happiness_raw{m}.trial_happiness_pred(s,:,b) = model_info.model_var{b}.trial_happiness_pred;
% 
%                 trial_happiness_pred = model_info.model_var{b}.trial_happiness_pred;
%                 allData{v}.model_happiness_raw{m}.trial_happiness_pred(s,:,b) = trial_happiness_pred;
% 
%                 trial_happiness_data = model_info.model_var{b}.trial_happiness_data;
%                 allData{v}.model_happiness_raw{m}.trial_happiness_data(s,:,b) = trial_happiness_data;
% 
%                 trial_happiness_residual = NaN(size(trial_happiness_data));
%                 rating_trialno = find(~isnan(trial_happiness_data));
%                 rating_happiness_residual = model_info.model_var{b}.rating_happiness_residual;
%                 trial_happiness_residual(rating_trialno) = rating_happiness_residual;
% 
%                 allData{v}.model_happiness_raw{m}.trial_happiness_residual(s,:,b) = trial_happiness_residual;
%                 allData{v}.model_happiness_raw{m}.happiness_residual_sd(s,b) = nanstd(model_info.model_var{b}.rating_happiness_residual);
%                 allData{v}.model_happiness_raw{m}.happiness_pred_sd(s,b) = nanstd(trial_happiness_pred(rating_trialno));
% 
%                 allData{v}.model_happiness_raw{m}.happiness_residual_pos_sd(s,b) = nanstd(rating_happiness_residual(rating_happiness_residual>0));
%                 allData{v}.model_happiness_raw{m}.happiness_residual_neg_sd(s,b) = nanstd(rating_happiness_residual(rating_happiness_residual<0));
% 
%             end % end of block
% 
% 
%         end % end of subject
%     end % end of model
% 
% end


%%%%% redcap info %%%%%
for v = 1:2

    % version_data
    version_data = list_version{v,1};

    % load data
    filename = sprintf('subject_medication_%s.csv', version_data);

    T_redcapInfo = readtable(filename);

    % organize data
    sublist = allData{v}.sublist;
    nSub = numel(sublist);
    for s = 1:nSub

        % idx_subject
        subno = str2num(sublist{s});
        
        % current_data
        idx_subject = (T_redcapInfo.redcapID==subno);
        current_data = T_redcapInfo(idx_subject,:);

        %%%%% antidepressant %%%%%
        answer = NaN;
        if v==1

            isAntidepressant = current_data.prescreen_med_antidepressant{:};
            if ~isempty(isAntidepressant)
                switch isAntidepressant
                    case {'Yes'}
                        answer = 1;
                    case {'No'}
                        answer = 0;
                end
            end
            
        elseif v==2

            isPsychoactive = current_data.prescreen_med_psychoactive{:};
            notAntidepressant = current_data.prescreen_med_not_antidepressant{:};
            if ~isempty(isPsychoactive)
                switch isPsychoactive
                    case {'Yes'}
                        switch notAntidepressant
                            case {'Yes'}
                                answer = 0;
                            case {'No'}
                                answer = 1;
                        end
                    case {'No'}
                        answer = 0;
                end
            end

        end
        allData{v}.redcap_info.antidepressant(s,1) = answer;

        
        %%%%% smoking %%%%%
        answer = NaN;
        if v==1

            isSmoke = current_data.prescreen_nicotine_use{:};
            if ~isempty(isSmoke)
                switch isSmoke
                    case {'Yes'}
                        answer = 1;
                    case {'No'}
                        answer = 0;
                end
            end
            
        elseif v==2

            answer = NaN;

        end
        allData{v}.redcap_info.smoke_history(s,1) = answer;

        %%%%% drink/drug %%%%%
        answer = NaN;
        isSubstance = current_data.prescreen_substance_use{:};
        if ~isempty(isSubstance)
            switch isSubstance
                case {'Yes'}
                    answer = 1;
                case {'No'}
                    answer = 0;
            end
        end
        allData{v}.redcap_info.substance_history(s,1) = answer;
        
    end

end








%%%%% scid info %%%%%
filename = 'subject_scid_info.xls';
data_scid = readtable(filename);

idx_ver = 1;
sublist = allData{idx_ver}.sublist;
nSub = numel(sublist);
allData{idx_ver}.scid.current_mde = NaN(nSub,1);
allData{idx_ver}.scid.past_mde = NaN(nSub,1);
allData{idx_ver}.scid.current_gad = NaN(nSub,1);
for s = 1:nSub
    
    idx_sub = data_scid.record_id==str2num(sublist{s});
    if sum(idx_sub)==0
        continue
    end
    
    % current_mde
    current_mde = data_scid.current_mde{idx_sub};
    if isempty(current_mde)
        current_mde = NaN;
    else
        switch current_mde
            case {'Y'}
                current_mde = 1;
            case {'N'}
                current_mde = 0;
        end
    end
    allData{idx_ver}.scid.current_mde(s,1) = current_mde;
    
    % current_mde
    past_mde = data_scid.past_mde{idx_sub};
    if isempty(past_mde)
        past_mde = NaN;
    else
        switch past_mde
            case {'Y'}
                past_mde = 1;
            case {'N'}
                past_mde = 0;
        end
    end
    allData{idx_ver}.scid.past_mde(s,1) = past_mde;
    
    % current_gad
    current_gad = data_scid.current_gad{idx_sub};
    if isempty(current_gad)
        current_gad = NaN;
    else
        switch current_gad
            case {'Y'}
                current_gad = 1;
            case {'N'}
                current_gad = 0;
        end
    end
    allData{idx_ver}.scid.current_gad(s,1) = current_gad;


end
sum(~isnan(allData{1}.scid.current_mde))
tabulate(allData{1}.scid.current_mde)
tabulate(allData{1}.scid.past_mde)
tabulate(allData{1}.scid.current_mde==1|allData{1}.scid.past_mde==1)
tabulate(allData{1}.scid.current_gad)
tabulate(allData{1}.scid.current_mde==1|allData{1}.scid.past_mde==1|allData{1}.scid.current_gad==1)


%%%%% matching smaple %%%%
v = 1;
clear sample_patients
for i = 1:numel(allData{v}.sublist)
    sample_patients(i).age = allData{v}.demographics.age(i);
    sample_patients(i).gender = allData{v}.demographics.gender(i);
    sample_patients(i).education = allData{v}.demographics.education(i);
    sample_patients(i).ex = 0;
    sample_patients(i).subject_idx = i;
end

idx_scid = (allData{1}.scid.current_mde==1|allData{1}.scid.past_mde==1);
% idx_scid = (allData{1}.scid.current_mde==1);
% idx_scid = (allData{1}.scid.past_mde==1);
sample_patients = sample_patients(idx_scid);

v = 2;
clear sample_controls
for i = 1:numel(allData{v}.sublist)
    sample_controls(i).age = allData{v}.demographics.age(i);
    sample_controls(i).gender = allData{v}.demographics.gender(i);
    sample_controls(i).education = allData{v}.demographics.education(i);
    sample_controls(i).ex = 0;
    sample_controls(i).subject_idx = i;
end

% match samples
alpha = 0.1; % p-value threshold for stopping rule
target_ratio = 1; % minimum sample size ratio patient/control (e.g. 1.5 means 50% more patients than controls)
max_iter = 500; % maximum number of iterations to run

clear current_p
for i = 1:max_iter
    
    % initial checks
    idx0 = find([sample_controls.ex]==0); % find controls not yet excluded
    idx1 = find([sample_patients.ex]==0); % find patients not yet excluded
    check_ratio = (length(idx1)/length(idx0)) >= target_ratio; % check if ratio rule met
    
    % display progress
    disp(['Matching samples by exclusion. N(Controls)=', num2str(length(idx0)),'. N(Patients)=', num2str(length(idx1)), '.']);
    
    % current group differences (p-values)
    [~,x,~,~] = prop_test([sum([sample_patients(idx1).gender]==0),sum([sample_controls(idx0).gender]==0)], ...
                          [length(idx1),length(idx0)],'false'); current_p(1,i) = x; % gender
    [x,~,~] = ranksum([sample_patients(idx1).age]',[sample_controls(idx0).age]'); current_p(2,i) = x; % age
    [x,~,~] = ranksum([sample_patients(idx1).education]',[sample_controls(idx0).education]'); current_p(3,i) = x; % education
    
    % check if stopping rule met:
    % if target_ratio == 1 % if aiming for perfect match
    %     stop = (sum(current_p(1,:)>=alpha)>0 && ...  % gender matched at least once
    %             sum(current_p(2,:)>=alpha)>0 && ...  % age matched at least once
    %             sum(current_p(3,:)>=alpha)>0) && ... % education matched at least once
    %             length(idx0) == length(idx1); % samples are currently same size
    % elseif target_ratio ~= 1 % if aiming for other ratio
    %     stop = (sum(current_p(1,:)>=alpha)>0 && ...
    %             sum(current_p(2,:)>=alpha)>0 && ...
    %             sum(current_p(3,:)>=alpha)>0) && ...
    %             check_ratio == 1; % minimum ratio rule met
    % end
    if target_ratio == 1 % if aiming for perfect match
        stop = (sum(current_p(1,i)>=alpha)>0 && ...  % gender matched at least once
            sum(current_p(2,i)>=alpha)>0 && ...  % age matched at least once
            sum(current_p(3,i)>=alpha)>0) && ... % education matched at least once
            length(idx0) == length(idx1); % samples are currently same size
    elseif target_ratio ~= 1 % if aiming for other ratio
        stop = (sum(current_p(1,i)>=alpha)>0 && ...
            sum(current_p(2,i)>=alpha)>0 && ...
            sum(current_p(3,i)>=alpha)>0) && ...
            check_ratio == 1; % minimum ratio rule met
    end
    
    if stop == 1 % if stopping rule met
        
        break % stop matching
        
    elseif stop == 0 && check_ratio == 0 % elseif stopping rule not met and ratio smaller than target
        
        % calculate new test statistic on each iteration
        clear new_stat
        for j = 1:length(idx0)

            % exclude subject j from control sample
            idx00 = idx0; idx00(j) = [];

            % calculate test statistics without subject j
            [~,~,x,~] = prop_test([sum([sample_patients(idx1).gender]==0),sum([sample_controls(idx00).gender]==0)], ...
                        [length(idx1),length(idx00)],'false'); new_stat(1,j) = abs(x); % gender (chi-squared)
            [~,~,x] = ranksum([sample_patients(idx1).age]',[sample_controls(idx00).age]'); new_stat(2,j) = abs(x.zval); % age (z)
            [~,~,x] = ranksum([sample_patients(idx1).education]',[sample_controls(idx00).education]'); new_stat(3,j) = abs(x.zval); % education (z)
        end

        % select subject from control sample to exclude
        combined_stat = sum(new_stat(current_p(:,i)<alpha,:),1); % calculate combined stat (check inclusion threshold)
        to_exclude = find(combined_stat==min(combined_stat),1,'first'); % find subject to minimise combined stat
        sample_controls(idx0(to_exclude)).ex = 1; % mark this subject for exclusion
        
    elseif stop == 0 && check_ratio == 1 % elseif stopping rule not met and ratio larger than target
        
        % calculate new test statistic on each iteration
        clear new_stat
        for j = 1:length(idx1)

            % exclude subject j from patients sample
            idx11 = idx1; idx11(j) = [];

            % calculate test statistics without subject j
            [~,~,x,~] = prop_test([sum([sample_patients(idx11).gender]==0),sum([sample_controls(idx0).gender]==0)], ...
                        [length(idx11),length(idx0)],'false'); new_stat(1,j) = abs(x); % gender (chi-squared)
            [~,~,x] = ranksum([sample_patients(idx11).age]',[sample_controls(idx0).age]'); new_stat(2,j) = abs(x.zval); % age (z)
            [~,~,x] = ranksum([sample_patients(idx11).education]',[sample_controls(idx0).education]'); new_stat(3,j) = abs(x.zval); % education (z)
        end

        % select subject from patient sample to exclude
        combined_stat = sum(new_stat(current_p(:,i)<alpha,:),1); % calculate combined stat (check inclusion threshold)
        to_exclude = find(combined_stat==min(combined_stat),1,'first'); % find subject to minimise combined stat
        sample_patients(idx1(to_exclude)).ex = 1; % mark this subject for exclusion

    end
    
end
sample_controls_full = sample_controls; % store full control sample
sample_patients_full = sample_patients; % store full patient sample
sample_controls = sample_controls([sample_controls.ex]==0); % exclude selected subjects from control sample
sample_patients = sample_patients([sample_patients.ex]==0); % exclude selected subjects from patient sample
% display message
if i<max_iter
    disp('Samples matched!');
    disp(['Final N(Controls)=', num2str(length(sample_controls)),'.']);
    disp(['Final N(Patients)=', num2str(length(sample_patients)),'.']);
elseif i==max_iter
    disp('Maximum iterations reached. Unable to match samples.');
end

match_idx.all = {[sample_patients.subject_idx]', [sample_controls.subject_idx]'};


% select data based on match_idx
clear matchData nonmatchData
for v = 1:2
    
    idx_match = match_idx.all{v};
    
    matchData{v}.demographics.gender = allData{v}.demographics.gender(idx_match);
    matchData{v}.demographics.age = allData{v}.demographics.age(idx_match);
    matchData{v}.demographics.education = allData{v}.demographics.education(idx_match);
    
    matchData{v}.questionnaire.PHQ_total = allData{v}.questionnaire.PHQ_total(idx_match,:);
    matchData{v}.questionnaire.MASQ_anhedonic_depression = allData{v}.questionnaire.MASQ_anhedonic_depression(idx_match,:);
    matchData{v}.questionnaire.GAD_total = allData{v}.questionnaire.GAD_total(idx_match,:);
    matchData{v}.questionnaire.AMI_behavioral = allData{v}.questionnaire.AMI_behavioral(idx_match,:);
    
    matchData{v}.questionnaire.PHQ_item = allData{v}.questionnaire.PHQ_item(idx_match,:,:);
    matchData{v}.questionnaire.MASQ_anhedonic_depression_item = allData{v}.questionnaire.MASQ_anhedonic_depression_item(idx_match,:,:);
    matchData{v}.questionnaire.GAD_item = allData{v}.questionnaire.GAD_item(idx_match,:,:);
    matchData{v}.questionnaire.AMI_behavioral_item = allData{v}.questionnaire.AMI_behavioral_item(idx_match,:,:);

    matchData{v}.questionnaire.PHQ_distress = allData{v}.questionnaire.PHQ_distress(idx_match,:);
    matchData{v}.questionnaire.GAD_distress = allData{v}.questionnaire.GAD_distress(idx_match,:);
    
    matchData{v}.behavior.choice_isGood = allData{v}.behavior.choice_isGood(idx_match,:,:);
    matchData{v}.behavior.choice_pGood_smooth = allData{v}.behavior.choice_pGood_smooth(idx_match,:,:);
    matchData{v}.behavior.choice_pGood_average = allData{v}.behavior.choice_pGood_average(idx_match,:);
    matchData{v}.behavior.choice_pStay_average = allData{v}.behavior.choice_pStay_average(idx_match,:);
    
    matchData{v}.behavior.happiness = allData{v}.behavior.happiness(idx_match,:,:);
    matchData{v}.behavior.happiness_mean = allData{v}.behavior.happiness_mean(idx_match,:);
    matchData{v}.behavior.happiness_backfilled = allData{v}.behavior.happiness_backfilled(idx_match,:,:);
    matchData{v}.behavior.happiness_interp = allData{v}.behavior.happiness_interp(idx_match,:,:);
    
    matchData{v}.model_learning{1}.parameter = allData{v}.model_learning{1}.parameter(idx_match,:);
    matchData{v}.model_learning{2}.parameter = allData{v}.model_learning{2}.parameter(idx_match,:);
    matchData{v}.model_learning{3}.parameter = allData{v}.model_learning{3}.parameter(idx_match,:);
    matchData{v}.model_happiness_raw{1}.parameter = allData{v}.model_happiness_raw{1}.parameter(idx_match,:);
    matchData{v}.model_happiness_raw{1}.trial_happiness_pred = allData{v}.model_happiness_raw{m}.trial_happiness_pred(idx_match,:,:);
    
    matchData{v}.demographics.diagnosis_phq = allData{v}.demographics.diagnosis_phq(idx_match,:);

    matchData{v}.redcap_info.antidepressant = allData{v}.redcap_info.antidepressant(idx_match,:);
    matchData{v}.redcap_info.smoke_history = allData{v}.redcap_info.smoke_history(idx_match,:);
    matchData{v}.redcap_info.substance_history = allData{v}.redcap_info.substance_history(idx_match,:);
    
    if v==1
        matchData{v}.scid.current_mde = allData{v}.scid.current_mde(idx_match,:);
        matchData{v}.scid.past_mde = allData{v}.scid.past_mde(idx_match,:);
    end
    
end


nonmatchData = allData;




%% dataset
clear allData
% dataset_name = 'match';
dataset_name = 'nonmatch';

switch dataset_name
    case {'match'}
        allData = matchData;
    case {'nonmatch'}
        allData = nonmatchData;
end

%%%%% PCA %%%%%
% surveyData = [];
% version_idx = [];
% for v = 1:2
% 
%     temp_surveyData = [nanmean(allData{v}.questionnaire.PHQ_item(:,:,1),3),...
%         nanmean(allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,1),3),...
%         nanmean(allData{v}.questionnaire.GAD_item(:,:,1),3),...
%         nanmean(allData{v}.questionnaire.AMI_behavioral_item(:,:,1),3)];
% 
%     nSub_version = size(temp_surveyData,1);
%     version_idx = [version_idx; ones(nSub_version,1)*v];
% 
%     surveyData = [surveyData; temp_surveyData];
% 
% end

% based on match sample
surveyData = [];
version_idx = [];
for v = 1:2

    temp_surveyData = [nanmean(matchData{v}.questionnaire.PHQ_item(:,:,1),3),...
        nanmean(matchData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,1),3),...
        nanmean(matchData{v}.questionnaire.GAD_item(:,:,1),3),...
        nanmean(matchData{v}.questionnaire.AMI_behavioral_item(:,:,1),3)];

    nSub_version = size(temp_surveyData,1);
    version_idx = [version_idx; ones(nSub_version,1)*v];

    surveyData = [surveyData; temp_surveyData];

end

[coeff,score,latent,tsquared,explained,mu] = pca(surveyData,...
    'centered', 'on',...
    'VariableWeights','variance');
combined_data_score = score;
combined_data_coeff = coeff;
combined_data_mu = mu;

allData;

% save('allData.mat', 'matchData', 'nonmatchData);


%% organize data for longitudinal analysis

switch dataset_name
    case {'nonmatch'}

        % select data based on match_idx
        clear longitudinalData
        longitudinalData{3} = allData{3};

        sublist_monthly = allData{3}.sublist;
        sublist_dense = allData{1}.sublist;
        nSub_monthly = numel(sublist_monthly);

        subject_order = NaN(nSub_monthly,1);
        for s = 1:nSub_monthly

            subname = sublist_monthly{s};
            idx_subject = strcmp(sublist_dense, subname);
            subject_order(s,1) = find(idx_subject);

        end
        idx_match = subject_order;

        v = 1;

        longitudinalData{v}.demographics.gender = allData{v}.demographics.gender(idx_match);
        longitudinalData{v}.demographics.age = allData{v}.demographics.age(idx_match);
        longitudinalData{v}.demographics.education = allData{v}.demographics.education(idx_match);

        longitudinalData{v}.questionnaire.PHQ_total = allData{v}.questionnaire.PHQ_total(idx_match,:);
        longitudinalData{v}.questionnaire.MASQ_anhedonic_depression = allData{v}.questionnaire.MASQ_anhedonic_depression(idx_match,:);
        longitudinalData{v}.questionnaire.GAD_total = allData{v}.questionnaire.GAD_total(idx_match,:);
        longitudinalData{v}.questionnaire.AMI_behavioral = allData{v}.questionnaire.AMI_behavioral(idx_match,:);

        longitudinalData{v}.questionnaire.PHQ_item = allData{v}.questionnaire.PHQ_item(idx_match,:,:);
        longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item = allData{v}.questionnaire.MASQ_anhedonic_depression_item(idx_match,:,:);
        longitudinalData{v}.questionnaire.GAD_item = allData{v}.questionnaire.GAD_item(idx_match,:,:);
        longitudinalData{v}.questionnaire.AMI_behavioral_item = allData{v}.questionnaire.AMI_behavioral_item(idx_match,:,:);

        longitudinalData{v}.questionnaire.PHQ_distress = allData{v}.questionnaire.PHQ_distress(idx_match,:);
        longitudinalData{v}.questionnaire.GAD_distress = allData{v}.questionnaire.GAD_distress(idx_match,:);

        longitudinalData{v}.behavior.choice_isGood = allData{v}.behavior.choice_isGood(idx_match,:,:);
        longitudinalData{v}.behavior.choice_pGood_smooth = allData{v}.behavior.choice_pGood_smooth(idx_match,:,:);
        longitudinalData{v}.behavior.choice_pGood_average = allData{v}.behavior.choice_pGood_average(idx_match,:);
        longitudinalData{v}.behavior.choice_pStay_average = allData{v}.behavior.choice_pStay_average(idx_match,:);

        longitudinalData{v}.behavior.happiness = allData{v}.behavior.happiness(idx_match,:,:);
        longitudinalData{v}.behavior.happiness_mean = allData{v}.behavior.happiness_mean(idx_match,:);
        longitudinalData{v}.behavior.happiness_backfilled = allData{v}.behavior.happiness_backfilled(idx_match,:,:);
        longitudinalData{v}.behavior.happiness_interp = allData{v}.behavior.happiness_interp(idx_match,:,:);

        longitudinalData{v}.model_learning{1}.parameter = allData{v}.model_learning{1}.parameter(idx_match,:);
        longitudinalData{v}.model_learning{2}.parameter = allData{v}.model_learning{2}.parameter(idx_match,:);
        longitudinalData{v}.model_learning{3}.parameter = allData{v}.model_learning{3}.parameter(idx_match,:);
        longitudinalData{v}.model_happiness_raw{1}.parameter = allData{v}.model_happiness_raw{1}.parameter(idx_match,:);
        longitudinalData{v}.model_happiness_raw{1}.trial_happiness_pred = allData{v}.model_happiness_raw{m}.trial_happiness_pred(idx_match,:,:);

        longitudinalData{v}.scid.current_mde = allData{v}.scid.current_mde(idx_match);
        longitudinalData{v}.scid.past_mde = allData{v}.scid.past_mde(idx_match);
        longitudinalData{v}.scid.current_gad = allData{v}.scid.current_gad(idx_match);


        longitudinalData{3}.scid = longitudinalData{1}.scid;

end

allData;

%% check distress
% v = 1;
% data_q = nanmean(allData{v}.questionnaire.PHQ_distress,2);
% % data_q = nanmean(allData{v}.questionnaire.GAD_distress,2);
% % data_q = (nanmean(allData{v}.questionnaire.PHQ_distress,2) + nanmean(allData{v}.questionnaire.GAD_distress,2))/2;
% 
% % xData = [
% %     nanmean(allData{v}.behavior.choice_pGood_average,2),...
% %     allData{v}.model_learning{1}.parameter];
% 
% xData = [
%     nanmean(allData{v}.questionnaire.PHQ_total,2),...
%     nanmean(allData{v}.questionnaire.MASQ_anhedonic_depression,2),...
%     nanmean(allData{v}.questionnaire.GAD_total,2),...
%     nanmean(allData{v}.questionnaire.AMI_behavioral,2)];
% 
% idx_select = data_q<=median(data_q);
% mean(data_q(idx_select))
% sum(idx_select)
% x1 = xData(idx_select, :);
% [mean(x1);std(x1)]
% 
% idx_select = data_q>median(data_q);
% mean(data_q(idx_select))
% sum(idx_select)
% x2 = xData(idx_select, :);
% [mean(x2);std(x2)]
% 
% pval_all = NaN(1,size(xData,2));
% for i = 1:size(xData,2)
%     pval_all(i) = ranksum(x1(:,i), x2(:,i));
% end
% pval_all
% 
% [rho,pval] = corr(data_q, xData, 'Type', 'spearman')
% 
% 
% 
% 
% %%%%% PCA %%%%%
% pca_data = [];
% demo = [];
% dummy_group = [];
% for v = 1:nVersion
% 
%     list_block = list_version{v,2};
%     nBlock = numel(list_block);
%     nSurvey_max = list_version{v,5};
% 
%     % apply to questionnaire at different times
%     pca_coeff = combined_data_coeff;
%     surveyData = [];
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
%             allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             allData{v}.questionnaire.GAD_item(:,:,i),...
%             allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
%     surveyData_new = surveyData;
%     surveyData_new = surveyData_new - combined_data_mu;
%     pca_coeff_new = pca_coeff;
%     pca_score_new = surveyData_new*pca_coeff_new;
% 
%     nSub = size(pca_score_new,1)/nSurvey_max;
%     pca_score = NaN(nSub,2);
%     for i = 1:2
%         temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
%         pca_score(:,i) = nanmean(temp_data,2);
%     end
% 
%     pca_data = [pca_data; pca_score];
%     demo = [demo;
%         [allData{v}.demographics.age,...
%         allData{v}.demographics.gender==1,...
%         allData{v}.demographics.education]];
%     dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];
% 
% end
% pc1 = pca_data(:,1);
% pc2 = pca_data(:,2);
% 
% 
% 
% yData = [nanmean(allData{1}.questionnaire.AMI_behavioral,2);
%     nanmean(allData{2}.questionnaire.AMI_behavioral,2)];
% 
% % yData = [nanmean(allData{1}.questionnaire.PHQ_distress,2);
% %     nanmean(allData{2}.questionnaire.PHQ_distress,2)];
% % yData = [nanmean(allData{1}.questionnaire.GAD_distress,2);
% %     nanmean(allData{2}.questionnaire.GAD_distress,2)];
% 
% % y1 = [nanmean(allData{1}.questionnaire.PHQ_distress,2);
% %     nanmean(allData{2}.questionnaire.PHQ_distress,2)];
% % y2 = [nanmean(allData{1}.questionnaire.GAD_distress,2);
% %     nanmean(allData{2}.questionnaire.GAD_distress,2)];
% % yData = (y1 + y2)/2;
% 
% idx_group = dummy_group==1;
% % xData = [
% %     pc1(idx_group),...
% %     pc2(idx_group),...
% %     demo(idx_group,:)];
% xData = [
%     dummy_group,...
%     pc1,...
%     pc2,...
%     demo];
% 
% % [reg_beta, dev, stats] = glmfit(xData, yData);
% [reg_beta, dev, stats] = glmfit(xData(idx_group,:), yData(idx_group,:));
% [stats.beta, stats.p]



%% table 1: demographic & survey
% depressed
v = 1;
list_block = list_version{v,2};
x1 = [
    allData{v}.demographics.gender==1,...
    allData{v}.demographics.age,...
    allData{v}.demographics.education,...
    allData{v}.questionnaire.PHQ_total(:,1),...
    allData{v}.questionnaire.MASQ_anhedonic_depression(:,1),...
    allData{v}.questionnaire.GAD_total(:,1),...
    allData{v}.questionnaire.AMI_behavioral(:,1)];
nansum(x1)
[nanmean(x1);nanstd(x1)]
[rho,pval] = corr(x1,...
    'type', 'spearman',...
    'Rows','pairwise')

x1_data = [
    nanmean(nanmean(allData{v}.behavior.choice_isGood(:,[1:30],:),2),3)*100,...
    nanmean(nanmean(allData{v}.behavior.happiness(:,[1:30],:),2),3)];
[nanmean(x1_data);nanstd(x1_data)]

x1_param = [
    allData{v}.model_learning{1}.parameter(:,2),...
    nanmean(allData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2)];
[nanmean(x1_param);nanstd(x1_param)]

x1_scid = [
    allData{v}.scid.current_mde,...
    allData{v}.scid.past_mde,...
    allData{v}.scid.current_mde==1|allData{1}.scid.past_mde==1];
[nanmean(x1_scid);nanstd(x1_scid)]


% non-depressed
v = 2;
list_block = list_version{v,2};
x2 = [
    allData{v}.demographics.gender==1,...
    allData{v}.demographics.age,...
    allData{v}.demographics.education,...
    allData{v}.questionnaire.PHQ_total(:,1),...
    allData{v}.questionnaire.MASQ_anhedonic_depression(:,1),...
    allData{v}.questionnaire.GAD_total(:,1),...
    allData{v}.questionnaire.AMI_behavioral(:,1)];
nansum(x2)
[nanmean(x2);nanstd(x2)]
[rho,pval] = corr(x2,...
    'type', 'spearman',...
    'Rows','pairwise')

x2_data = [
    nanmean(nanmean(allData{v}.behavior.choice_isGood(:,[1:30],:),2),3)*100,...
    nanmean(nanmean(allData{v}.behavior.happiness(:,[1:30],:),2),3)];
[nanmean(x2_data);nanstd(x2_data)]

x2_param = [
    allData{v}.model_learning{1}.parameter(:,2),...
    nanmean(allData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2)];
[nanmean(x2_param);nanstd(x2_param)]



% chi-square: gender
n1 = sum(x1(:,1));
N1 = numel(x1(:,1));
n2 = sum(x2(:,1));
N2 = numel(x2(:,1));
v1 = [repmat('a',N1,1); repmat('b',N2,1)];
v2 = [repmat(1,n1,1); repmat(2,N1-n1,1); repmat(1,n2,1); repmat(2,N2-n2,1)];
[tbl,chi2stat,pval] = crosstab(v1,v2)


% ranksum: demographic
pval_all = NaN(size(x1,2),1);
zval_all = NaN(size(x1,2),1);
for i = 1:size(x1,2)
     [pval,h,stats] = ranksum(x1(:,i),x2(:,i));
     zval_all(i) = stats.zval;
     pval_all(i) = pval;
end
[zval_all, pval_all]


% ranksum: data
pval_all = NaN(size(x1_data,2),1);
zval_all = NaN(size(x1_data,2),1);
for i = 1:size(x1_data,2)
     [pval,h,stats] = ranksum(x1_data(:,i),x2_data(:,i));
     zval_all(i) = stats.zval;
     pval_all(i) = pval;
end
[zval_all, pval_all]

% ranksum: parameter
pval_all = NaN(size(x1_param,2),1);
zval_all = NaN(size(x1_param,2),1);
for i = 1:size(x1_param,2)
     [pval,h,stats] = ranksum(x1_param(:,i),x2_param(:,i));
     zval_all(i) = stats.zval;
     pval_all(i) = pval;
end
[zval_all, pval_all]



% idx_select = allData{1}.scid.current_mde==1 | allData{1}.scid.past_mde==1;
% pval_all = NaN(size(x1_data,2),1);
% zval_all = NaN(size(x1_data,2),1);
% for i = 1:size(x1_data,2)
%      [pval,h,stats] = ranksum(x1_data(idx_select,i),x2_data(:,i));
%      zval_all(i) = stats.zval;
%      pval_all(i) = pval;
% end
% zval_all
% pval_all



%% fig1: learning average
list_color = {
    [0.8    0.15    0.15]; % red
    [0.7216, 0.7216, 0.7216]; % light gray
    };

clear h_data
figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*0.7;
fg.pp(4) = fg.pp(4)*1.1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on

clear group_data
for v = 1:nVersion
    
    switch v
        case {1}
            list_trial = [1:30];
        case {2}
            list_trial = [1:30];
    end
        
    subject_data = nanmean(nanmean(allData{v}.behavior.choice_isGood(:,[list_trial],:),3),2);
    subject_data = subject_data*100;
    
    nSub = size(subject_data,1);
    
    group_data{v} = subject_data;
    
    meanData = nanmean(subject_data,1);
    semData = nanstd(subject_data,0,1)./sqrt(nSub);
    
    %%%%% data %%%%%
    xData = v;
    yData = meanData;
    yData_sem = semData;

    h = bar(xData, yData,...
        'linewidth', 2,...
        'barwidth', 0.4,...
        'facecolor', list_color{v},...
        'edgecolor', 'k');

    e = errorbar(xData, yData, yData_sem,...
        'linestyle', 'none',...
        'linewidth', 2,...
        'color', 'k',...
        'CapSize',16);
    
end
set(gca,'fontsize', 32, 'linewidth', 2);
ylabel('Learning performance (%)');
xlim([0.5,2.5]);

yrange = [50,100];
yscale = max(yrange)-min(yrange);
ylim(yrange);
xlabel('Groups');
set(gca,'XTick',[1,2],'XTickLabel',{'MDD', 'Control'},...
    'YTick',[yrange(1):25:yrange(2)]);



% pval
pval_diff = ranksum(group_data{1},group_data{2})
hold on
if pval_diff<0.05
    if pval_diff<0.001
        text_pval = 'p<.001';
    else
        text_pval = sprintf('p=%.3f',pval_diff);
        text_pval(3) = [];
    end
    xpos = [1:2];
    ypos = max(nanmean(group_data{1}), nanmean(group_data{2}))*[1,1] + yscale*0.1;
    plot(xpos,ypos,...
        'linestyle', '-',...
        'linewidth', 4,...
        'color', 'k');
    text(mean(xpos), mean(ypos), text_pval,...
        'fontsize',20,...
        'horizontalalignment', 'center',...
        'verticalalignment', 'bottom',...
        'color', 'k');
    
end
hold off



% output figure
fig_file = fullfile(dirFig, sprintf('%s_behavior_avg_learning', dataset_name));
print(fig_file, '-dpdf');


%% fig 1: happiness average
list_color = {
    [0.8    0.15    0.15]; % red
    [0.7216, 0.7216, 0.7216]; % light gray
    };

% list_color = {
%     [0.6275,      0,      0]; % dark yed
%     [0.7216, 0.7216, 0.7216]; % light gray
%     };
clear h_data
figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*0.7;
fg.pp(4) = fg.pp(4)*1.1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on

clear group_data
for v = 1:2
    
    switch v
        case {1}
            list_trial = [1:30];
        case {2}
            list_trial = [1:30];
    end
    subject_data = nanmean(nanmean(allData{v}.behavior.happiness(:,[list_trial],:),3),2);
    
    subject_data = subject_data;
    
    nSub = size(subject_data,1);
    
    group_data{v} = subject_data;
    
    meanData = nanmean(subject_data,1);
    semData = nanstd(subject_data,0,1)./sqrt(nSub);
        
    %%%%% data %%%%%
    xData = v;
    yData = meanData;
    yData_sem = semData;
    h = bar(xData, yData,...
        'linewidth', 2,...
        'barwidth', 0.4,...
        'facecolor', list_color{v},...
        'edgecolor', 'k');

    errorbar(xData, yData, yData_sem,...
        'linestyle', 'none',...
        'linewidth', 2,...
        'color', 'k',...
        'CapSize', 16);
    
end
set(gca,'fontsize', 32, 'linewidth', 2);
ylabel('Momentary mood');
xlim([0.5,2.5]);

yrange = [25,75];
yscale = max(yrange)-min(yrange);
ylim(yrange);
xlabel('Groups');
set(gca,'XTick',[1,2],'XTickLabel',{'MDD', 'Control'},...
    'YTick',[yrange(1):25:yrange(2)]);



% pval
pval_diff = ranksum(group_data{1},group_data{2})
hold on
if pval_diff<0.05
    if pval_diff<0.001
        text_pval = 'p<.001';
    else
        text_pval = sprintf('p=%.3f',pval_diff);
        text_pval(3) = [];
    end
    xpos = [1:2];
    ypos = max(nanmean(group_data{1}), nanmean(group_data{2}))*[1,1] + yscale*0.1;
    plot(xpos,ypos,...
        'linestyle', '-',...
        'linewidth', 4,...
        'color', 'k');
    text(mean(xpos), mean(ypos), text_pval,...
        'fontsize',20,...
        'horizontalalignment', 'center',...
        'verticalalignment', 'bottom',...
        'color', 'k');
    
end
hold off

% output figure
fig_file = fullfile(dirFig, sprintf('%s_behavior_avg_happiness', dataset_name));
print(fig_file, '-dpdf');






%% fig 2: PCA
% x1 = score(version_idx==1,[1:2]);
% nanmean(x1)
% nanstd(x1)
% 
% x2 = score(version_idx==2,[1:2]);
% nanmean(x2)
% nanstd(x2)
% 
% [pval,h,stats] = ranksum(x1(:,1),x2(:,1))
% [pval,h,stats] = ranksum(x1(:,2),x2(:,2))



%%%%% explained variance %%%%%
list_color = {
    [0.8320, 0.3672, 0]
    [0, 0.4453, 0.6953];
    };
nComp = numel(explained);
clear h_data
figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*1.2;
fg.pp(4) = fg.pp(4)*1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on

plot([1:nComp]', explained,...
    'linestyle', '-',...
    'color', 'k',...
    'linewidth', 2,...
    'marker', 'o',...
    'markersize', 12,...
    'markerfacecolor', 'w',...
    'markeredgecolor', 'k');

for i = 1:2
    plot(i,explained(i),...
        'linestyle', 'none',...
        'color', 'k',...
        'linewidth', 2,...
        'marker', 'o',...
        'markersize', 12,...
        'markerfacecolor', list_color{i},...
        'markeredgecolor', 'k');
end


hold off

ylim([0,50]);

set(gca,'fontsize', 24, 'linewidth',2);
xlabel('Components')
ylabel('Explained variance (%)');

fig_file = fullfile(dirFig, sprintf('%s_pca_explained', dataset_name));
print(fig_file, '-dpdf');



%%%%% component coeff %%%%%
list_color_survey = {
    [251,180,174]/255;
    [179,205,227]/255;
    [204,235,197]/255;
    [222,203,228]/255;
    };

list_idx_survey = [
    ones(9,1);
    ones(10,1)*2;
    ones(7,1)*3;
    ones(6,1)*4;
    ];
nItem = numel(list_idx_survey);
for i = 1:2
    
    clear h_data
    figure;
    fg = fig_setting_default();
    % fg.pp(3) = fg.pp(3)*1.5;
    % fg.pp(4) = fg.pp(4)*0.8;

    fg.pp(3) = fg.pp(3)*1.2;
    fg.pp(4) = fg.pp(4)*0.7;
    
    set(gcf,...
        'Position',fg.pp,...
        'PaperPosition', fg.pp,...
        'PaperSize', fg.pp([3:4]));
    set(gcf, 'PaperPositionMode', 'Auto');
    hold on
    
    for j = 1:nItem
        
        idx_survey = list_idx_survey(j);
        
        xData = j;
        yData = coeff(j,i);
        h = bar(xData, yData,'barwidth',1,'linewidth',2);
        
        h.FaceColor = list_color_survey{idx_survey};
        h.EdgeColor = 'k';
        
        h_data(idx_survey) = h;
        
    end
    hold off
    
    set(gca,'fontsize',32,'linewidth',2);
    
    
    ylim([-0.4,0.4]);
    set(gca, 'YTick', [-0.3,0,0.3]);
    
    xlabel('Item');
    ylabel('Weights');
    switch i
        case {1}
            title('General depression dimension');
        case {2}
            title('Anhedonia dimension');
    end
    
    
    fig_file = fullfile(dirFig, sprintf('%s_pca_component_%d',dataset_name, i));
    print(fig_file, '-dpdf');
    
    
    
    if i==1
        legend(h_data, {'PHQ', 'MASQ-anhedonia', 'GAD', 'AMI-behavioral'},...
            'location', 'EastOutside',...
            'fontsize', 32);
        fig_file = fullfile(dirFig, 'legend_pca_component');
        print(fig_file, '-dpdf');
    end
    
end

%%%%% scatterhist of components %%%%%
list_color = {
    [1.0000    0.2    0.2]; % light red
    [0.4,0.4,0.4]; % dark gray
    };

list_marker = {
    '^';
    'o';
    };

figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*1.2;
fg.pp(4) = fg.pp(4)*1.2;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on
plot([-12,12],[0,0],...
    'linestyle','--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);
plot([0,0],[-12,12],...
    'linestyle','--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);

x1 = score(:,1);
x2 = score(:,2);
h = scatterhist(x1,x2,...
    'Group',version_idx,...
    'kernel','on',...
    'location', 'SouthWest',...
    'linestyle', {'-','-'},...
    'linewidth', [4,4],...
    'Color', {'r','k'},...
    'marker', '^o',...
    'markersize', [8,8],...
    'direction', 'out');

hold off

for v = 1:2
    
    % scatter
    h(1).Children(v).LineWidth = 0.5;

    h(1).Children(v).Marker = list_marker{3-v};

    h(1).Children(v).MarkerEdgeColor = 'w';
    h(1).Children(v).MarkerFaceColor = list_color{3-v};

    % x-axis
    h(2).Children(v+1).Color = list_color{3-v};

    % y-axis
    h(3).Children(v+1).Color = list_color{3-v};
    
end

set(gca,'fontsize',32,'linewidth',2);
xlim([-11,11]);
ylim([-11,11]);
set(gca, 'Xtick', [-10:5:10], 'Ytick', [-10:5:10]);

xlabel('General depression dimension');
ylabel('Anhedonia dimension');

switch dataset_name
    case {'match'}
        legend({'MDD', 'Control'});
    case {'nonmatch'}
        legend({'Depressed', 'Non-depressed'});
end

% legend
for v = 1:2    
    % scatter
    h(1).Children(v).MarkerSize = 16;
end
fig_file = fullfile(dirFig, 'legend_pca_component_dist');
print(fig_file, '-dpdf');

% data
h(1).Children = h(1).Children([2,1]);
h(2).Children([2,3]) = h(2).Children([3,2]);
h(3).Children([2,3]) = h(3).Children([3,2]);

legend off
for v = 1:2    
    % scatter
    % h(1).Children(v).MarkerSize = 6;
    h(1).Children(v).MarkerSize = 8;
end
fig_file = fullfile(dirFig, sprintf('%s_pca_component_dist', dataset_name));
print(fig_file, '-dpdf');


% group difference
for i = 1:2

    val_all = NaN(2,2);
    stat_all = NaN(1,2);

    idx_select = version_idx==1;
    x1 = combined_data_score(idx_select,i);

    idx_select = version_idx==2;
    x2 = combined_data_score(idx_select,i);

    val_all(1,1) = nanmean(x1);
    val_all(1,2) = nanmean(x2);
    val_all(2,1) = nanstd(x1);
    val_all(2,2) = nanstd(x2);


    [pval,h,stats] = ranksum(x1,x2);
    stat_all(1,1) = stats.zval;
    stat_all(1,2) = pval;

    val_all
    stat_all
end



% gender difference
gender_idx = [allData{1}.demographics.gender;
    allData{2}.demographics.gender];
age_idx = [allData{1}.demographics.age;
    allData{2}.demographics.age];
education_idx = [allData{1}.demographics.education;
    allData{2}.demographics.education];
for i = 1:2

    val_all = NaN(2,2);
    stat_all = NaN(1,2);

    idx_select = gender_idx==1;
    x1 = combined_data_score(idx_select,i);

    % idx_select = gender_idx==0;
    idx_select = gender_idx~=1;
    x2 = combined_data_score(idx_select,i);

    val_all(1,1) = nanmean(x1);
    val_all(1,2) = nanmean(x2);
    % val_all(2,1) = nanstd(x1);
    % val_all(2,2) = nanstd(x2);


    [pval,h,stats] = ranksum(x1,x2);
    stat_all(1,1) = stats.zval;
    stat_all(1,2) = pval;

    val_all
    stat_all
end

% yData = double(gender_idx==1);
% xData = combined_data_score(:,[1:2]);
% [reg_beta, dev, stats] = glmfit(xData, yData);
% [stats.beta,stats.p]

yData = combined_data_score(:,2);
xData = [version_idx, double(gender_idx==1)];
    
[reg_beta, dev, stats] = glmfit(xData, yData);
[stats.beta,stats.p]



% 
% 
% val_all = NaN(2,2);
% pval_all = NaN(1,2);
% for i = 1:2
% 
%     idx_select = version_idx==1;
%     x1 = score(idx_select,i);
% 
%     idx_select = version_idx==2;
%     x2 = score(idx_select,i);
% 
%     val_all(1,i) = nanstd(x1);
%     val_all(2,i) = nanstd(x2);
% 
%     [idx_h,p] = vartest2(x1,x2);
%     pval_all(1,i) = p;
% 
% end
% val_all
% pval_all
% 
% 
% 
% x1 = allData{1}.model_learning{3}.parameter;
% x2 = allData{2}.model_learning{3}.parameter;
% 
% nanmean(x1)
% nanstd(x1)
% 
% nanmean(x2)
% nanstd(x2)
% 
% ranksum(x1(:,2),x2(:,2))
% [h,p] = vartest2(x1(:,2),x2(:,2))


%% fig 2: between-subject effect
xData = [];
yData = [];
pca_data = [];
survey_mean = [];
demo = [];
dummy_group = [];

category_subgroup = [];

for v = 1:2
% for v = 2
% for v = 3

    list_block = list_version{v,2};
    nBlock = numel(list_block);
    nSurvey_max = list_version{v,5};

    % survey mean
    % survey_mean = [survey_mean;
    %     [nanmean(allData{v}.questionnaire.PHQ_total,2),...
    %     nanmean(allData{v}.questionnaire.MASQ_anhedonic_depression,2),...
    %     nanmean(allData{v}.questionnaire.GAD_total,2),...
    %     nanmean(allData{v}.questionnaire.AMI_behavioral,2)]];

    survey_mean = [survey_mean;
        [nanmean(mean(allData{v}.questionnaire.PHQ_item,2),3),...
        nanmean(mean(allData{v}.questionnaire.MASQ_anhedonic_depression_item,2),3),...
        nanmean(mean(allData{v}.questionnaire.GAD_item,2),3),...
        nanmean(mean(allData{v}.questionnaire.AMI_behavioral_item,2),3)]];
    
    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    surveyData = [];
    for i = 1:nSurvey_max
        
        temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
            allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            allData{v}.questionnaire.GAD_item(:,:,i),...
            allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
        
        surveyData = [surveyData; temp_surveyData];
        
    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;
    
    nSub = size(pca_score_new,1)/nSurvey_max;
    pca_score = NaN(nSub,2);
    for i = 1:2
        temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
        pca_score(:,i) = nanmean(temp_data,2);
    end

    pca_data = [pca_data; pca_score];

    if v==1
        current_mde = allData{v}.scid.current_mde;
        past_mde = allData{v}.scid.past_mde;
    else
        current_mde = zeros(nSub,1);
        past_mde = zeros(nSub,1);
    end
    demo = [demo;
        [allData{v}.demographics.age,...
        allData{v}.demographics.gender==1,...
        allData{v}.demographics.education]];

    % demo = [demo;
    %     [allData{v}.demographics.age,...
    %     allData{v}.demographics.gender==1,...
    %     allData{v}.demographics.education,...
    %     current_mde,...
    %     past_mde]];
    


    dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];

    category_subgroup = [category_subgroup;
        [allData{v}.demographics.gender,...
        allData{v}.redcap_info.antidepressant,...
        allData{v}.redcap_info.smoke_history,...
        allData{v}.redcap_info.substance_history]];

    % behavior_data = [nanmean(allData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2)]; % baseline mood
    % behavior_data = allData{v}.model_learning{1}.parameter(:,2); % rewSen

    % behavior_data = nanmean(allData{v}.behavior.happiness_mean,2); % mean mood
    behavior_data = nanmean(allData{v}.behavior.choice_pGood_average,2); % mean performance
    % behavior_data = nanmean(nanmean(allData{v}.behavior.choice_isGood(:,end-9:end,:),2),3); % mean performance

    yData = [yData; behavior_data];
end
pc1 = pca_data(:,1);
pc2 = pca_data(:,2);

% pc1 = combined_data_score(:,1);
% pc2 = combined_data_score(:,2);

% pc2 = survey_mean(:,2)-survey_mean(:,3);



%%%%% check %%%%%
% x1 = survey_mean(:,2)-survey_mean(:,3);
% % x1 = pc1;
% % x1 = pc2;
% % x1 = survey_mean;
% 
% % x2 = yData;
% x2 = pc1;
% % x2 = pc2;
% 
% 
% [rho,pval] = corr(x1,x2,'type','spearman')
% 
% 
% xData = zscore(survey_mean);
% [reg_beta,dev,stats] = glmfit(xData, pc1)
% [reg_beta,dev,stats] = glmfit(xData, pc2)



%%%%%%%%%%%%%%%%%



%%%%% check distribution %%%%%
% current_data = [pc1, pc2, survey_mean];
% 
% current_data = current_data([1:300],:);
% yData = yData([1:300],:);
% 
% list_cutoff = prctile(yData, [25,75]);
% % list_cutoff = prctile(yData, [50,50]);
% 
% meanData = [];
% semData = [];
% clear x1 x2
% for i = 1:2
% 
%     switch i
%         case {1}
%             idx_select = (yData<list_cutoff(1));
%         case {2}
%             idx_select = (yData>list_cutoff(1));
%     end
%     data_select = current_data(idx_select,:);
% 
%     switch i
%         case {1}
%             x1 = data_select;
%         case {2}
%             x2 = data_select;
%     end
% 
%     meanData = [meanData; nanmean(data_select)];
%     semData = [semData; nanstd(data_select,0,1)./sqrt(sum(idx_select))];
% 
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pval_all = NaN(6,1);
% for i = 1:6
%     pval_all(i) = ranksum(x1(:,i),x2(:,i));
% end
% pval_all



% meanData(:,[1:2]) = meanData(:,[1:2])*20;
% semData(:,[1:2]) = semData(:,[1:2])*20;



% 
% % q_select = [1:2];
% % q_select = [3:6];
% q_select = [1:6];
% figure;
% fig_setting_default;
% hold on
% 
% h = bar(meanData(:,q_select)');
% e = errorbar(h(1).XEndPoints, meanData(1,q_select)', semData(1,q_select)');
% set(e, 'linestyle', 'none', 'color', 'k');
% e = errorbar(h(2).XEndPoints, meanData(2,q_select)', semData(2,q_select)');
% set(e, 'linestyle', 'none', 'color', 'k');
% 
% hold off
% set(gca,'fontsize',24);
% ylabel('score');
% 
% % ylim([-2,2]);
% % set(gca,'XTick',q_select,'XTickLabel',{'PC1', 'PC2'});
% % set(gca,'XTick',[1:numel(q_select,'XTickLabel',{'PHQ', 'anhedonia', 'GAD', 'bAMI'});
% set(gca,'XTick',[1:numel(q_select)],'XTickLabel',{'PC1', 'PC2', 'PHQ', 'anhedonia', 'GAD', 'bAMI'});
% 
% % title('rewSen: match group (n=198)');
% % title('rewSen: depressed group (n=300)');
% 
% title('baselie mood: match group (n=198)');
% % title('baselie mood: depressed group (n=300)');
% 
% 
% legend(h, {'lower 25%', 'higher 25%'},...
%     'location', 'best');






% subgroup
% idx_subgroup = category_subgroup(:,1)==1; % female
% idx_subgroup = category_subgroup(:,1)==0; % male
% idx_subgroup = category_subgroup(:,2)==1; % antidepressant: yes
% idx_subgroup = category_subgroup(:,2)==0; % antidepressant: no
% idx_subgroup = category_subgroup(:,3)==1; % smoke_history: yes
% idx_subgroup = category_subgroup(:,3)==0; % smoke_history: no
% idx_subgroup = category_subgroup(:,4)==1; % substance_history: yes
% idx_subgroup = category_subgroup(:,4)==0; % substance_history: no

% demo = demo(idx_subgroup,:);
% demo(:,2) = [];
% dummy_group = dummy_group(idx_subgroup,:);
% yData = yData(idx_subgroup,:);
% pca_data = pca_data(idx_subgroup,:);
% pc1 = pc1(idx_subgroup,:);
% pc2 = pc2(idx_subgroup,:);



% dummy_group_residual
[reg_beta,dev,stats] = glmfit(pca_data, dummy_group);
yval = glmval(reg_beta, pca_data, 'identity');
dummy_group_residual = dummy_group - yval;

% pc1_residual
[reg_beta,dev,stats] = glmfit(dummy_group, pc1);
yval = glmval(reg_beta, dummy_group, 'identity');
pc1_residual = pc1 - yval;

% pc2_residual
[reg_beta,dev,stats] = glmfit(dummy_group, pc2);
yval = glmval(reg_beta, dummy_group, 'identity');
pc2_residual = pc2 - yval;



% standardization
xData = [pc1, pc2, pc1_residual, pc2_residual, dummy_group, dummy_group_residual, demo];
nSub = size(xData,1);
xData = (xData - repmat(nanmean(xData,1),nSub,1)) ./ repmat(nanstd(xData,0,1),nSub,1);


% regression
tbl = array2table([yData, xData],...
    'VariableNames',...
    {'yData', 'pc1', 'pc2', 'pc1_residual', 'pc2_residual',...
    'dummy_group', 'dummy_group_residual',...
    'age', 'gender', 'education'});

model_dummy = fitlm(tbl, 'yData ~ dummy_group + age + gender + education')
model_dummy_pcresidual = fitlm(tbl, 'yData ~ pc1_residual + pc2_residual + dummy_group + age + gender + education')

model_pc = fitlm(tbl, 'yData ~ pc1 + pc2 + age + gender + education')

model_pc1 = fitlm(tbl, 'yData ~ pc1 + age + gender + education')
model_pc2 = fitlm(tbl, 'yData ~ pc2 + age + gender + education')

model_dummy_pc = fitlm(tbl, 'yData ~ pc1 + pc2 + dummy_group + age + gender + education')
% model_others = fitlm(tbl, 'yData ~ pc1 + pc2 + dummy_group + age + gender + education')
% model_others = fitlm(tbl, 'yData ~ pc1 + pc2 + dummy_group_residual + age + gender + education')

LR = 2*(model_dummy_pcresidual.LogLikelihood - model_dummy.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = model_dummy_pcresidual.NumEstimatedCoefficients - model_dummy.NumEstimatedCoefficients
pval = 1 - chi2cdf(LR, df)

% full vs dummy only
LR = 2*(model_dummy_pc.LogLikelihood - model_dummy.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = model_dummy_pc.NumEstimatedCoefficients - model_dummy.NumEstimatedCoefficients
pval = 1 - chi2cdf(LR, df)

% full vs pc only
LR = 2*(model_dummy_pc.LogLikelihood - model_pc.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = model_dummy_pc.NumEstimatedCoefficients - model_pc.NumEstimatedCoefficients
pval = 1 - chi2cdf(LR, df)



m1 = model_pc1.ModelCriterion.AIC;
m2 = model_pc2.ModelCriterion.AIC;
m12 = model_pc.ModelCriterion.AIC;
m0 = model_dummy.ModelCriterion.AIC;
fprintf('m0 = %.2f\n', m0);
fprintf('m1 = %.2f\n', m1);
fprintf('m2 = %.2f\n', m2);
fprintf('m12 = %.2f\n', m12);

[m0;m1;m2;m12]-m1
[m0;m1;m2;m12]-m2


% pc1, pc2
xData = [pc1, pc2, demo];
nSub = size(xData,1);
xData = (xData - repmat(nanmean(xData,1),nSub,1)) ./ repmat(nanstd(xData,0,1),nSub,1);

% regression
tbl = array2table([yData, xData],...
    'VariableNames',...
    {'yData', 'pc1', 'pc2',...
    'age', 'gender', 'education'});

% model_dummy = fitlm(tbl, 'yData ~ dummy_group + age + gender + education')
model_dummy_pcresidual = fitlm(tbl, 'yData ~ pc1 + pc2 + age + gender + education')

LR = 2*(model_dummy_pcresidual.LogLikelihood - model_dummy.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = model_dummy_pcresidual.NumEstimatedCoefficients - model_dummy.NumEstimatedCoefficients
pval = 1 - chi2cdf(LR, df)


% tbl = array2table([yData, xData],...
%     'VariableNames',...
%     {'yData', 'pc1', 'pc2', 'pc1_residual', 'pc2_residual', 'dummy_group',...
%     'age', 'gender', 'education', 'current_mde', 'past_mde'});
% 
% model_dummy = fitlm(tbl, 'yData ~ dummy_group + age + gender + education + current_mde + past_mde')
% model_dummy_pcresidual = fitlm(tbl, 'yData ~ pc1_residual + pc2_residual + dummy_group + age + gender + education + current_mde + past_mde')
% 
% LR = 2*(model_dummy_pcresidual.LogLikelihood - model_dummy.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
% df = model_dummy_pcresidual.NumEstimatedCoefficients - model_dummy.NumEstimatedCoefficients
% pval = 1 - chi2cdf(LR, df)


% gender subgroup
% tbl = array2table([yData, xData],...
%     'VariableNames',...
%     {'yData', 'pc1', 'pc2', 'pc1_residual', 'pc2_residual', 'dummy_group',...
%     'age', 'education'});
% 
% model_dummy = fitlm(tbl, 'yData ~ dummy_group + age + education')
% model_dummy_pcresidual = fitlm(tbl, 'yData ~ pc1_residual + pc2_residual + dummy_group + age + education')
% 
% LR = 2*(model_dummy_pcresidual.LogLikelihood - model_dummy.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
% df = model_dummy_pcresidual.NumEstimatedCoefficients - model_dummy.NumEstimatedCoefficients
% pval = 1 - chi2cdf(LR, df)


reg_beta = model_dummy_pcresidual.Coefficients.Estimate(2:end);
reg_se = model_dummy_pcresidual.Coefficients.SE(2:end);
reg_pval = model_dummy_pcresidual.Coefficients.pValue(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]

zval_diff = (reg_beta(1)-reg_beta(3))./sqrt(reg_se(1)^2+reg_se(3)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
% pval_diff = 1;
comp_13_pval = [1,3,pval_diff]

zval_diff = (reg_beta(2)-reg_beta(3))./sqrt(reg_se(2)^2+reg_se(3)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
% pval_diff = 1;
comp_23_pval = [2,3,pval_diff]


clear result_summary
result_summary.beta = reg_beta(1:3);
result_summary.se = reg_se(1:3);
result_summary.p = reg_pval(1:3);
result_summary.pval_diff = [comp_12_pval;comp_13_pval;comp_23_pval];




%%%%% check %%%%%
% idx_group = (dummy_group==1);
% 
% data_q = pc2(idx_group);
% data_param = yData(idx_group);
% 
% [val,idx_order] = sort(data_q,'ascend')
% data_q = data_q(idx_order)
% data_param = data_param(idx_order)
% 
% x1 = data_param(1:25);
% x2 = data_param(end-24:end);
% 
% [mean(x1),mean(x2)]
% ranksum(x1,x2)


%%%%%%%%%%%%%%%%%



%%%%% figure: bar %%%%%
yrange = [-6,3];

clear h_data
yscale = max(yrange)-min(yrange);

list_color = {
    [0.8320, 0.3672, 0]
    [0, 0.4453, 0.6953];
    [1,1,1];
    };

figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*1;
fg.pp(4) = fg.pp(4)*1.2;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on
plot([0.5,3.5],[0,0],...
    'linestyle', '--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);
for i = 1:3

    xData = i;
    yData = result_summary.beta(i);
    yData_sem = result_summary.se(i);
    yData_pval = result_summary.p(i);

    h = bar(xData, yData,...
        'linewidth', 2,...
        'barwidth', 0.35,...
        'facecolor', list_color{i},...
        'edgecolor', 'k');

    errorbar(xData, yData, yData_sem,...
        'linestyle', 'none',...
        'linewidth', 2,...
        'color', 'k',...
        'CapSize',16);


    pval = yData_pval;
    if pval<0.05
        if pval<0.001
            % text_pval = 'P<.001';
            text_pval = 'P<0.001';
        elseif pval<0.01
            text_pval = sprintf('P=%.3f',pval);
            % text_pval(3) = [];
        else 
            text_pval = sprintf('P=%.2f',pval);
            % text_pval(3) = [];
        end
        xpos = xData;
        ypos = yData - yData_sem - yscale*0.05;
        text(xpos, ypos, text_pval,...
            'fontsize',24,...
            'horizontalalignment', 'center',...
            'verticalalignment', 'middle',...
            'color', 'k');
    end


end

idx_sig = 0;
for i = 1:3

    pval_diff = result_summary.pval_diff(i,3);
    if pval_diff<0.05
        idx_sig = idx_sig + 1;
        if pval_diff<0.001
            % text_pval = 'P<.001';
            text_pval = 'P<0.001';
        elseif pval_diff<0.01
            text_pval = sprintf('P=%.3f',pval_diff);
            % text_pval(3) = [];
        else
            text_pval = sprintf('P=%.2f',pval_diff);
            % text_pval(3) = [];
        end
        xpos = result_summary.pval_diff(i,[1,2]);
        ypos = max(max(result_summary.beta+result_summary.se),0)*[1,1] + yscale*(0.1);
        plot(xpos,ypos,...
            'linestyle', '-',...
            'linewidth', 4,...
            'color', 'k');
        text(mean(xpos), mean(ypos), text_pval,...
            'fontsize',24,...
            'horizontalalignment', 'center',...
            'verticalalignment', 'bottom',...
            'color', 'k');

    end
end

hold off
set(gca,'fontsize',30,'linewidth',2);
% xlabel('Regressor');
xlabel(sprintf('\n\n'));
ylabel('Regression coefficient');

xlim([0.5,3.5]);
ylim(yrange);
set(gca,'YTick',[-6:3:3]);

set(gca,'XTick',[1,2,3],'XTickLabel',{});
switch dataset_name
    case {'match'}
        text_xticklabel = {sprintf('General\ndepression\ndimension'), sprintf('Anhedonia\ndimension'), sprintf('MDD\ndiagnosis')};
    case {'nonmatch'}
        text_xticklabel = {sprintf('General\ndepression\ndimension'), sprintf('Anhedonia\ndimension'), sprintf('group')};
end
list_xShift = [-0.15, 0, 0.15];
for i = 1:3
    xpos = i + list_xShift(i);
    ypos = min(yrange) - (max(yrange)-min(yrange))*0.02;
    text(xpos, ypos, text_xticklabel{i},...
        'fontsize', 30,...
        'HorizontalAlignment', 'Center',...
        'VerticalAlignment', 'top');
end

% output figure
% fig_file = fullfile(dirFig, sprintf('%s_reg_mood_pca_acrossSubject', dataset_name));
fig_file = fullfile(dirFig, sprintf('%s_reg_learning_pca_acrossSubject', dataset_name));
print(fig_file, '-dpdf');






%% fig 3: monthly logitudinal analysis (m2-m6)
v = 3;

%%%%% get pc score %%%%%
nSub = size(longitudinalData{v}.questionnaire.PHQ_total,1);

nSurvey_total = 0;
surveyData = [];

nSurvey_max = list_version{v,5};
nSurvey_total = nSurvey_total + nSurvey_max;

for i = 1:nSurvey_max

    temp_surveyData = [longitudinalData{v}.questionnaire.PHQ_item(:,:,i),...
        longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
        longitudinalData{v}.questionnaire.GAD_item(:,:,i),...
        longitudinalData{v}.questionnaire.AMI_behavioral_item(:,:,i)];

    surveyData = [surveyData; temp_surveyData];

end

% apply to questionnaire at different times
pca_coeff = combined_data_coeff;

surveyData_new = surveyData;
surveyData_new = surveyData_new - combined_data_mu;
pca_coeff_new = pca_coeff;
pca_score_new = surveyData_new*pca_coeff_new;

pc1 = reshape(pca_score_new(:,1), nSub, nSurvey_total);
pc2 = reshape(pca_score_new(:,2), nSub, nSurvey_total);

% data
list_block = list_version{v, 2};

% mood
param_mood = longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block);

% rewSen
param_rewSen = longitudinalData{v}.model_learning{2}.parameter(:,1+list_block);


%%%%% average item score %%%%%
survey_mean = [];
for i = 1:nSurvey_max
    survey_mean = [survey_mean;
        [mean(allData{v}.questionnaire.PHQ_item(:,:,i),2),...
        mean(allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),2),...
        mean(allData{v}.questionnaire.GAD_item(:,:,i),2),...
        mean(allData{v}.questionnaire.AMI_behavioral_item(:,:,i),2)]];
end
anhedonia_minus_anxiety = survey_mean(:,2)-survey_mean(:,3);

%%%%% combined: mean vs change %%%%
nMonth = size(pc1,2);
list_month = [1:nMonth];
demo = [
    longitudinalData{v}.demographics.age,...
    double(longitudinalData{v}.demographics.gender==1),...
    longitudinalData{v}.demographics.education];

clear xData_combined
list_subno_combined= [];
list_monthno_combined = [];
for m = 1:nMonth

    % select months
    idx_month = m;
    % idx_mean = list_month(list_month~=m);
    idx_mean = list_month;

    % organize data
    pc1_mean = nanmean(pc1(:, idx_mean),2);
    pc2_mean = nanmean(pc2(:, idx_mean),2);
    mood_mean = nanmean(param_mood(:, idx_mean),2);
    rewSen_mean = nanmean(param_rewSen(:, idx_mean),2);

    % residual
    pc1_t = pc1(:, idx_month);
    pc2_t = pc2(:, idx_month);

    [reg_beta, dev, stats] = glmfit(pc2_t, pc1_t);
    pc1_t_residual = stats.resid + reg_beta(1); % residual + constant

    [reg_beta, dev, stats] = glmfit(pc1_t, pc2_t);
    pc2_t_residual = stats.resid + reg_beta(1); % residual + constant


    xData = [
        pc1(:,idx_month),...
        pc2(:,idx_month),...
        pc1_mean, pc1(:,idx_month)-pc1_mean,...
        pc2_mean, pc2(:,idx_month)-pc2_mean,...
        param_mood(:,idx_month), mood_mean, param_mood(:,idx_month)-mood_mean,...
        param_rewSen(:,idx_month), rewSen_mean, param_rewSen(:,idx_month)-rewSen_mean,...
        pc1_t_residual, pc2_t_residual];

    xData = [xData, demo];

    list_subno = [1:size(xData,1)]';
    list_monthno = ones(size(xData,1),1)*m;

    if m==1
        xData_combined = xData;
        list_subno_combined = list_subno;
        list_monthno_combined = list_monthno;
    else
        xData_combined = [xData_combined; xData];
        list_subno_combined = [list_subno_combined; list_subno];
        list_monthno_combined = [list_monthno_combined; list_monthno];
    end

end
xData_combined = [xData_combined, anhedonia_minus_anxiety];


% standarization
xData_zscore = (xData_combined - repmat(nanmean(xData_combined,1),size(xData_combined,1),1)) ./ repmat(nanstd(xData_combined,0,1),size(xData_combined,1),1);

% convert to table
tbl = array2table([xData_combined, list_subno_combined, list_monthno_combined],...
    'VariableNames',...
    {'pc1_t',...
    'pc2_t',...
    'pc1_mean', 'pc1_change',...
    'pc2_mean', 'pc2_change',...
    'mood_t', 'mood_mean', 'mood_change',...
    'rewSen_t', 'rewSen_mean', 'rewSen_change',...
    'pc1_t_residual', 'pc2_t_residual',...
    'age', 'gender', 'education',...
    'anhedonia_minus_anxiety',...
    'subno', 'monthno'});

tbl_zscore = array2table([xData_zscore, list_subno_combined, list_monthno_combined],...
    'VariableNames',...
    {'pc1_t',...
    'pc2_t',...
    'pc1_mean', 'pc1_change',...
    'pc2_mean', 'pc2_change',...
    'mood_t', 'mood_mean', 'mood_change',...
    'rewSen_t', 'rewSen_mean', 'rewSen_change',...
    'pc1_t_residual', 'pc2_t_residual',...
    'age', 'gender', 'education',...
    'anhedonia_minus_anxiety',...
    'subno', 'monthno'});

writetable(tbl_zscore, 'data_lme.csv');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% shuffle month order %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% pc1 %%%%%
nPerm = 100;
stat_perm = NaN(nPerm,1);

% true
lme_formula = 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_t + rewSen_change + pc2_t|subno)';
% lme_formula = 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_t + rewSen_change|subno)';
model_true = fitlme(tbl_zscore, lme_formula);
model_mean = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)');
% model_null = fitlme(tbl_zscore, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)');

nSub = max(tbl_zscore.subno);

for idx_perm = 1:nPerm

    fprintf('%d/%d\n', idx_perm, nPerm);

    xData_perm = tbl_zscore;

    % shuffle within subjects
    for s = 1:nSub

        idx_sub = (xData_perm.subno==s);

        order_random = randperm(sum(idx_sub));
        list_var = {
            'pc2_t';
            'mood_t';
            'rewSen_change';
            };
        for i = 1:numel(list_var)
            varname = list_var{i};
            val = xData_perm.(varname)(idx_sub);
            xData_perm.(varname)(idx_sub) = val(order_random);
        end

    end

    model_perm = fitlme(xData_perm, lme_formula);
    % stat_perm(idx_perm) = model_perm.LogLikelihood;
    stat_perm(idx_perm) = model_perm.ModelCriterion.BIC;
    % stat_perm(idx_perm) = model_perm.Coefficients.Estimate(3);

end

% stat_true = model_true.LogLikelihood;
% stat_null = model_null.LogLikelihood;

% stat_true =  2*(stat_true-stat_null);
% stat_perm = 2*(stat_perm-stat_null);

% stat_true = model_true.Coefficients.Estimate(3);
% stat_mean = model_mean.Coefficients.Estimate(3);

stat_true = model_true.ModelCriterion.BIC;
stat_mean = model_mean.ModelCriterion.BIC;

figure;
hold on
histogram(stat_perm);
xline(stat_true, 'r');
xline(stat_mean, 'g');
hold off


%%%% pc2 %%%%%
nPerm = 100;
stat_perm = NaN(nPerm,1);

% true
lme_formula = 'pc2_t ~ mood_mean + mood_change + rewSen_t + age + gender + education + pc1_t + (1 + mood_change + rewSen_t + pc1_t|subno)';
% lme_formula = 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_t + rewSen_change|subno)';
model_true = fitlme(tbl_zscore, lme_formula);
model_mean = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + pc1_t + (1 + mood_change + pc1_t|subno)');
% model_null = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + age + gender + education + pc1_t + (1 + mood_change + rewSen_t + pc1_t|subno)');

nSub = max(tbl_zscore.subno);

for idx_perm = 1:nPerm

    fprintf('%d/%d\n', idx_perm, nPerm);

    xData_perm = tbl_zscore;

    % shuffle within subjects
    for s = 1:nSub

        idx_sub = (xData_perm.subno==s);

        order_random = randperm(sum(idx_sub));
        list_var = {
            'pc1_t';
            'rewSen_t';
            'mood_change';
            };
        for i = 1:numel(list_var)
            varname = list_var{i};
            val = xData_perm.(varname)(idx_sub);
            xData_perm.(varname)(idx_sub) = val(order_random);
        end

    end

    model_perm = fitlme(xData_perm, lme_formula);
    % stat_perm(idx_perm) = model_perm.LogLikelihood;
    stat_perm(idx_perm) = model_perm.ModelCriterion.BIC;
    % stat_perm(idx_perm) = model_perm.Coefficients.Estimate(5);

end

% stat_true = model_true.LogLikelihood;
% stat_null = model_null.LogLikelihood;

% stat_true =  2*(stat_true-stat_null);
% stat_perm = 2*(stat_perm-stat_null);

% stat_true = model_true.Coefficients.Estimate(5);

stat_true = model_true.ModelCriterion.BIC;
stat_mean = model_mean.ModelCriterion.BIC;

figure;
hold on
histogram(stat_perm);
xline(stat_true, 'r');
xline(stat_mean, 'g');
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% out-of-month prediction %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % keep subjects who have data in all the months
% nSub = max(tbl_zscore.subno);
% idx_valid = zeros(numel(tbl_zscore.subno),1);
% for s = 1:nSub
% 
%     idx_sub = (tbl_zscore.subno==s);
%     current_data = tbl_zscore(idx_sub,:);
%     if ~isnan(sum(sum(current_data.Variables)))
%         idx_valid(idx_sub) = 1;
%     end
% end
% tbl_zscore_valid = tbl_zscore(idx_valid==1,:);
% 
% %%%%% pc1 %%%%%
% list_month = [1:5];
% nMonth = numel(list_month);
% 
% sublist_valid = unique(tbl_zscore_valid.subno);
% nSub_valid = numel(sublist_valid);
% 
% pc_state = NaN(nSub_valid, nMonth);
% yhat_state = NaN(nSub_valid, nMonth);
% yhat_trait = NaN(nSub_valid, nMonth);
% 
% % prediction from mean
% idx_select = (tbl_zscore_valid.monthno==1);
% x_mean = tbl_zscore_valid.mood_mean(idx_select);
% y_mean = tbl_zscore_valid.pc1_mean(idx_select);
% [reg_beta,dev,stats] = glmfit(x_mean,y_mean);
% yhat_mean = glmval(reg_beta, x_mean, 'identity');
% 
% % within-subject prediction
% for s = 1:nSub_valid
% 
%     idx_sub = (tbl_zscore_valid.subno==sublist_valid(s));
%     x = tbl_zscore_valid.mood_t(idx_sub);
%     y = tbl_zscore_valid.pc1_t(idx_sub);
% 
%     for m = 1:nMonth
% 
%         train_idx = (list_month~=m);
%         test_idx = (list_month==m);
% 
%         [reg_beta] = glmfit(x(train_idx), y(train_idx));
%         yhat = glmval(reg_beta, x(test_idx), 'identity');
%         % yhat = x(test_idx)*reg_beta(2) + mean(y);
% 
%         % [reg_beta] = robustfit(x(train_idx), y(train_idx));
%         % yhat = x(test_idx)*reg_beta(2) + reg_beta(1);
% 
%         % state
%         yhat_state(s,m) = yhat;
% 
%         % trait
%         yhat_trait(s,m) = yhat_mean(s,1);
% 
%         % pc_state
%         pc_state(s,m) = y(test_idx);
% 
%     end
% 
% end
% 
% mean((pc_state - yhat_state).^2)
% mean((pc_state - yhat_trait).^2)






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% out-of-month prediction %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% keep subjects who have data in all the months
% nSub = max(tbl_zscore.subno);
% idx_valid = zeros(numel(tbl_zscore.subno),1);
% for s = 1:nSub
% 
%     idx_sub = (tbl_zscore.subno==s);
%     current_data = tbl_zscore(idx_sub,:);
%     if ~isnan(sum(sum(current_data.Variables)))
%         idx_valid(idx_sub) = 1;
%     end
% end

tbl_valid = tbl;
nSub_valid = numel(unique(tbl_valid.subno));


%%%% pc1 %%%%%
list_month = [1:5];
nMonth = numel(list_month);

result_rmse = NaN(nMonth, 2);
result_logp = NaN(nSub_valid, nMonth, 2);
result_r = NaN(nMonth, 2);
all_y = NaN(nSub_valid, nMonth);
all_yhat_state = NaN(nSub_valid, nMonth);
all_yhat_trait = NaN(nSub_valid, nMonth);

for m = 1:nMonth

    train_idx = (tbl_valid.monthno~=m);
    test_idx = (tbl_valid.monthno==m);

    data_train = tbl_valid(train_idx,:);
    data_test = tbl_valid(test_idx,:);

    % update mean measure based on trained months only
    for s = 1:nSub_valid

        idx_subject_train = (data_train.subno==s);

        subject_mood = data_train.mood_t(idx_subject_train);
        subject_rewSen = data_train.rewSen_t(idx_subject_train);

        mood_mean = nanmean(subject_mood);
        rewSen_mean = nanmean(subject_rewSen);

        % update data_train
        data_train.mood_mean(idx_subject_train) = mood_mean;
        data_train.mood_change(idx_subject_train) = data_train.mood_t(idx_subject_train) - mood_mean;
        data_train.rewSen_mean(idx_subject_train) = rewSen_mean;
        data_train.rewSen_change(idx_subject_train) = data_train.rewSen_t(idx_subject_train) - rewSen_mean;
        
        % update data_test
        idx_subject_test = (data_test.subno==s);
        data_test.mood_mean(idx_subject_test) = mood_mean;
        data_test.mood_change(idx_subject_test) = data_test.mood_t(idx_subject_test) - mood_mean;
        data_test.rewSen_mean(idx_subject_test) = rewSen_mean;
        data_test.rewSen_change(idx_subject_test) = data_test.rewSen_t(idx_subject_test) - rewSen_mean;
    end

    % fit model
    % model_state = fitlme(data_train, 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_t + rewSen_change + pc2_t|subno)');
    % model_trait = fitlme(data_train, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)');
    % y = data_test.pc1_t;
  
    model_state = fitlme(data_train, 'pc2_t ~ mood_mean + mood_change + rewSen_t + age + gender + education + pc1_t + (1 + mood_change + rewSen_t + pc1_t|subno)');
    model_trait = fitlme(data_train, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + pc1_t + (1 + mood_change + pc1_t|subno)');
    y = data_test.pc2_t;
  
    % prediction
    yhat_state = predict(model_state, data_test, 'Conditional', true);
    yhat_trait = predict(model_trait, data_test, 'Conditional', true);

    all_y(:,m) = y;

    % RMSE
    % rmse_state = sqrt(nanmean((yhat_state-y).^2));
    % rmse_trait = sqrt(nanmean((yhat_trait-y).^2));
    % result_rmse(m,1) = rmse_state;
    % result_rmse(m,2) = rmse_trait;

    all_yhat_state(:,m) = yhat_state;
    all_yhat_trait(:,m) = yhat_trait;

    
    % correlation
    [r_state] = corr(yhat_state, y, 'type','pearson');
    [r_trait] = corr(yhat_trait, y, 'type','pearson');
    result_r(m,1) = r_state;
    result_r(m,2) = r_trait;


    % log predictive density
    s2_state = model_state.MSE;
    s2_trait = model_trait.MSE;

    result_logp(:,m,1) = -0.5*log(2*pi*s2_state) - (y - yhat_state).^2/(2*s2_state);
    result_logp(:,m,2) = -0.5*log(2*pi*s2_trait) - (y - yhat_trait).^2/(2*s2_trait);



end
% compare
% logp_state = result_logp(:,:,1);
% logp_trait = result_logp(:,:,2);
% diff_LPPD = nansum(logp_state) - nansum(logp_trait)
% nanmean(logp_state-logp_trait)
% nansum(logp_state-logp_trait)
% nanmedian(logp_state-logp_trait)
% 
% hist(mean(logp_state-logp_trait,2))
% 
% for i = 1:5
%     signrank(logp_state(:,i),logp_trait(:,i))
%     [median(logp_state(:,i)), median(logp_trait(:,i))]
% end

% RMSE
rmse_state = sqrt(nanmean((all_yhat_state(:)-all_y(:)).^2));
rmse_trait = sqrt(nanmean((all_yhat_trait(:)-all_y(:)).^2));
result_rmse = [rmse_state, rmse_trait]
100*(rmse_trait-rmse_state)/max(result_rmse)

% compare abs_error for each month
abs_error_state = (all_yhat_state-all_y).^2;
abs_error_trait = (all_yhat_trait-all_y).^2;
% abs_error_state = abs(all_yhat_state-all_y);
% abs_error_trait = abs(all_yhat_trait-all_y);
result_all = [];
for m = 1:nMonth

    x1 = abs_error_state(:,m);
    x2 = abs_error_trait(:,m);

    idx_notnan = ~isnan(x1+x2);
    x1 = x1(idx_notnan);
    x2 = x2(idx_notnan);

    pval = signrank(x1, x2);

    rho_state = corr(all_yhat_state(:,m), all_y(:,m), 'rows', 'pairwise');
    rho_trait = corr(all_yhat_trait(:,m), all_y(:,m), 'rows', 'pairwise');

    % result_all(m,:) = [mean(x1), mean(x2), numel(x1), mean(x1<x2), pval, rho_state, rho_trait];
    result_all(m,:) = [mean(x1), mean(x2), numel(x1), mean(x2<x1), pval, rho_state, rho_trait];
    
end
result_all
mean(result_all)
% 
% x1 = abs_error_state(:);
% x2 = abs_error_trait(:);
% 
% idx_notnan = ~isnan(x1+x2);
% x1 = x1(idx_notnan);
% x2 = x2(idx_notnan);
% 
% pval = signrank(x1, x2);
% [mean(x1), mean(x2), numel(x1), mean(x1<x2), pval]
% % [mean(x1), mean(x2), numel(x1), mean(x2<x1), pval]
% 
% rho_state = corr(all_yhat_state(:), all_y(:), 'rows', 'pairwise')
% rho_trait = corr(all_yhat_trait(:), all_y(:), 'rows', 'pairwise')





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% linear mixed-effect model %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% pc1 %%%%%
model_full = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_change + rewSen_change + pc2_t|subno)')

model_mood_t = fitlme(tbl_zscore, 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_t + rewSen_change + pc2_t|subno)')
model_mood_mean = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)')

model_mood_change = fitlme(tbl_zscore, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_change + rewSen_change + pc2_t|subno)')

% model_mood_mean_change = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_change + rewSen_change + pc2_t|subno)')

% model_mood_null = fitlme(tbl_zscore, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)')
% model_mood_null = fitlme(tbl_zscore, 'pc1_t ~ 1 + (1|subno)')
% 
% model_mood_mean = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + age + gender + education + pc2_t + (1 + pc2_t|subno)')
% model_mood_change = fitlme(tbl_zscore, 'pc1_t ~ mood_change + age + gender + education + pc2_t + (1 + mood_change + pc2_t|subno)')
% model_mood_mean_change = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + mood_change + age + gender + education + pc2_t + (1 + mood_change + pc2_t|subno)')




% Bayes factor: state vs trait model
bic_best = model_mood_t.ModelCriterion.BIC;
bic_alternative = model_mood_mean.ModelCriterion.BIC;
% bic_alternative = model_full.ModelCriterion.BIC;
bayes_factor = exp((bic_alternative-bic_best)/2)



% % list_check = [10:20:160]';
% list_check = [3,4,5]';
% temp_bf = NaN(numel(list_check), 3);
% for i=1:numel(list_check)
% 
%     nSub_check = list_check(i);
%     % model_mood_t = fitlme(tbl_zscore(tbl_zscore.subno<=nSub_check,:), 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_t + rewSen_change + pc2_t|subno)');
%     % model_mood_mean = fitlme(tbl_zscore(tbl_zscore.subno<=nSub_check,:), 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)');
% 
%     model_mood_t = fitlme(tbl_zscore(tbl_zscore.monthno<=nSub_check,:), 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_t + rewSen_change + pc2_t|subno)');
%     model_mood_mean = fitlme(tbl_zscore(tbl_zscore.monthno<=nSub_check,:), 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)');
% 
%     bic_best = model_mood_t.ModelCriterion.BIC;
%     bic_alternative = model_mood_mean.ModelCriterion.BIC;
%     bayes_factor = exp((bic_alternative-bic_best)/2);
% 
% 
%     temp_bf(i,:) = [bayes_factor, bic_best, bic_alternative];
% 
% end






% model_full = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + mood_change + age + gender + education + (1 + mood_change |subno)')
% 
% model_mood_t = fitlme(tbl_zscore, 'pc1_t ~ mood_t + age + gender + education + (1 + mood_t|subno)')
% model_mood_mean = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + age + gender + education + (1|subno)')
% model_mood_change = fitlme(tbl_zscore, 'pc1_t ~ mood_change + age + gender + education + (1 + mood_change |subno)')


% model_full = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
% model_full = fitlme(tbl_zscore, 'pc1_t_residual ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')

% model_without_mood_mean = fitlme(tbl, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
% model_without_mood_change = fitlme(tbl, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_change|subno)')
% model_without_mood = fitlme(tbl, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_change|subno)')

% model_1 = model_full;
% % model_2 = model_without_mood_mean;
% % model_2 = model_without_mood_change;
% model_2 = model_without_mood;
% 
% % model comparison
% model_comparison = compare(model_2, model_1)

% reg_beta = model_full.Coefficients.Estimate(2:5);
% reg_se = model_full.Coefficients.SE(2:5);
% reg_pval = model_full.Coefficients.pValue(2:5);

reg_beta = model_full.Coefficients.Estimate(3:6);
reg_se = model_full.Coefficients.SE(3:6);
reg_pval = model_full.Coefficients.pValue(3:6);


clear comp_pval
zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_pval(1,:) = [1,2,pval_diff];

zval_diff = (reg_beta(3)-reg_beta(4))./sqrt(reg_se(3)^2+reg_se(4)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_pval(2,:) = [3,4,pval_diff];

clear result_summary
result_summary.beta = reg_beta;
result_summary.se = reg_se;
result_summary.p = reg_pval;
result_summary.pval_diff = comp_pval;



%%%%% pc2 %%%%%
model_full = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + pc1_t + (1 + mood_change + rewSen_change + pc1_t|subno)')

model_rewSen_mean = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + pc1_t + (1 + mood_change + pc1_t|subno)')
model_rewSen_t = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + rewSen_t + age + gender + education + pc1_t + (1 + mood_change + rewSen_t + pc1_t|subno)')

model_rewSen_change = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + rewSen_change + age + gender + education + pc1_t + (1 + mood_change + rewSen_change + pc1_t|subno)')


bic_best = model_rewSen_mean.ModelCriterion.BIC;
bic_alternative = model_rewSen_t.ModelCriterion.BIC;
bayes_factor = exp((bic_alternative-bic_best)/2)



% list_check = [10:20:160]';
% % list_check = [3,4,5]';
% temp_bf = NaN(numel(list_check), 3);
% for i=1:numel(list_check)
% 
%     nSub_check = list_check(i);
% 
%     model_rewSen_mean = fitlme(tbl_zscore(tbl_zscore.subno<=nSub_check,:), 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + pc1_t + (1 + mood_change + pc1_t|subno)');
%     model_rewSen_t = fitlme(tbl_zscore(tbl_zscore.subno<=nSub_check,:), 'pc2_t ~ mood_mean + mood_change + rewSen_t + age + gender + education + pc1_t + (1 + mood_change + rewSen_t + pc1_t|subno)');
% 
%     % model_rewSen_mean = fitlme(tbl_zscore(tbl_zscore.monthno<=nSub_check,:), 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + pc1_t + (1 + mood_change + pc1_t|subno)');
%     % model_rewSen_t = fitlme(tbl_zscore(tbl_zscore.monthno<=nSub_check,:), 'pc2_t ~ mood_mean + mood_change + rewSen_t + age + gender + education + pc1_t + (1 + mood_change + rewSen_t + pc1_t|subno)');
% 
%     bic_best = model_rewSen_mean.ModelCriterion.BIC;
%     bic_alternative = model_rewSen_t.ModelCriterion.BIC;
%     bayes_factor = exp((bic_alternative-bic_best)/2);
% 
%     temp_bf(i,:) = [bayes_factor, bic_best, bic_alternative];
% 
% end



% model_full = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
% model_full = fitlme(tbl_zscore, 'pc2_t_residual ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')

% model_without_mood_mean = fitlme(tbl, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
% model_without_mood_change = fitlme(tbl, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_change|subno)')
% model_without_mood = fitlme(tbl, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_change|subno)')

% model_1 = model_full;
% % model_2 = model_without_mood_mean;
% % model_2 = model_without_mood_change;
% model_2 = model_without_mood;
% 
% % model comparison
% model_comparison = compare(model_2, model_1)

reg_beta = model_full.Coefficients.Estimate(3:6);
reg_se = model_full.Coefficients.SE(3:6);
reg_pval = model_full.Coefficients.pValue(3:6);



clear comp_pval
zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_pval(1,:) = [1,2,pval_diff];

zval_diff = (reg_beta(3)-reg_beta(4))./sqrt(reg_se(3)^2+reg_se(4)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_pval(2,:) = [3,4,pval_diff];

clear result_summary
result_summary.beta = reg_beta;
result_summary.se = reg_se;
result_summary.p = reg_pval;
result_summary.pval_diff = comp_pval;





% figure: bar
yrange = [-0.4,0.2];
% yrange = [-0.3,0.1];

clear h_data
yscale = max(yrange)-min(yrange);

list_color = {
    [0.5020, 0, 0.4549];
    [0.5020, 0, 0.4549];
    [0.1608, 0.5490, 0.5490];
    [0.1608, 0.5490, 0.5490];
    };

figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*1.4;
fg.pp(4) = fg.pp(4)*1.4;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on
% plot([0.5,4.5],[0,0],...
%     'linestyle', '--',...
%     'linewidth', 2,...
%     'color', [0.5,0.5,0.5]);
yline(0,...
    'linestyle', '--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);
xline(2.5,...
    'linestyle', '--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);
for i = 1:4

    xData = i;
    yData = result_summary.beta(i);
    yData_sem = result_summary.se(i);
    yData_pval = result_summary.p(i);

    h = bar(xData, yData,...
        'linewidth', 2,...
        'barwidth', 0.4,...
        'facecolor', list_color{i},...
        'edgecolor', 'k');

    errorbar(xData, yData, yData_sem,...
        'linestyle', 'none',...
        'linewidth', 2,...
        'color', 'k',...
        'CapSize',16);


    pval = yData_pval;
    if pval<0.05
        if pval<0.001
            % text_pval = 'P<.001';
            text_pval = 'P<0.001';
        elseif pval<0.01
            text_pval = sprintf('P=%.3f',pval);
            % text_pval(3) = [];
        else
            text_pval = sprintf('P=%.2f',pval);
            % text_pval(3) = [];
        end
        xpos = xData;
        ypos = yData - yData_sem - yscale*0.05;
        text(xpos, ypos, text_pval,...
            'fontsize',30,...
            'horizontalalignment', 'center',...
            'verticalalignment', 'middle',...
            'color', 'k');
    end


end

idx_sig = 0;
for i = 1:size(result_summary.pval_diff,1)

    pval_diff = result_summary.pval_diff(i,3);
    if pval_diff<0.05
        idx_sig = idx_sig + 1;
        if pval_diff<0.001
            % text_pval = 'P<.001';
            text_pval = 'P<0.001';
        elseif pval_diff<0.01
            text_pval = sprintf('P=%.3f',pval_diff);
            % text_pval(3) = [];
        else
            text_pval = sprintf('P=%.2f',pval_diff);
            % text_pval(3) = [];
        end
        xpos = result_summary.pval_diff(i,[1,2]);
        % ypos = max(max(result_summary.beta+result_summary.se),0)*[1,1] + yscale*0.05;
        ypos = [1,1]*yscale*0.1;
        plot(xpos,ypos,...
            'linestyle', '-',...
            'linewidth', 4,...
            'color', 'k');
        text(mean(xpos), mean(ypos), text_pval,...
            'fontsize',30,...
            'horizontalalignment', 'center',...
            'verticalalignment', 'bottom',...
            'color', 'k');

    end
end

hold off
set(gca,'fontsize',35,'linewidth',2);
% xlabel('Regressor');
xlabel(sprintf('\n'));
ylabel('Regression coefficient');

xlim([0.5,4.5]);
ylim(yrange);
set(gca,'YTick',[-0.4:0.2:0.2]);
% set(gca,'YTick',[-0.3:0.1:0.1]);

set(gca,'XTick',[1,2,3,4],'XTickLabel',{});
text_xticklabel = {'Mean', 'Change', 'Mean', 'Change'};

for i = 1:4
    xpos = i;
    ypos = min(yrange) - (max(yrange)-min(yrange))*0.02;
    text(xpos, ypos, text_xticklabel{i},...
        'fontsize', 35,...
        'color', list_color{i},...
        'HorizontalAlignment', 'Center',...
        'VerticalAlignment', 'top');

end

xpos = 1.5;
ypos = min(yrange) - (max(yrange)-min(yrange))*0.12;
text(xpos, ypos, 'Baseline mood',...
    'fontsize', 35,...
    'color', list_color{1},...
    'HorizontalAlignment', 'Center',...
    'VerticalAlignment', 'top');

xpos = 3.5;
ypos = min(yrange) - (max(yrange)-min(yrange))*0.12;
text(xpos, ypos, 'Reward sensitivity',...
    'fontsize', 35,...
    'color', list_color{3},...
    'HorizontalAlignment', 'Center',...
    'VerticalAlignment', 'top');



% output figure
% fig_file = fullfile(dirFig, 'monthly_reg_pc1_fullmodel');
fig_file = fullfile(dirFig, 'monthly_reg_pc2_fullmodel');
print(fig_file, '-dpdf');



%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% correlation %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
% x = tbl.mood_mean + tbl.mood_change;
% x = reshape(x,[],nMonth);
% x = nanmean(x(:,1:4),2);
% y = tbl.pc1_t(tbl.monthno==5);
% [rho,pval] = corr(x,y,'type','spearman','row','pairwise')
% 
% x = tbl.mood_mean + tbl.mood_change;
% x = reshape(x,[],nMonth);
% x = x(:,5) - nanmean(x(:,1:4),2);
% y = tbl.pc1_t(tbl.monthno==5);
% [rho,pval] = corr(x,y,'type','spearman','row','pairwise')
% 
% x = tbl.rewSen_mean;
% x = nanmean(reshape(x,[],nMonth),2);
% y = tbl.pc2_t(tbl.monthno==5);
% [rho,pval] = corr(x,y,'type','spearman','row','pairwise')
% 
% x = tbl.rewSen_change(tbl.monthno==5);
% y = tbl.pc2_t(tbl.monthno==5);
% [rho,pval] = corr(x,y,'type','spearman','row','pairwise')
% 
% 
% 
% x_mean = tbl.mood_mean(tbl.monthno==1);
% x_change = reshape(tbl.mood_change,[],nMonth);
% % xData = [x_mean, x_change];
% 
% xData = tbl.mood_mean + tbl.mood_change;
% xData = reshape(xData,[],nMonth);
% yData = tbl.pc1_t(tbl.monthno==5);
% [reg_beta, dev, stats] = glmfit(xData,yData);
% [stats.beta, stats.p]
% 
% x_mean = tbl.rewSen_mean(tbl.monthno==1);
% x_change = reshape(tbl.rewSen_change,[],nMonth);
% xData = [x_mean, x_change];
% yData = tbl.pc2_t(tbl.monthno==5);
% [reg_beta, dev, stats] = glmfit(xData,yData);
% [stats.beta, stats.p]



% x = tbl.mood_change;
% x = reshape(x,[],nMonth);
% y = tbl.pc1_change;
% y = reshape(y,[],nMonth);
% x = nanstd(x,0,2);
% y = nanstd(y,0,2);
% 
% [rho,pval] = corr(x,y,'type','spearman','row','pairwise')
% 
% x = tbl.rewSen_change;
% x = reshape(x,[],nMonth);
% y = tbl.pc2_change;
% y = reshape(y,[],nMonth);
% x = nanstd(x,0,2);
% y = nanstd(y,0,2);
% 
% [rho,pval] = corr(x,y,'type','spearman','row','pairwise')


%%%%% mood_mean X pc1_mean %%%%%
% x = tbl.mood_mean;
% 
% % y = tbl.pc1_mean;
% y = tbl.pc1_t_residual;
% 
% x = nanmean(reshape(x,[],nMonth),2);
% y = nanmean(reshape(y,[],nMonth),2);
% [rho,pval] = corr(x,y,'type','spearman','row','pairwise')
% 
% 
% 
% figure;
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*1;
% fg.pp(4) = fg.pp(4)*1.4;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% hold on
% 
% plot(x(:),y(:),...
%     'linestyle','none',...
%     'marker', 'o',...
%     'markersize', 12,...
%     'markerfacecolor', [0.5020, 0, 0.4549],...
%     'markeredgecolor', 'w',...
%     'linewidth', 1);
% 
% reg_beta = glmfit(x(:),y(:));
% xval = [min(x(:));max(x(:))];
% yval = glmval(reg_beta,xval,'identity');
% plot(xval,yval,...
%     'linestyle','-',...
%     'linewidth', 6,...
%     'color', 'k');
% 
% hold off
% set(gca,'fontsize',35,'linewidth',2);
% xlabel(sprintf('Baseline mood'));
% ylabel('General depression dimension');
% title('Trait')
% xlim([0,100]);
% ylim([-12,12]);
% 
% set(gca,...
%     'xtick',[0:25:100],...
%     'ytick', [-12:6:12]);
% 
% fig_file = fullfile(dirFig, 'monthly_corr_moodMean_pc1Mean');
% print(fig_file, '-dpdf');
% 
% %%%%% rewSen_mean X pc2_mean %%%%%
% x = tbl.rewSen_mean;
% 
% % y = tbl.pc2_mean;
% y = tbl.pc2_t_residual;
% 
% x = nanmean(reshape(x,[],nMonth),2);
% y = nanmean(reshape(y,[],nMonth),2);
% [rho,pval] = corr(x,y,'type','spearman')
% 
% figure;
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*1;
% fg.pp(4) = fg.pp(4)*1.4;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% hold on
% 
% plot(x(:),y(:),...
%     'linestyle','none',...
%     'marker', 'o',...
%     'markersize', 12,...
%     'markerfacecolor', [0.1608, 0.5490, 0.5490],...
%     'markeredgecolor', 'w',...
%     'linewidth', 1);
% 
% reg_beta = glmfit(x(:),y(:));
% xval = [min(x(:));max(x(:))];
% yval = glmval(reg_beta,xval,'identity');
% plot(xval,yval,...
%     'linestyle','-',...
%     'linewidth', 6,...
%     'color', 'k');
% 
% 
% hold off
% set(gca,'fontsize',35,'linewidth',2);
% xlabel('Reward sensitivity');
% ylabel('Anhedonia dimension');
% title('Trait')
% xlim([-60,0]);
% ylim([-6,6]);
% 
% set(gca,...
%     'xtick',[-60:20:0],...
%     'ytick', [-6:3:6]);
% 
% fig_file = fullfile(dirFig, 'monthly_corr_rewSenMean_pc2Mean');
% print(fig_file, '-dpdf');







%%%%% mood_mean X pc1_mean (quantile) %%%%%
nBin = 20;

x = tbl.mood_mean;

% y = tbl.pc1_mean;
y = tbl.pc1_t_residual;

x = nanmean(reshape(x,[],nMonth),2);
y = nanmean(reshape(y,[],nMonth),2);
[rho,pval] = corr(x,y,'type','spearman','row','pairwise');


bin_x_mean = NaN(nBin,1);
bin_x_sem = NaN(nBin,1);
bin_y_mean = NaN(nBin,1);
bin_y_sem = NaN(nBin,1);
list_bin = prctile(x, linspace(0,100,nBin+1));
for i = 1:nBin

    if i~=nBin
    idx_select = (x>=list_bin(i)) & (x<list_bin(i+1));
    else
        idx_select = (x>=list_bin(i)) & (x<=list_bin(i+1));
    end

    x_select = x(idx_select);
    y_select = y(idx_select);
    
    bin_x_mean(i) = nanmean(x_select);
    bin_x_sem(i) = nanstd(x_select)./sqrt(numel(x_select));

    bin_y_mean(i) = nanmean(y_select);
    bin_y_sem(i) = nanstd(y_select)./sqrt(numel(y_select));

end

figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*0.9;
fg.pp(4) = fg.pp(4)*1.4;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on

reg_beta = glmfit(bin_x_mean,bin_y_mean);
xval = [min(bin_x_mean);max(bin_x_mean)];
yval = glmval(reg_beta,xval,'identity');
plot(xval,yval,...
    'linestyle','-',...
    'linewidth', 10,...
    'color', 'k');

plot(bin_x_mean, bin_y_mean,...
    'linestyle','none',...
    'marker', 'o',...
    'markersize', 20,...
    'markerfacecolor', [0.5020, 0, 0.4549],...
    'markeredgecolor', 'w',...
    'linewidth', 2);
e = errorbar(bin_x_mean, bin_y_mean, bin_x_sem);
set(e,...
    'linestyle', 'none',...
    'color', 'k',...
    'linewidth', 2,...
    'CapSize',0);

hold off

set(gca,'fontsize',35,'linewidth',2);
xlabel('Baseline mood');
ylabel('General depression dimension');
% title('Trait')
xlim([0,100]);
ylim([-7,7]);

set(gca,...
    'xtick',[0:25:100],...
    'ytick', [-6:3:6]);

xrange = xlim;
yrange = ylim;
if pval<0.001
    text_rho = sprintf('%.2f', rho);
    % text_rho(2) = [];
    % text_rho_pval = sprintf('$\\rho=%s$\n$P<.001$', text_rho);
    text_rho_pval = sprintf('$\\rho=%s$\n$P<0.001$', text_rho);
else
    text_rho = sprintf('%.2f', rho);
    % text_rho(2) = [];
    text_pval = sprintf('%.3f', pval);
    % text_pval(1) = [];
    text_rho_pval = sprintf('$\\rho=%sf$\n$P=%s$', text_rho, text_pval);
end
text(min(xrange)+range(xrange)*0.03, min(yrange)+range(yrange)*0.03, text_rho_pval,...
    'fontsize', 30,...
    'HorizontalAlignment', 'left',...
    'VerticalAlignment', 'bottom',...
    'interpreter', 'latex');


fig_file = fullfile(dirFig, 'monthly_corr_moodMean_pc1Mean_quantile');
print(fig_file, '-dpdf');




%%%%% rewSen_mean X pc2_mean (quantile) %%%%%
nBin = 20;

x = tbl.rewSen_mean;

% y = tbl.anhedonia_minus_anxiety;
% y = tbl.pc2_mean;
y = tbl.pc2_t_residual;



x = nanmean(reshape(x,[],nMonth),2);
y = nanmean(reshape(y,[],nMonth),2);
[rho,pval] = corr(x,y,'type','spearman')

bin_x_mean = NaN(nBin,1);
bin_x_sem = NaN(nBin,1);
bin_y_mean = NaN(nBin,1);
bin_y_sem = NaN(nBin,1);
list_bin = prctile(x, linspace(0,100,nBin+1));
for i = 1:nBin

    if i~=nBin
    idx_select = (x>=list_bin(i)) & (x<list_bin(i+1));
    else
        idx_select = (x>=list_bin(i)) & (x<=list_bin(i+1));
    end

    x_select = x(idx_select);
    y_select = y(idx_select);
    
    bin_x_mean(i) = nanmean(x_select);
    bin_x_sem(i) = nanstd(x_select)./sqrt(numel(x_select));

    bin_y_mean(i) = nanmean(y_select);
    bin_y_sem(i) = nanstd(y_select)./sqrt(numel(y_select));

end

figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*0.9;
fg.pp(4) = fg.pp(4)*1.4;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on

reg_beta = glmfit(bin_x_mean,bin_y_mean);
xval = [min(bin_x_mean);max(bin_x_mean)];
yval = glmval(reg_beta,xval,'identity');
plot(xval,yval,...
    'linestyle','-',...
    'linewidth', 10,...
    'color', 'k');

plot(bin_x_mean, bin_y_mean,...
    'linestyle','none',...
    'marker', 'o',...
    'markersize', 20,...
    'markerfacecolor', [0.1608, 0.5490, 0.5490],...
    'markeredgecolor', 'w',...
    'linewidth', 2);
e = errorbar(bin_x_mean, bin_y_mean, bin_x_sem);
set(e,...
    'linestyle', 'none',...
    'color', 'k',...
    'linewidth', 2,...
    'CapSize',0);

hold off
set(gca,'fontsize',35,'linewidth',2);
xlabel('Reward sensitivity');
ylabel('Anhedonia dimension');
% title('Trait')
xlim([-60,0]);
ylim([-2.5,2.5]);

set(gca,...
    'xtick',[-60:20:0],...
    'ytick', [-2:1:2]);

xrange = xlim;
yrange = ylim;
if pval<0.001
    text_rho = sprintf('%.2f', rho);
    % text_rho(2) = [];
    % text_rho_pval = sprintf('$\\rho=%s$\n$P<.001$', text_rho);
    text_rho_pval = sprintf('$\\rho=%s$\n$P<0.001$', text_rho);
else
    text_rho = sprintf('%.2f', rho);
    % text_rho(2) = [];
    text_pval = sprintf('%.3f', pval);
    % text_pval(1) = [];
    text_rho_pval = sprintf('$\\rho=%s$\n$P=%s$', text_rho, text_pval);
end
text(min(xrange)+range(xrange)*0.03, min(yrange)+range(yrange)*0.03, text_rho_pval,...
    'fontsize', 30,...
    'HorizontalAlignment', 'left',...
    'VerticalAlignment', 'bottom',...
    'interpreter', 'latex');

fig_file = fullfile(dirFig, 'monthly_corr_rewSenMean_pc2Mean_quantile');
print(fig_file, '-dpdf');



%%%%% mood_change X pc1_change (bar) %%%%%
x = tbl.mood_change;

% y = tbl.pc1_t - tbl.pc1_mean;
y = tbl.pc1_t_residual;

x = reshape(x,[],nMonth);
y = reshape(y,[],nMonth);
% y = y - repmat(nanmean(y,2), 1, nMonth);

nSub = size(x,1);
category_y = NaN(nSub, 2);
for s = 1:nSub

    current_x = x(s,:);
    current_y = y(s,:);

    % decrease
    idx_select = (current_x<0);
    category_y(s,1) = nanmean(current_y(idx_select));

    % increase
    idx_select = (current_x>=0);
    category_y(s,2) = nanmean(current_y(idx_select));

end


% figure
figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*0.9;
fg.pp(4) = fg.pp(4)*1.4;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on
% yline(0,...
%     'linestyle', '--',...
%     'linewidth', 2,...
%     'color', [0.5,0.5,0.5]);

xData = [1,2];
yData = nanmean(category_y,1);
yData_sem = nanstd(category_y, 0, 1)./sqrt(nSub);
h = bar(xData, yData,...
        'linewidth', 2,...
        'barwidth', 0.35,...
        'facecolor', [0.5020, 0, 0.4549],...
        'edgecolor', 'k');
errorbar(xData, yData, yData_sem,...
        'linestyle', 'none',...
        'linewidth', 2,...
        'color', 'k',...
        'CapSize',16);

% difference
pval_diff = signrank(category_y(:,1),category_y(:,2));
if pval_diff<0.05
    if pval_diff<0.001
        % text_pval = 'P<.001';
        text_pval = 'P<0.001';
    elseif pval_diff<0.01
        text_pval = sprintf('P=%.3f',pval_diff);
        % text_pval(3) = [];
    else
        text_pval = sprintf('P=%.2f',pval_diff);
        % text_pval(3) = [];
    end
    xpos = [1,2];
    ypos = max(max(yData+yData_sem),0)*[1,1] + 0.2;
    plot(xpos,ypos,...
        'linestyle', '-',...
        'linewidth', 4,...
        'color', 'k');
    text(mean(xpos), mean(ypos), text_pval,...
        'fontsize',30,...
        'horizontalalignment', 'center',...
        'verticalalignment', 'bottom',...
        'color', 'k');

end

hold off

set(gca,'fontsize',35,'linewidth',2);
xlabel('Baseline mood');
ylabel('General depression dimension');
% title('State')

xlim([0.5,2.5]);
ylim([0,2]);
set(gca,'YTick',[0:0.5:2]);
set(gca,'XTick',[1,2],'XTickLabel',{'Decrease', 'Increase'});

% output figure
fig_file = fullfile(dirFig, 'monthly_moodChange_pc1Change_bar');
print(fig_file, '-dpdf');



%%%%% rewSen_change X pc2_change (bar) %%%%%
x = tbl.rewSen_change;

% y = tbl.anhedonia_minus_anxiety;
% y = tbl.pc2_t - tbl.pc2_mean;
y = tbl.pc2_t_residual;

x = reshape(x,[],nMonth);
y = reshape(y,[],nMonth);
% y = y - repmat(nanmean(y,2), 1, nMonth);

nSub = size(x,1);
category_y = NaN(nSub, 2);
for s = 1:nSub

    current_x = x(s,:);
    current_y = y(s,:);

    % decrease
    idx_select = (current_x<0);
    category_y(s,1) = nanmean(current_y(idx_select));

    % increase
    idx_select = (current_x>=0);
    category_y(s,2) = nanmean(current_y(idx_select));

end


% figure
figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*0.9;
fg.pp(4) = fg.pp(4)*1.4;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on
yline(0,...
    'linestyle', '--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);

xData = [1,2];
yData = nanmean(category_y,1);
yData_sem = nanstd(category_y, 0, 1)./sqrt(nSub);
h = bar(xData, yData,...
        'linewidth', 2,...
        'barwidth', 0.35,...
        'facecolor', [0.1608, 0.5490, 0.5490],...
        'edgecolor', 'k');
errorbar(xData, yData, yData_sem,...
        'linestyle', 'none',...
        'linewidth', 2,...
        'color', 'k',...
        'CapSize',16);

% difference
pval_diff = signrank(category_y(:,1),category_y(:,2))
if pval_diff<0.05
    if pval_diff<0.001
        text_pval = 'P<.001';
    else
        text_pval = sprintf('P=%.3f',pval_diff);
        text_pval(3) = [];
    end
    xpos = [1,2];
    ypos = max(max(yData+yData_sem),0)*[1,1] + 0.1;
    plot(xpos,ypos,...
        'linestyle', '-',...
        'linewidth', 4,...
        'color', 'k');
    text(mean(xpos), mean(ypos), text_pval,...
        'fontsize',30,...
        'horizontalalignment', 'center',...
        'verticalalignment', 'bottom',...
        'color', 'k');

end

hold off

set(gca,'fontsize',35,'linewidth',2);
xlabel('Reward sensitivity');
ylabel('Anhedonia dimension');
% title('State')

xlim([0.5,2.5]);
ylim([-0.4,0.4]);
set(gca,'YTick',[-0.4:0.2:0.4]);
set(gca,'XTick',[1,2],'XTickLabel',{'Decrease', 'Increase'});

fig_file = fullfile(dirFig, 'monthly_rewSenChange_pc2Change_bar');
print(fig_file, '-dpdf');






%%%%% mood_change X pc1_change %%%%%
% % x = tbl.mood_change;
% % y = tbl.pc1_t - tbl.pc1_mean;
% % x = reshape(x,[],nMonth);
% % y = reshape(y,[],nMonth);
% 
% x = tbl.mood_change;
% 
% % y = tbl.pc1_t - tbl.pc1_mean;
% y = tbl.pc1_t_residual;
% 
% x = reshape(x,[],nMonth);
% y = reshape(y,[],nMonth);
% y = y - repmat(nanmean(y,2), 1, nMonth);
% 
% color_data = [0.5020, 0, 0.4549];
% color_base = [0.8, 0.8, 0.8];
% color_mat = [linspace(color_base(1), color_data(1), 6)',...
%     linspace(color_base(2), color_data(2), 6)',...
%     linspace(color_base(3), color_data(3), 6)'];
% list_color = color_mat(2:6,:);
% 
% figure;
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*1;
% fg.pp(4) = fg.pp(4)*1.4;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% hold on
% reg_beta = glmfit(x(:),y(:));
% xval = [min(x(:));max(x(:))];
% yval = glmval(reg_beta,xval,'identity');
% plot(xval,yval,...
%     'linestyle','-',...
%     'linewidth', 6,...
%     'color', 'k');
% for idx_month = 1:nMonth
% 
%     [rho,pval] = corr(x(:,idx_month),y(:,idx_month),...
%         'type','spearman',...
%         'row','pairwise')
% 
%     plot(x(:,idx_month),y(:,idx_month),...
%         'linestyle','none',...
%         'marker', 'o',...
%         'markersize', 6,...
%         'markerfacecolor', list_color(idx_month,:),...
%         'markeredgecolor', 'w',...
%         'linewidth', 0.5);
% 
% end
% hold off
% set(gca,'fontsize',35,'linewidth',2);
% xlabel('Baseline mood');
% ylabel('General depression dimension');
% title('State')
% xlim([-50,50]);
% ylim([-12,12]);
% 
% set(gca,...
%     'xtick',[-50:25:50],...
%     'ytick', [-12:6:12]);
% 
% fig_file = fullfile(dirFig, 'monthly_corr_moodChange_pc1Change');
% print(fig_file, '-dpdf');
% 
% % color bar
% figure;
% axis off
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*0.5;
% fg.pp(4) = fg.pp(4)*0.4;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% ax1 = axes('Position', [0.1,0.1,0.8,0.8]);
% colormap(ax1, list_color);
% c1 = colorbar(ax1, 'fontsize',30, 'Ticks', []);
% c1.LineWidth = 0.1;
% c1.Color = [1,1,1];
% c1.Position(1) = 0.1;
% c1.Position(3) = c1.Position(3)*2
% % c1.Position(4) = c1.Position(4)*0.6;
% axis(ax1, 'off');
% 
% list_xpos = [0.1:0.2:0.9];
% for i = 1:5
%     text(0.35, list_xpos(i), sprintf('Month %d', i+1),...
%     'fontsize', 24,...
%     'HorizontalAlignment', 'center',...
%     'color', list_color(i,:));
% end
% 
% fig_file = fullfile(dirFig, 'monthly_corr_moodChange_pc1Change_colorbar');
% print(fig_file, '-dpdf');



%%%%% rewSen_change X pc2_change %%%%%
% x = tbl.rewSen_change;
% 
% % y = tbl.pc2_t - tbl.pc2_mean;
% y = tbl.pc2_t_residual;
% 
% x = reshape(x,[],nMonth);
% y = reshape(y,[],nMonth);
% y = y - repmat(nanmean(y,2), 1, nMonth);
% 
% color_data = [0.1608, 0.5490, 0.5490];
% color_base = [0.8, 0.8, 0.8];
% color_mat = [linspace(color_base(1), color_data(1), 6)',...
%     linspace(color_base(2), color_data(2), 6)',...
%     linspace(color_base(3), color_data(3), 6)'];
% list_color = color_mat(2:6,:);
% 
% figure;
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*1;
% fg.pp(4) = fg.pp(4)*1.4;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% hold on
% reg_beta = glmfit(x(:),y(:));
% xval = [min(x(:));max(x(:))];
% yval = glmval(reg_beta,xval,'identity');
% plot(xval,yval,...
%     'linestyle','-',...
%     'linewidth', 6,...
%     'color', 'k');
% for idx_month = 1:nMonth
% 
%     [rho,pval] = corr(x(:,idx_month),y(:,idx_month),...
%         'type','spearman',...
%         'row','pairwise')
% 
%     plot(x(:,idx_month),y(:,idx_month),...
%         'linestyle','none',...
%         'marker', 'o',...
%         'markersize', 6,...
%         'markerfacecolor', list_color(idx_month,:),...
%         'markeredgecolor', 'w',...
%         'linewidth', 0.5);
% 
% end
% hold off
% set(gca,'fontsize',35,'linewidth',2);
% xlabel('Reward sensitivity');
% ylabel('Anhedonia dimension');
% title('State')
% xlim([-60,60]);
% ylim([-10,10]);
% 
% set(gca,...
%     'xtick',[-60:30:60],...
%     'ytick', [-10:5:10]);
% 
% fig_file = fullfile(dirFig, 'monthly_corr_rewSenChange_pc2Change');
% print(fig_file, '-dpdf');
% 
% % color bar
% figure;
% axis off
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*0.5;
% fg.pp(4) = fg.pp(4)*0.4;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% ax1 = axes('Position', [0.1,0.1,0.8,0.8]);
% colormap(ax1, list_color);
% c1 = colorbar(ax1, 'fontsize',30, 'Ticks', []);
% c1.LineWidth = 0.1;
% c1.Color = [1,1,1];
% c1.Position(1) = 0.1;
% c1.Position(3) = c1.Position(3)*2
% % c1.Position(4) = c1.Position(4)*0.6;
% axis(ax1, 'off');
% 
% list_xpos = [0.1:0.2:0.9];
% for i = 1:5
%     text(0.35, list_xpos(i), sprintf('Month %d', i+1),...
%     'fontsize', 24,...
%     'HorizontalAlignment', 'center',...
%     'color', list_color(i,:));
% end
% 
% fig_file = fullfile(dirFig, 'monthly_corr_rewSenChange_pc2Change_colorbar');
% print(fig_file, '-dpdf');





%% supplementary fig: dense + monthly
%%%%% get pc score %%%%%
nSub = size(longitudinalData{3}.questionnaire.PHQ_total,1);


nSurvey_total = 0;
surveyData = [];

for v = [1,3]
% for v = [3]

    nSurvey_max = list_version{v,5};
    nSurvey_total = nSurvey_total + nSurvey_max;

    for i = 1:nSurvey_max

        temp_surveyData = [longitudinalData{v}.questionnaire.PHQ_item(:,:,i),...
            longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            longitudinalData{v}.questionnaire.GAD_item(:,:,i),...
            longitudinalData{v}.questionnaire.AMI_behavioral_item(:,:,i)];

        surveyData = [surveyData; temp_surveyData];

    end

end

% apply to questionnaire at different times
pca_coeff = combined_data_coeff;

surveyData_new = surveyData;
surveyData_new = surveyData_new - combined_data_mu;
pca_coeff_new = pca_coeff;
pca_score_new = surveyData_new*pca_coeff_new;

pc1 = reshape(pca_score_new(:,1), nSub, nSurvey_total);
pc2 = reshape(pca_score_new(:,2), nSub, nSurvey_total);

% average score from dense sampling
pc1 = [nanmean(pc1(:,1:2),2), pc1(:, 3:end)];
pc2 = [nanmean(pc2(:,1:2),2), pc2(:, 3:end)];

% parameter
param_mood = [];
param_rewSen = [];
for v = [1,3]
% for v = [3]

    % data
    list_block = list_version{v, 2};

    % mood
    switch v
        case {1}
            param_mood = nanmean(longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2);
        case {3}
            param_mood = [param_mood,...
                longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block)];
    end
    
    % rewSen
    switch v
        case {1}
            param_rewSen = nanmean(longitudinalData{v}.model_learning{2}.parameter(:,1+list_block),2);
        case {3}
            param_rewSen = [param_rewSen,...
                longitudinalData{v}.model_learning{2}.parameter(:,1+list_block)];
    end
    

end

scid_diagnosis = longitudinalData{1}.scid;
idx_scid = ~isnan(scid_diagnosis.current_mde) & ~isnan(scid_diagnosis.past_mde);
idx_mdd = (scid_diagnosis.current_mde==1) | (scid_diagnosis.past_mde==1);


% xData = nanmean(param_mood,2);
% yData = nanmean(pc1,2);

% xData = nanmean(param_mood(:,1),2);
% yData = nanmean(pc1(:,1),2);

% xData = nanmean(param_mood(:,2:end),2);
% yData = nanmean(pc1(:,2:end),2);

% xData = nanmean(param_rewSen,2);
% yData = nanmean(pc2,2);

% xData = nanmean(param_rewSen(:,1),2);
% yData = nanmean(pc2(:,1),2);

% xData = nanmean(param_rewSen(:,2:end),2);
% yData = nanmean(pc2(:,2:end),2);

% xData = param_mood(:,1);
% xData = param_rewSen(:,1);
% yData = pc1;
% yData = pc2;


[rho,pval] = corr(xData, yData,...
    'type', 'spearman',...
    'rows', 'pairwise')

[rho,pval] = corr(xData(idx_scid), yData(idx_scid),...
    'type', 'spearman',...
    'rows', 'pairwise')

[rho,pval] = corr(xData(idx_mdd), yData(idx_mdd),...
    'type', 'spearman',...
    'rows', 'pairwise')




%% supplementary fig: histogram of number of plays
switch dataset_name
    case {'nonmatch'}

        list_title_name = {
            sprintf('Depressed\nDense sampling');
            sprintf('Non-depressed\n');
            sprintf('Depressed\nMonthly follow-up');
            };

        for v = 1:nVersion

            subject_nPlay = sum(~isnan(allData{v}.behavior.choice_pGood_average),2);
            max_play = max(list_version{v,2});

            mean(subject_nPlay/max_play)

            summary_nPlay = tabulate(subject_nPlay);
            xData = summary_nPlay(:,1);
            yData = summary_nPlay(:,2);

            figure;
            fg = fig_setting_default();
            fg.pp(3) = fg.pp(3)*0.9;
            set(gcf,...
                'Position',fg.pp,...
                'PaperPosition', fg.pp,...
                'PaperSize', fg.pp([3:4]));
            set(gcf, 'PaperPositionMode', 'Auto');
            hold on

            bar(xData, yData, 0.9*(max_play/7),...
                'linewidth', 2,...
                'facecolor', [0.3,0.3,0.3],...
                'edgecolor', 'w')

            hold off
            set(gca, 'fontsize', 28, 'linewidth', 2);
            set(gca, 'XTick', [1:max_play]);
            xlim([0.5, max_play+0.5]);
            xlabel('Number of completed plays');
            ylabel('Number of participants');

            switch v
                case {1}
                    ylim([0,300]);
                    set(gca, 'YTick', [0:100:300]);
                case {2}
                    ylim([0,120]);
                    set(gca, 'YTick', [0:40:120]);
                case {3}
                    ylim([0,150]);
                    set(gca, 'YTick', [0:50:150]);
            end

            title(list_title_name{v});

            % output figure
            fig_file = fullfile(dirFig, sprintf('%s_%s_completedPlays', dataset_name, list_version{v,1}));
            print(fig_file, '-dpdf');

        end


    case {'match'}

        list_title_name = {
            sprintf('MDD\nDense sampling');
            sprintf('Control\n');
            };

        for v = 1:2

            subject_nPlay = sum(~isnan(allData{v}.behavior.choice_pGood_average),2);
            max_play = max(list_version{v,2});

            mean(subject_nPlay/max_play)

            summary_nPlay = tabulate(subject_nPlay);
            xData = summary_nPlay(:,1);
            yData = summary_nPlay(:,2);

            figure;
            fg = fig_setting_default();
            fg.pp(3) = fg.pp(3)*0.9;
            set(gcf,...
                'Position',fg.pp,...
                'PaperPosition', fg.pp,...
                'PaperSize', fg.pp([3:4]));
            set(gcf, 'PaperPositionMode', 'Auto');
            hold on

            bar(xData, yData, 0.9*(max_play/7),...
                'linewidth', 2,...
                'facecolor', [0.3,0.3,0.3],...
                'edgecolor', 'w')

            hold off
            set(gca, 'fontsize', 28, 'linewidth', 2);
            set(gca, 'XTick', [1:max_play]);
            xlim([0.5, max_play+0.5]);
            xlabel('Number of completed plays');
            ylabel('Number of participants');

            ylim([0,100]);
            set(gca, 'YTick', [0:50:100]);
            

            title(list_title_name{v});

            % output figure
            fig_file = fullfile(dirFig, sprintf('%s_%s_completedPlays', dataset_name, list_version{v,1}));
            print(fig_file, '-dpdf');

        end

end









%% supplementary fig: correlation between model-free and model parameter
list_color = {
    [1.0000    0.2    0.2]; % light red
    [0.4,0.4,0.4]; % dark gray
    };
list_marker = {
    '^';
    'o';
    };


list_type_behavior = {'pGood', 'avgHappy'};
list_type_param = {'rewSen', 'baselineMood'};
for idx_type = 1:2
    for v = 1:nVersion

        list_block = list_version{v,2};

        figure;
        fg = fig_setting_default();
        fg.pp(3) = fg.pp(3)*1.2;
        fg.pp(4) = fg.pp(4)*1.2;
        set(gcf,...
            'Position',fg.pp,...
            'PaperPosition', fg.pp,...
            'PaperSize', fg.pp([3:4]));
        set(gcf, 'PaperPositionMode', 'Auto');
        hold on


        switch idx_type
            case {1}
                xData = allData{v}.model_learning{1}.parameter(:,2);
                yData = nanmean(allData{v}.behavior.choice_pGood_average,2)*100;
            case {2}
                xData = [nanmean(allData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2)];
                yData = nanmean(allData{v}.behavior.happiness_mean,2);
        end

        [rho,pval] = corr(xData, yData, 'type', 'spearman')

        [reg_beta] = glmfit(xData, yData);
        xval = [min(xData), max(xData)];
        yval = glmval(reg_beta, xval, 'identity');
        plot(xval, yval,...
            'linestyle', '-',...
            'linewidth', 4,...
            'color', list_color{v});

        h = plot(xData, yData,...
            'linestyle', 'none',...
            'linewidth', 0.5,...
            'marker', list_marker{v},...
            'markersize', 10,...
            'MarkerEdgeColor', 'w',...
            'MarkerFaceColor', list_color{v});

        hold off
        set(gca,'fontsize', 32, 'linewidth', 2);

        switch idx_type
            case {1}
                xlabel('Reward sensitivity (D_{small})');
                xlim([-80, 0]);
                set(gca,'xtick',[-80:20:0]);

                ylabel('Learning performance (%)');
                ylim([40,100]);
                set(gca,'ytick',[40:20:100]);
            case {2}
                xlabel('Baseline mood (w_{0})');
                xlim([0,100]);
                set(gca,'xtick',[0:25:100]);

                ylabel('Momentary mood');
                ylim([0,100]);
                set(gca,'ytick',[0:25:100]);

        end

        switch v
            case {1}
                group_name = 'MDD';
            case {2}
                group_name = 'Control';
        end
        title(group_name);

        fig_file = sprintf('%s_corr_model_behavior_%s_%s_%s',...
            dataset_name, list_type_param{idx_type}, list_type_behavior{idx_type}, group_name);
        fig_file = fullfile(dirFig, fig_file);
        print(fig_file, '-dpdf');


    end
end





%% SM: learning trajectory: group, PC1, PC2
list_trial = [1:30];

split_type = 'group';
% split_type = 'PC1';
% split_type = 'PC2';

switch split_type
    case {'group'}
        list_color = {
            [1.0000    0.2    0.2]; % light red
            [0.4,0.4,0.4]; % dark gray
            };
        text_legend = {'MDD', 'Control'};
        text_title = 'Diagnosis group';
    case {'PC1'} 
        list_color = {
            [0.8320, 0.3672, 0]; % light red
            [0.4,0.4,0.4]; % dark gray
            };
        text_legend = {
            'High';
            'Low';
            };
        text_title = 'General depression dimension';
    case {'PC2'}
        list_color = {
            [0, 0.4453, 0.6953]; % light red
            [0.4,0.4,0.4]; % dark gray
            };
        text_legend = {
            'High';
            'Low';
            };
        text_title = 'Anhedonia dimension';
end


yData = [];
pca_data = [];
dummy_group = [];
for v = 1:2

    list_block = list_version{v,2};
    nBlock = numel(list_block);
    nSurvey_max = list_version{v,5};
    
    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    surveyData = [];
    for i = 1:nSurvey_max
        
        temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
            allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            allData{v}.questionnaire.GAD_item(:,:,i),...
            allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
        
        surveyData = [surveyData; temp_surveyData];
        
    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;
    
    nSub = size(pca_score_new,1)/nSurvey_max;
    pca_score = NaN(nSub,2);
    for i = 1:2
        temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
        pca_score(:,i) = nanmean(temp_data,2);
    end

    pca_data = [pca_data; pca_score];
    dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];

    behavior_data = nanmean(allData{v}.behavior.choice_pGood_smooth(:,list_trial,:),3);
    
    yData = [yData; behavior_data];
end
pc1 = pca_data(:,1);
pc2 = pca_data(:,2);

switch split_type
    case {'group'}
        q_val = dummy_group;
    case {'PC1'}
        q_val = pc1;
    case {'PC2'}
        q_val = pc2;
end





clear h_data nSub_group
figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*1.2;
fg.pp(4) = fg.pp(4)*1.1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on

subject_data = yData;
subject_data = subject_data*100;

for g = 1:2

    switch g
        case {1}
            idx_select = q_val>median(q_val);
        case {2}
            idx_select = q_val<=median(q_val);
    end
    current_data = subject_data(idx_select,:);

    nSub = size(current_data,1);
    nSub_group(g) = nSub;

    meanData = nanmean(current_data,1);
    semData = nanstd(current_data,0,1)./sqrt(nSub);

    %%%%% data %%%%%
    [hl, hp] = boundedline(...
        list_trial, meanData, semData,...
        'alpha');

    set(hl,...
        'Linesmoothing', 'on',...
        'Color', list_color{g},...
        'LineStyle', '-',...
        'LineWidth', 6);

    set(hp,...
        'Linesmoothing', 'on',...
        'FaceColor', list_color{g});

    h_data(g) = hl;


end
set(gca,'fontsize', 32, 'linewidth', 2);
ylabel('Learning performance (%)');
xlim([0,31]);

yrange = [40,100];
ylim(yrange);
xlabel('Trial number');
set(gca,'XTick',[0:10:30],...
    'YTick',[yrange(1):20:yrange(2)]);

% title(text_title);
h_legend = legend(h_data, text_legend,...
    'fontsize', 32,...
    'location', 'SouthEast');

% output figure
fig_file = fullfile(dirFig, sprintf('%s_behavior_trajectory_learning_%s', dataset_name, split_type));
print(fig_file, '-dpdf');








%% SM: happiness trajectory, example
list_group = {
    'MDD example participant';
    'Control example participant';
    };
subid_select = [89, 75];

list_color = {
    [1.0000    0.2    0.2]; % light red
    [0.4,0.4,0.4]; % dark gray
    };
list_marker = {
    '^';
    'o';
    };
clear h_data
figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*2;
fg.pp(4) = fg.pp(4)*1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on

for i = 1:6
    xData = [i*5+0.5, i*5+0.5];
    yData = [0,100];
    plot(xData, yData,...
        'linestyle', '--',...
        'linewidth', 2,...
        'color', 'k');
end

clear group_data h_data
for v = 1:nVersion

    subject_data = allData{v}.behavior.happiness(subid_select(v),:,:);
    subject_data = subject_data(:);

    model_data = allData{v}.model_happiness_raw{1}.trial_happiness_pred(subid_select(v),:,:);
    model_data = model_data(:);

    idx_notnan = ~isnan(subject_data);

    subject_data = subject_data(idx_notnan);
    model_data = model_data(idx_notnan);

    % subject_data = subject_data(1:30);
    % model_data = model_data(1:30);

    nRating = numel(subject_data);
    nBlock = nRating/5;
    blockno = ceil([1:nRating]/5);
    xData = [1:nRating];
    label_xtick = mod([1:nRating]-1,5)+1;
    yData = subject_data;
    yData_model = model_data;

    %%%%% data %%%%%
    for b = 1:nBlock

        idx_block = (blockno==b);
        current_xData = xData(idx_block);
        current_yData = yData(idx_block);
        current_yData_model = yData_model(idx_block);

        % model
        plot(current_xData, current_yData,...
            'LineStyle', '-',...
            'LineWidth', 4,...
            'color', list_color{v});

        % data
        h = plot(current_xData, current_yData_model,...
            'linestyle', 'none',...
            'linewidth', 2,...
            'marker', list_marker{v},...
            'markersize', 12,...
            'MarkerFaceColor', list_color{v},...
            'markeredgecolor', 'k');

        

    end

    h_data(v) = h;

end
set(gca,'fontsize', 28, 'linewidth', 2);
ylabel('Momentary mood');
xlim([0,36]);

yrange = [0,100];
ylim(yrange);
xlabel('Rating for each play');
set(gca, ...
    'XTick',[3,8,13,18,23,28,33],...
    'XTickLabel', {'Play 1', 'Play 2', 'Play 3', 'Play 4', 'Play 5', 'Play 6', 'Play 7'});

legend(h_data, list_group,...
    'fontsize', 28,...
    'location', 'SouthWest');
title('Example participants');

% output figure
fig_file = fullfile(dirFig, sprintf('%s_behavior_trajectory_happiness_example', dataset_name));
print(fig_file, '-dpdf');




%% supplementary fig: replication of between-participant analysis on monthly
xData = [];
yData = [];
pca_data = [];
demo = [];
dummy_group = [];

category_subgroup = [];

for v = 3

    list_block = list_version{v,2};
    nBlock = numel(list_block);
    nSurvey_max = list_version{v,5};
    
    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    surveyData = [];
    for i = 1:nSurvey_max
        
        temp_surveyData = [longitudinalData{v}.questionnaire.PHQ_item(:,:,i),...
            longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            longitudinalData{v}.questionnaire.GAD_item(:,:,i),...
            longitudinalData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
        
        surveyData = [surveyData; temp_surveyData];
        
    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;
    
    nSub = size(pca_score_new,1)/nSurvey_max;
    pca_score = NaN(nSub,2);
    for i = 1:2
        temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
        pca_score(:,i) = nanmean(temp_data,2);
    end

    pca_data = [pca_data; pca_score];

    current_mde = longitudinalData{v}.scid.current_mde;
    past_mde = longitudinalData{v}.scid.past_mde;

    demo = [demo;
        [longitudinalData{v}.demographics.age,...
        longitudinalData{v}.demographics.gender==1,...
        longitudinalData{v}.demographics.education]];

    % demo = [demo;
    %     [longitudinalData{v}.demographics.age,...
    %     longitudinalData{v}.demographics.gender==1,...
    %     longitudinalData{v}.demographics.education,...
    %     current_mde,...
    %     past_mde]];
    
    scid_mde = current_mde+past_mde;
    dummy_group = [dummy_group; scid_mde];

    % category_subgroup = [category_subgroup;
    %     [allData{v}.demographics.gender,...
    %     allData{v}.redcap_info.antidepressant,...
    %     allData{v}.redcap_info.smoke_history,...
    %     allData{v}.redcap_info.substance_history]];

    behavior_data = [nanmean(longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2)];
    % behavior_data = longitudinalData{v}.model_learning{1}.parameter(:,2);
    

%     behavior_data = longitudinalData{v}.model_happiness_raw{1}.parameter(:,1);
    % behavior_data = longitudinalData{v}.model_happiness_raw{1}.parameter(:,end-2); % w_p
    % behavior_data = longitudinalData{v}.model_happiness_raw{1}.parameter(:,end-1); % w_rpe
    % behavior_data = longitudinalData{v}.model_happiness_raw{1}.parameter(:,end);
    
    % behavior_data = longitudinalData{v}.model_learning{1}.parameter(:,1);

    % behavior_data = [nanmean(longitudinalData{v}.behavior.happiness_mean,2)];
    % behavior_data = [nanmean(longitudinalData{v}.behavior.choice_pGood_average,2)];

    % behavior_data = [nanmean(nanmean(longitudinalData{v}.behavior.choice_isGood(:,[21:30],:),2),3)];

    yData = [yData; behavior_data];
end
pc1 = pca_data(:,1);
pc2 = pca_data(:,2);


% dummy_group_residual
[reg_beta] = glmfit(pca_data, dummy_group);
yval = glmval(reg_beta, pca_data, 'identity');
dummy_group_residual = dummy_group - yval;

% pc1_residual
[reg_beta] = glmfit(dummy_group, pc1);
yval = glmval(reg_beta, dummy_group, 'identity');
pc1_residual = pc1 - yval;

% pc2_residual
[reg_beta] = glmfit(dummy_group, pc2);
yval = glmval(reg_beta, dummy_group, 'identity');
pc2_residual = pc2 - yval;

% standardization
xData = [pc1, pc2, pc1_residual, pc2_residual, dummy_group, demo];
nSub = size(xData,1);
xData = (xData - repmat(nanmean(xData,1),nSub,1)) ./ repmat(nanstd(xData,0,1),nSub,1);

% regression
tbl = array2table([yData, xData],...
    'VariableNames',...
    {'yData', 'pc1', 'pc2', 'pc1_residual', 'pc2_residual', 'dummy_group',...
    'age', 'gender', 'education'});

model_dummy = fitlm(tbl, 'yData ~ dummy_group + age + gender + education')
model_dummy_pcresidual = fitlm(tbl, 'yData ~ pc1_residual + pc2_residual + dummy_group + age + gender + education')

LR = 2*(model_dummy_pcresidual.LogLikelihood - model_dummy.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = model_dummy_pcresidual.NumEstimatedCoefficients - model_dummy.NumEstimatedCoefficients
pval = 1 - chi2cdf(LR, df)

reg_beta = model_dummy_pcresidual.Coefficients.Estimate(2:end);
reg_se = model_dummy_pcresidual.Coefficients.SE(2:end);
reg_pval = model_dummy_pcresidual.Coefficients.pValue(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]

% zval_diff = (reg_beta(1)-reg_beta(3))./sqrt(reg_se(1)^2+reg_se(3)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1);
% else
%     pval_diff = cdf('normal',zval_diff,0,1);
% end
pval_diff = 1;
comp_13_pval = [1,3,pval_diff]

% zval_diff = (reg_beta(2)-reg_beta(3))./sqrt(reg_se(2)^2+reg_se(3)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1);
% else
%     pval_diff = cdf('normal',zval_diff,0,1);
% end
pval_diff = 1;
comp_23_pval = [2,3,pval_diff]


clear result_summary
result_summary.beta = reg_beta(1:3);
result_summary.se = reg_se(1:3);
result_summary.p = reg_pval(1:3);
result_summary.pval_diff = [comp_12_pval;comp_13_pval;comp_23_pval];






%%%%% figure: bar %%%%%
yrange = [-8,4];

clear h_data
yscale = max(yrange)-min(yrange);

list_color = {
    [0.8320, 0.3672, 0]
    [0, 0.4453, 0.6953];
    [1,1,1];
    };

figure;
fg = fig_setting_default();
fg.pp(3) = fg.pp(3)*1;
fg.pp(4) = fg.pp(4)*1.2;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on
plot([0.5,3.5],[0,0],...
    'linestyle', '--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);
for i = 1:3

    xData = i;
    yData = result_summary.beta(i);
    yData_sem = result_summary.se(i);
    yData_pval = result_summary.p(i);

    h = bar(xData, yData,...
        'linewidth', 2,...
        'barwidth', 0.35,...
        'facecolor', list_color{i},...
        'edgecolor', 'k');

    errorbar(xData, yData, yData_sem,...
        'linestyle', 'none',...
        'linewidth', 2,...
        'color', 'k',...
        'CapSize',16);


    pval = yData_pval;
    if pval<0.05
        if pval<0.001
            % text_pval = 'P<.001';
            text_pval = 'P<0.001';
        else
            text_pval = sprintf('P=%.3f',pval);
            % text_pval(3) = [];
        end
        xpos = xData;
        ypos = yData - yData_sem - yscale*0.05;
        text(xpos, ypos, text_pval,...
            'fontsize',24,...
            'horizontalalignment', 'center',...
            'verticalalignment', 'middle',...
            'color', 'k');
    end


end

idx_sig = 0;
for i = 1:3

    pval_diff = result_summary.pval_diff(i,3);
    if pval_diff<0.05
        idx_sig = idx_sig + 1;
        if pval_diff<0.001
            % text_pval = 'P<.001';
            text_pval = 'P<0.001';
        else
            text_pval = sprintf('P=%.3f',pval_diff);
            % text_pval(3) = [];
        end
        xpos = result_summary.pval_diff(i,[1,2]);
        ypos = max(max(result_summary.beta+result_summary.se),0)*[1,1] + yscale*(0.1);
        plot(xpos,ypos,...
            'linestyle', '-',...
            'linewidth', 4,...
            'color', 'k');
        text(mean(xpos), mean(ypos), text_pval,...
            'fontsize',24,...
            'horizontalalignment', 'center',...
            'verticalalignment', 'bottom',...
            'color', 'k');

    end
end

hold off
set(gca,'fontsize',30,'linewidth',2);
% xlabel('Regressor');
xlabel(sprintf('\n\n'));
ylabel('Regression coefficient');

xlim([0.5,3.5]);
ylim(yrange);
set(gca,'YTick',[-8:4:4]);
set(gca,'XTick',[1,2,3],'XTickLabel',{});
text_xticklabel = {sprintf('General\ndepression\ndimension'), sprintf('Anhedonia\ndimension'), sprintf('MDD\ndiagnosis')};
    
list_xShift = [-0.15, 0, 0.15];
for i = 1:3
    xpos = i + list_xShift(i);
    ypos = min(yrange) - (max(yrange)-min(yrange))*0.02;
    text(xpos, ypos, text_xticklabel{i},...
        'fontsize', 30,...
        'HorizontalAlignment', 'Center',...
        'VerticalAlignment', 'top');
end

% output figure
fig_file = fullfile(dirFig, 'monthly_reg_mood_pca_acrossSubject');
% fig_file = fullfile(dirFig, 'monthly_reg_learning_pca_acrossSubject');
print(fig_file, '-dpdf');









%% supplementary fig: learning trajectory
% list_color = {
%     % [0.8    0.15    0.15]; % red
%     % [0.7216, 0.7216, 0.7216]; % light gray
% 
%     [1.0000    0.2    0.2]; % light red
%     [0.4,0.4,0.4]; % dark gray
%     };
% 
% clear h_data
% figure;
% fg = fig_setting_default();
% % fg.pp(3) = fg.pp(3)*0.7;
% % fg.pp(4) = fg.pp(4)*1.1;
% % set(gcf,...
% %     'Position',fg.pp,...
% %     'PaperPosition', fg.pp,...
% %     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% hold on
% 
% clear group_data h_data
% for v = 1:nVersion
% 
%     switch v
%         case {1}
%             list_trial = [1:30];
%         case {2}
%             list_trial = [1:30];
%     end
% 
%     subject_data = nanmean(allData{v}.behavior.choice_pGood_smooth(:,[list_trial],:),3);
% 
%     subject_data = subject_data*100;
% 
%     nSub = size(subject_data,1);
% 
%     meanData = nanmean(subject_data,1);
%     semData = nanstd(subject_data,0,1)./sqrt(nSub);
% 
%     %%%%% data %%%%%
%     [hl, hp] = boundedline(...
%         list_trial, meanData, semData,...
%         'alpha');
% 
%     set(hl,...
%         'Linesmoothing', 'on',...
%         'Color', list_color{v},...
%         'LineStyle', '-',...
%         'LineWidth', 4);
% 
%     set(hp,...
%         'Linesmoothing', 'on',...
%         'FaceColor', list_color{v});
% 
%     h_data(v) = hl;
% 
% 
% end
% set(gca,'fontsize', 28, 'linewidth', 2);
% ylabel('Learning performance (%)');
% xlim([0,31]);
% 
% yrange = [40,100];
% ylim(yrange);
% xlabel('Trial number');
% set(gca,'XTick',[0:10:30],...
%     'YTick',[yrange(1):20:yrange(2)]);
% 
% legend(h_data, {'MDD', 'Control'},...
%     'fontsize', 28,...
%     'location', 'SouthEast');
% 
% 
% % output figure
% fig_file = fullfile(dirFig, sprintf('%s_behavior_trajectory_learning', dataset_name));
% print(fig_file, '-dpdf');


%% supplementary fig: happiness trajectory
% list_color = {
%     [1.0000    0.2    0.2]; % light red
%     [0.4,0.4,0.4]; % dark gray
%     };
% 
% clear h_data
% figure;
% fg = fig_setting_default();
% % fg.pp(3) = fg.pp(3)*0.7;
% % fg.pp(4) = fg.pp(4)*1.1;
% % set(gcf,...
% %     'Position',fg.pp,...
% %     'PaperPosition', fg.pp,...
% %     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% hold on
% 
% clear group_data h_data
% for v = 1:nVersion
% 
%     switch v
%         case {1}
%             list_trial = [1:30];
%         case {2}
%             list_trial = [1:30];
%     end
%     % subject_data =nanmean(allData{v}.behavior.happiness(:,[list_trial],:),3);
%     subject_data =nanmean(allData{v}.behavior.happiness_backfilled(:,[list_trial],:),3);
%     % subject_data =nanmean(allData{v}.behavior.happiness_interp(:,[list_trial],:),3);
% 
%     subject_data = subject_data;
% 
%     nSub = size(subject_data,1);
% 
%     meanData = nanmean(subject_data,1);
%     semData = nanstd(subject_data,0,1)./sqrt(nSub);
% 
%     idx_notnan = ~isnan(meanData);
% 
%     %%%%% data %%%%%
%     [hl, hp] = boundedline(...
%         list_trial(idx_notnan), meanData(idx_notnan), semData(idx_notnan),...
%         'alpha');
% 
%     set(hl,...
%         'Linesmoothing', 'on',...
%         'Color', list_color{v},...
%         'LineStyle', '-',...
%         'LineWidth', 4);
% 
%     set(hp,...
%         'Linesmoothing', 'on',...
%         'FaceColor', list_color{v});
% 
%     h_data(v) = hl;
% 
% end
% set(gca,'fontsize', 28, 'linewidth', 2);
% ylabel('Momentary mood');
% xlim([0,31]);
% 
% yrange = [25,75];
% ylim(yrange);
% xlabel('Trial number');
% set(gca,'XTick',[0:10:30],...
%     'YTick',[yrange(1):25:yrange(2)]);
% 
% legend(h_data, {'MDD', 'Control'},...
%     'fontsize', 28,...
%     'location', 'SouthEast');
% 
% % output figure
% fig_file = fullfile(dirFig, sprintf('%s_behavior_trajectory_happiness', dataset_name));
% print(fig_file, '-dpdf');






%% supplementary fig: learning trajectory X PC
% 
% xData = [];
% yData = [];
% pca_data = [];
% dummy_group = [];
% for v = 1:nVersion
% 
%     list_block = list_version{v,2};
%     nBlock = numel(list_block);
%     nSurvey_max = list_version{v,5};
% 
%     % apply to questionnaire at different times
%     pca_coeff = combined_data_coeff;
%     surveyData = [];
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
%             allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             allData{v}.questionnaire.GAD_item(:,:,i),...
%             allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
%     surveyData_new = surveyData;
%     surveyData_new = surveyData_new - combined_data_mu;
%     pca_coeff_new = pca_coeff;
%     pca_score_new = surveyData_new*pca_coeff_new;
% 
%     nSub = size(pca_score_new,1)/nSurvey_max;
%     pca_score = NaN(nSub,2);
%     for i = 1:2
%         temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
%         pca_score(:,i) = nanmean(temp_data,2);
%     end
% 
%     pca_data = [pca_data; pca_score];
% 
%     dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];
% 
%     behavior_data = nanmean(allData{v}.behavior.choice_pGood_smooth(:,[list_trial],:),3);
% 
%     yData = [yData; behavior_data];
% end
% pc1 = pca_data(:,1);
% pc2 = pca_data(:,2);
% 
% 
% 
% % figure
% clear h_data
% figure;
% fg = fig_setting_default();
% % fg.pp(3) = fg.pp(3)*0.7;
% % fg.pp(4) = fg.pp(4)*1.1;
% % set(gcf,...
% %     'Position',fg.pp,...
% %     'PaperPosition', fg.pp,...
% %     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% hold on
% 
% clear group_data h_data
% for p = 1:2
% 
%     switch p
%         case {1}
%             % idx_select = pc2>median(pc2);
%             idx_select = pc2>0 & pc1<0;
%         case {2}
%             % idx_select = pc2<=median(pc2);
%             idx_select = pc2<=0 & pc1<0;
%     end
% 
%     data_select = yData(idx_select,:);
% 
%     nSub = size(data_select,1)
% 
%     meanData = nanmean(data_select,1);
%     semData = nanstd(data_select,0,1)./sqrt(nSub);
% 
%     %%%%% data %%%%%
%     [hl, hp] = boundedline(...
%         list_trial, meanData, semData,...
%         'alpha');
% 
%     set(hl,...
%         'Linesmoothing', 'on',...
%         'Color', list_color{p},...
%         'LineStyle', '-',...
%         'LineWidth', 4);
% 
%     set(hp,...
%         'Linesmoothing', 'on',...
%         'FaceColor', list_color{p});
% 
%     % h_data(v) = hl;
% 
% end


%% SM: logitudinal analysis
% %%%%% combine two studies %%%%%
% % for v = 1:2
% for v = 3
% 
%     nSub = size(allData{v}.questionnaire.PHQ_total,1);
%     list_block = list_version{v,2};
%     nBlock = numel(list_block);
% 
%     nSurvey_max = list_version{v,5};
% 
%     % apply to questionnaire at different times
%     pca_coeff = combined_data_coeff;
%     surveyData = [];
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
%             allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             allData{v}.questionnaire.GAD_item(:,:,i),...
%             allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
%     surveyData_new = surveyData;
%     surveyData_new = surveyData_new - combined_data_mu;
%     pca_coeff_new = pca_coeff;
%     pca_score_new = surveyData_new*pca_coeff_new;
% 
%     component_1 = reshape(pca_score_new(:,1),nSub, nSurvey_max);
%     component_2 = reshape(pca_score_new(:,2),nSub, nSurvey_max);
% 
%     dummy_all = ones(nSub, nSurvey_max)*v;
% 
%     subno_all = NaN(nSub, nSurvey_max);
%     blockno_all = NaN(nSub, nSurvey_max);
% 
%     age_all = NaN(nSub, nSurvey_max);
%     gender_all = NaN(nSub, nSurvey_max);
%     education_all = NaN(nSub, nSurvey_max);
% 
% 
% 
%     happiness_mean_all = NaN(nSub, nSurvey_max);
%     happiness_baseline_all = NaN(nSub, nSurvey_max);
% 
%     pGood_all = NaN(nSub,nSurvey_max);
%     pStay_all = NaN(nSub,nSurvey_max);
% 
%     rewSen_all = NaN(nSub,nSurvey_max);
% 
% 
% 
%     %%%%% detrend %%%%%
%     % x = repmat([list_block], nSub, 1);
%     % y = allData{v}.model_learning{2}.parameter(:,2:end);
%     % [reg_beta, dev, stats] = glmfit(x(:), y(:));
%     % y = stats.resid + reg_beta(1);
%     % % y = stats.resid;
%     % param_rewSen_detrend = reshape(y, nSub, nBlock);
% 
%     % param_rewSen_detrend = NaN(nSub, nBlock);
%     % for s = 1:nSub
%     % 
%     %     x = [list_block];
%     %     y = allData{v}.model_learning{2}.parameter(s,2:end);
%     %     [reg_beta, dev, stats] = glmfit(x(:), y(:));
%     %     y = stats.resid + reg_beta(1);
%     % 
%     %     param_rewSen_detrend(s,:) = y;
%     % 
%     % end
% 
%     param_rewSen_detrend = allData{v}.model_learning{2}.parameter(:,2:end);
% 
%     %%%%%%%%%%%%%%%%%%%
% 
%     for s = 1:nSub
% 
%         subno_all(s,:) = s + v*1000;
%         blockno_all(s,:) = 1:nSurvey_max;
% 
%         age_all(s,:) = allData{v}.demographics.age(s);
%         gender_all(s,:) = allData{v}.demographics.gender(s)==1;
%         education_all(s,:) = allData{v}.demographics.education(s);
% 
% 
%         pGood = allData{v}.behavior.choice_pGood_average(s,:);
%         pStay = allData{v}.behavior.choice_pStay_average(s,:);
%         happiness_mean = allData{v}.behavior.happiness_mean(s,:);
% 
%         rewSen = param_rewSen_detrend(s,:);
% 
%         % rewSen = allData{v}.model_learning{2}.parameter(s,2:end);
%         % rewSen = allData{v}.model_learning{3}.parameter(s,nBlock + list_block);
%         % rewSen = allData{v}.model_learning{3}.parameter(s,list_block);
% 
%         happiness_baseline = allData{v}.model_happiness_raw{1}.parameter(s,1+list_block);
% 
%         switch v
%             case {1}
% 
%                 happiness_baseline_all(s,1) = nanmean(happiness_baseline([1:2]));
%                 happiness_baseline_all(s,2) = nanmean(happiness_baseline([6:7]));
% 
%                 happiness_mean_all(s,1) = nanmean(happiness_mean([1:2]));
%                 happiness_mean_all(s,2) = nanmean(happiness_mean([6:7]));
% 
%                 pGood_all(s,1) = nanmean(pGood([1:2]));
%                 pGood_all(s,2) = nanmean(pGood([6:7]));
% 
%                 pStay_all(s,1) = nanmean(pStay([1:2]));
%                 pStay_all(s,2) = nanmean(pStay([6:7]));
% 
%                 rewSen_all(s,1) = nanmean(rewSen([1:2]));
%                 rewSen_all(s,2) = nanmean(rewSen([6:7]));
% 
%             case {2}
%                 happiness_baseline_all(s,1) = nanmean(happiness_baseline([1:2]));
%                 happiness_baseline_all(s,2) = nanmean(happiness_baseline([3:4]));
%                 happiness_baseline_all(s,3) = nanmean(happiness_baseline([5:6]));
% 
%                 happiness_mean_all(s,1) = nanmean(happiness_mean([1:2]));
%                 happiness_mean_all(s,2) = nanmean(happiness_mean([3:4]));
%                 happiness_mean_all(s,3) = nanmean(happiness_mean([5:6]));
% 
%                 pGood_all(s,1) = nanmean(pGood([1:2]));
%                 pGood_all(s,2) = nanmean(pGood([3:4]));
%                 pGood_all(s,3) = nanmean(pGood([5:6]));
% 
%                 pStay_all(s,1) = nanmean(pStay([1:2]));
%                 pStay_all(s,2) = nanmean(pStay([3:4]));
%                 pStay_all(s,3) = nanmean(pStay([5:6]));
% 
%                 rewSen_all(s,1) = nanmean(rewSen([1:2]));
%                 rewSen_all(s,2) = nanmean(rewSen([3:4]));
%                 rewSen_all(s,3) = nanmean(rewSen([5:6]));
% 
%             case {3}
% 
%                 for idx_time = 1:nSurvey_max
% 
%                     happiness_baseline_all(s,idx_time) = happiness_baseline(idx_time);
%                     rewSen_all(s,idx_time) = rewSen(idx_time);
%                 end
% 
%         end
% 
%     end
% 
%     % corrected by mean
%     % rewSen_mean = repmat(abs(nanmean(rewSen_all,2)),1,nSurvey_max);
%     % % rewSen_mean = repmat(abs(rewSen_all(:,1)),1,nSurvey_max);
%     % rewSen_all = rewSen_all./rewSen_mean;
% 
%     % remove linear treand
%     % x = repmat([1:nSurvey_max], nSub, 1);
%     % y = rewSen_all;
%     % [reg_beta, dev, stats] = glmfit(x(:),y(:));
%     % y = stats.resid + reg_beta(1);
% 
% 
% 
%     tbl = table(subno_all(:), blockno_all(:),...
%         age_all(:), gender_all(:), education_all(:),...
%         component_1(:), component_2(:),...
%         happiness_baseline_all(:),...
%         happiness_mean_all(:),...
%         pGood_all(:), pStay_all(:), rewSen_all(:),...
%         dummy_all(:),...
%         'VariableNames',...
%         {'subno', 'blockno',...
%         'age', 'gender', 'education',...
%         'component_1', 'component_2',...
%         'happiness_baseline',...
%         'happiness_mean',...
%         'pGood', 'pStay', 'rewSen',...
%         'dummy'});
% 
%     % if v==1
%     %     T_organizedData = tbl;
%     % else
%     %     T_organizedData = [T_organizedData; tbl];
%     % end
% 
% end
% T_organizedData = tbl;
% 
% 
% 
% %%%%% predictive future %%%%%
% % demo = [T_organizedData.age, T_organizedData.gender, T_organizedData.education];
% demo = [T_organizedData.age, T_organizedData.gender, T_organizedData.education, T_organizedData.dummy];
% demo = demo(T_organizedData.blockno==1,:);
% subno = T_organizedData.subno(T_organizedData.blockno==1,:);
% blockno = T_organizedData.blockno;
% pc1 = T_organizedData.component_1;
% pc2 = T_organizedData.component_2;
% y_baseline = T_organizedData.happiness_baseline;
% y_rewSen = T_organizedData.rewSen;
% 
% 
% idx_select = (T_organizedData.blockno==1);
% pc1_pre = pc1(idx_select);
% pc2_pre = pc2(idx_select);
% y_baseline_pre = y_baseline(idx_select);
% y_rewSen_pre = y_rewSen(idx_select);
% 
% idx_select = (T_organizedData.blockno==2);
% % idx_select = (T_organizedData.blockno==5);
% pc1_post = pc1(idx_select);
% pc2_post = pc2(idx_select);
% y_baseline_post = y_baseline(idx_select);
% y_rewSen_post = y_rewSen(idx_select);
% 
% 
% 
% tbl = array2table(...
%     [pc1_pre, pc1_post, pc1_post-pc1_pre,...
%     pc2_pre, pc2_post, pc2_post-pc2_pre,...
%     sign(pc1_pre), sign(pc2_pre),...
%     y_baseline_pre, y_baseline_post, y_baseline_post - y_baseline_pre,...
%     y_rewSen_pre, y_rewSen_post, y_rewSen_post - y_rewSen_pre,...
%     demo],...
%     'VariableNames',...
%     {'pc1_pre', 'pc1_post', 'pc1_change',...
%     'pc2_pre', 'pc2_post', 'pc2_change',...
%     'sign_pc1_pre', 'sign_pc2_pre',...
%     'mood_pre', 'mood_post', 'mood_change',...
%     'rewSen_pre', 'rewSen_post', 'rewSen_change',...
%     'age', 'gender', 'education','dummy'});
% 
% 
% model_rewSen = fitlm(tbl, 'pc1_post ~ pc1_pre + mood_pre + rewSen_pre + rewSen_post + age + gender + education + dummy')
% model_mood = fitlm(tbl, 'pc1_post ~ pc1_pre + mood_pre + mood_post + rewSen_pre + age + gender + education + dummy')
% model_full = fitlm(tbl, 'pc1_post ~ pc1_pre + mood_pre + mood_post + rewSen_pre + rewSen_post + age + gender + education + dummy')
% 
% % LR = 2*(model_full.LogLikelihood - model_rewSen.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
% % df = model_full.NumEstimatedCoefficients - model_rewSen.NumEstimatedCoefficients
% % pval = 1 - chi2cdf(LR, df)
% % 
% % LR = 2*(model_full.LogLikelihood - model_mood.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
% % df = model_full.NumEstimatedCoefficients - model_mood.NumEstimatedCoefficients
% % pval = 1 - chi2cdf(LR, df)
% 
% 
% 
% 
% 
% model_rewSen = fitlm(tbl, 'pc2_post ~ pc2_pre + mood_pre + rewSen_pre + rewSen_post + age + gender + education + dummy')
% model_mood = fitlm(tbl, 'pc2_post ~ pc2_pre + mood_pre + mood_post + rewSen_pre + age + gender + education + dummy')
% model_full = fitlm(tbl, 'pc2_post ~ pc2_pre + mood_pre + mood_post + rewSen_pre + rewSen_post + age + gender + education + dummy')
% % model_full = fitlm(tbl, 'pc2_post ~ pc2_pre + mood_pre + mood_post + rewSen_pre + sign_pc2_pre*rewSen_post + age + gender + education + dummy')
% model_full = fitlm(tbl, 'pc2_post ~ pc2_pre + pc1_pre + mood_pre + mood_post + rewSen_pre + sign_pc2_pre*rewSen_post + age + gender + education + dummy')
% 
% % LR = 2*(model_full.LogLikelihood - model_rewSen.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
% % df = model_full.NumEstimatedCoefficients - model_rewSen.NumEstimatedCoefficients
% % pval = 1 - chi2cdf(LR, df)
% % 
% % LR = 2*(model_full.LogLikelihood - model_mood.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
% % df = model_full.NumEstimatedCoefficients - model_mood.NumEstimatedCoefficients
% % pval = 1 - chi2cdf(LR, df)
% 
% 
% xData = tbl(:,{'pc2_pre', 'mood_pre', 'mood_post', 'rewSen_pre', 'rewSen_post', 'age', 'gender', 'education'});
% yData = tbl(:, 'pc2_post');
% xData = table2array(xData);
% yData = table2array(yData);
% [reg_beta, stats] = robustfit(xData, yData);
% [reg_beta, stats.p]
% 
% 
% 
% % xData = [pc2_pre, y_baseline_pre, y_baseline_post, y_rewSen_pre, y_rewSen_post];
% % yData = pc2_post;
% % [reg_beta, stats] = robustfit(xData, yData);
% % [reg_beta, stats.p]
% % 
% % idx_select = demo(:,end)==1;
% % [reg_beta, stats] = robustfit(xData(idx_select,:), yData(idx_select,:));
% % [reg_beta, stats.p]
% % 
% % idx_select = demo(:,end)==2;
% % [reg_beta, stats] = robustfit(xData(idx_select,:), yData(idx_select,:));
% % [reg_beta, stats.p]
% 
% 
% [rho,pval] = corr(pc1_pre, y_baseline_pre, 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc1_post, y_baseline_post, 'type', 'spearman', 'rows', 'pairwise')
% 
% [rho,pval] = corr(pc2_pre, y_rewSen_pre, 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc2_post, y_rewSen_post, 'type', 'spearman', 'rows', 'pairwise')
% 
% 
% 
% 
% 
% 
% 
% 
% 
% x = tbl.mood_change;
% y = tbl.pc1_change;
% 
% [reg_beta,dev,stats] = glmfit(tbl.mood_pre,tbl.mood_change);
% x = stats.resid;
% 
% [reg_beta,dev,stats] = glmfit(tbl.pc1_pre, tbl.pc1_change);
% y = stats.resid;
% 
% [rho,pval] =corr(x,y,'type','spearman','rows','pairwise')
% figure;
% fig_setting_default;
% plot(x,y,'ko');
% set(gca,'fontsize',24,'linewidth',2);
% xlabel('Mood change')
% ylabel('PC1 change');
% 
% 
% x = tbl.rewSen_change;
% y = tbl.pc2_change;
% 
% [reg_beta,dev,stats] = glmfit(tbl.rewSen_pre, tbl.rewSen_change);
% x = stats.resid;
% 
% [reg_beta,dev,stats] = glmfit(tbl.pc2_pre, tbl.pc2_change);
% y = stats.resid;
% 
% [rho,pval] =corr(x,y,'type','spearman','rows','pairwise')
% figure;
% fig_setting_default;
% plot(x,y,'ko');
% set(gca,'fontsize',24,'linewidth',2);
% xlabel('rewSen change')
% ylabel('PC2 change');






%% parameter over plays
% pc_type = 'pc1';
% % pc_type = 'pc2';
% 
% data_type = 'mood';
% % data_type = 'rewSen';
% % data_type = 'alpha';
% 
% for v = 1:nVersion
% 
%     %%%%% get pc score %%%%%
%     nSub = size(allData{v}.questionnaire.PHQ_total,1);
% 
%     list_block = list_version{v,2};
%     % switch v
%     %     case {1}
%     %         list_block = list_version{v,2};
%     %     case {2}
%     %         % list_block = list_version{v,2};
%     %         list_block = [1:4];
%     % end
%     nBlock = numel(list_block)
% 
%     nSurvey_max = list_version{v,5};
% 
%     % apply to questionnaire at different times
%     pca_coeff = combined_data_coeff;
%     surveyData = [];
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
%             allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             allData{v}.questionnaire.GAD_item(:,:,i),...
%             allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
%     surveyData_new = surveyData;
%     surveyData_new = surveyData_new - combined_data_mu;
%     pca_coeff_new = pca_coeff;
%     pca_score_new = surveyData_new*pca_coeff_new;
% 
%     pc1 = reshape(pca_score_new(:,1),nSub, nSurvey_max);
%     pc2 = reshape(pca_score_new(:,2),nSub, nSurvey_max);
% 
% 
% 
%     %%%%% organize data %%%%%
%     pc1_pre = pc1(:,1);
%     pc2_pre = pc2(:,1);
% 
%     pc1_post = pc1(:,end);
%     pc2_post = pc2(:,end);
%     % pc1_post = pc1(:,2);
%     % pc2_post = pc2(:,2);
% 
%     switch pc_type
%         case {'pc1'}
%             qval = pc1_pre;
%             yData = pc1_post-pc1_pre;
%         case {'pc2'}
%             qval = pc2_pre;
%             yData = pc2_post-pc2_pre;
%     end
% 
%     switch data_type
%         case {'mood'}
%             xData = allData{v}.model_happiness_raw{1}.parameter(:,1+list_block);
%         case {'rewSen'}
%             xData = allData{v}.model_learning{2}.parameter(:,1+list_block);
%             % xData = allData{v}.model_learning{3}.parameter(:,nBlock+list_block);
%         case {'alpha'}
%             xData = allData{v}.model_learning{3}.parameter(:,list_block);
%     end
% 
%     nPlay = size(xData,2);
%     % xData = xData - repmat(xData(:,1), 1, nPlay);
%     clear h_data
%     list_color = {
%         [0.6,0.6,1];
%         [0.2,0.2,1];
%         [1,0.6,0.6];
%         [1,0.2,0.2];
%         };
%     list_linestyle = {
%         '--';
%         '-';
%         '--';
%         '-';
%         };
%     list_marker = {
%         'o';
%         '^';
%         'o';
%         '^';
%         };
% 
%     idx_plot = 0;
%     figure;
%     fg = fig_setting_default();
%     fg.pp(4) = fg.pp(4)*1.2;
%     set(gcf,...
%         'Position',fg.pp,...
%         'PaperPosition', fg.pp,...
%         'PaperSize', fg.pp([3:4]));
%     set(gcf, 'PaperPositionMode', 'Auto');
%     hold on
%     for i = 1:2
%         for j = 1:2
% 
%             idx_plot = idx_plot + 1;
% 
%             if i==1
%                 idx_q = qval<=nanmedian(qval);
%             elseif i==2
%                 idx_q = qval>nanmedian(qval);
%             end
%             if j==1
%                 idx_change = (yData<0);
%             elseif j==2
%                 idx_change = (yData>0);
%             end
%             idx_select = idx_q & idx_change;
% 
%             data_select = xData(idx_select,:);
%             nSub_select = size(data_select,1)
% 
%             xval = [1:size(data_select,2)];
%             meanData = nanmean(data_select,1);
%             semData = nanstd(data_select,0,1)./sqrt(nSub_select);
% 
%             h = plot(xval, meanData,...
%                 'linestyle', list_linestyle{idx_plot},...
%                 'linewidth', 2,...
%                 'color', list_color{idx_plot},...
%                 'marker', list_marker{idx_plot},...
%                 'markersize', 12,...
%                 'markerfacecolor', list_color{idx_plot}, ...
%                 'markeredgecolor', 'k');
%             h_data(idx_plot) = h;
%             e = errorbar(xval, meanData, semData,...
%                 'linestyle', 'none',...
%                 'linewidth', 2,...
%                 'color', 'k');
% 
%         end
%     end
%     hold off
%     set(gca, 'fontsize', 24, 'linewidth', 2);
%     xlim([0.5,7.5]);
% 
%     switch data_type
%         case {'mood'}
%             ylim([40,70]);
%         case {'rewSen'}
%             ylim([-40,-10]);
%     end
% 
%     set(gca,'XTick',[1:7]);
% 
%     xlabel('Play number');
%     ylabel(data_type);
% 
%     text_legend = {
%         'starting low, getting better';
%         'starting low, getting worse';
%         'starting high, getting better';
%         'starting high, getting worse';
%         };
%     legend(h_data, text_legend,...
%         'location', 'SouthOutside',...
%         'fontsize', 20);
% 
% end



%% parameter over plays: split groups, initial <0/>0 X worse/better
% pc_type = 'pc1';
pc_type = 'pc2';

% data_type = 'pc1';
% data_type = 'pc2';
% data_type = 'mood';
data_type = 'rewSen';
% data_type = 'alpha';

% for v = 1:nVersion
for v = 3

    %%%%% get pc score %%%%%
    nSub = size(allData{v}.questionnaire.PHQ_total,1);

    list_block = list_version{v,2};
    nBlock = numel(list_block);

    nSurvey_max = list_version{v,5};

    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    
    surveyData = [];
    for i = 1:nSurvey_max

        temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
            allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            allData{v}.questionnaire.GAD_item(:,:,i),...
            allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];

        surveyData = [surveyData; temp_surveyData];

    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;

    pc1 = reshape(pca_score_new(:,1),nSub, nSurvey_max);
    pc2 = reshape(pca_score_new(:,2),nSub, nSurvey_max);



    %%%%% organize data %%%%%
    pc1_pre = pc1(:,1);
    pc2_pre = pc2(:,1);

    pc1_post = pc1(:,end);
    pc2_post = pc2(:,end);
    % pc1_post = pc1(:,2);
    % pc2_post = pc2(:,2);

    switch pc_type
        case {'pc1'}
            qval = pc1_pre;
            yData = pc1_post-pc1_pre;
        case {'pc2'}
            qval = pc2_pre;
            yData = pc2_post-pc2_pre;
    end

    switch data_type
        case {'mood'}
            xData = allData{v}.model_happiness_raw{1}.parameter(:,1+list_block);
        case {'rewSen'}
            xData = allData{v}.model_learning{2}.parameter(:,1+list_block);
            % xData = allData{v}.model_learning{3}.parameter(:,nBlock+list_block);
        case {'alpha'}
            xData = allData{v}.model_learning{3}.parameter(:,list_block);
        case {'pc1'}
            xData = pc1;
        case {'pc2'}
            xData = pc2;
    end

    nPlay = size(xData,2);
    % xData = xData - repmat(xData(:,1), 1, nPlay);
    clear h_data
    list_color = {
        [0.6,0.6,1];
        [0.2,0.2,1];
        [1,0.6,0.6];
        [1,0.2,0.2];
        };
    list_linestyle = {
        '--';
        '-';
        '--';
        '-';
        };
    list_marker = {
        'o';
        '^';
        'o';
        '^';
        };


    nSub_group = NaN(4,1);
    idx_plot = 0;
    figure;
    fg = fig_setting_default();
    fg.pp(4) = fg.pp(4)*1.2;
    set(gcf,...
        'Position',fg.pp,...
        'PaperPosition', fg.pp,...
        'PaperSize', fg.pp([3:4]));
    set(gcf, 'PaperPositionMode', 'Auto');
    hold on
    for i = 1:2
        for j = 1:2

            idx_plot = idx_plot + 1;

            if i==1
                % idx_q = qval<=nanmedian(qval);
                idx_q = qval<=0;
            elseif i==2
                % idx_q = qval>nanmedian(qval);
                idx_q = qval>0;
            end
            if j==1
                idx_change = (yData<0);
            elseif j==2
                idx_change = (yData>0);
            end
            idx_select = idx_q & idx_change;

            data_select = xData(idx_select,:);
            nSub_select = size(data_select,1);
            nSub_group(idx_plot) = nSub_select;

            xval = [1:size(data_select,2)];
            meanData = nanmean(data_select,1);
            semData = nanstd(data_select,0,1)./sqrt(nSub_select);

            h = plot(xval, meanData,...
                'linestyle', list_linestyle{idx_plot},...
                'linewidth', 2,...
                'color', list_color{idx_plot},...
                'marker', list_marker{idx_plot},...
                'markersize', 12,...
                'markerfacecolor', list_color{idx_plot}, ...
                'markeredgecolor', 'k');
            h_data(idx_plot) = h;
            e = errorbar(xval, meanData, semData,...
                'linestyle', 'none',...
                'linewidth', 2,...
                'color', 'k');

        end
    end
    hold off
    set(gca, 'fontsize', 24, 'linewidth', 2);
    xlim([0.5,5.5]);

    switch data_type
        case {'mood'}
            ylim([40,70]);
        case {'rewSen'}
            ylim([-40,-10]);
        case {'pc1'}
            ylim([-6, 6]);
        case {'pc2'}
            ylim([-6, 6]);
            
    end

    set(gca,'XTick',[1:5]);

    xlabel('Play number (month)');
    ylabel(data_type);

    text_legend = {
        sprintf('pc initial<0, getting better (change<0) (n=%d)', nSub_group(1));
        sprintf('pc initial<0, getting worse (change>0) (n=%d)', nSub_group(2));
        sprintf('pc initial>0, getting better (change<0) (n=%d)', nSub_group(3));
        sprintf('pc initial>0, getting worse (change>0) (n=%d)', nSub_group(4));
        };
    legend(h_data, text_legend,...
        'location', 'SouthOutside',...
        'fontsize', 20);

end


%% relationshiop between initial value and change
% list_data_type = {
%     'PC1';
%     'PC2';
%     'Mood';
%     'rewSen';
%     };
% nType = numel(list_data_type);
% 
% 
% 
% figure;
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*3;
% fg.pp(4) = fg.pp(4)*2;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% 
% idx_plot = 0;
% for v = 1:nVersion
% 
%     switch v
%         case {1}
%             text_version = 'depressed';
%         case {2}
%             text_version = 'non-depressed';
%     end
% 
%     %%%%% get pc score %%%%%
%     nSub = size(allData{v}.questionnaire.PHQ_total,1);
% 
%     list_block = list_version{v,2};
% 
%     nSurvey_max = list_version{v,5};
% 
%     % apply to questionnaire at different times
%     pca_coeff = combined_data_coeff;
%     surveyData = [];
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
%             allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             allData{v}.questionnaire.GAD_item(:,:,i),...
%             allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
%     surveyData_new = surveyData;
%     surveyData_new = surveyData_new - combined_data_mu;
%     pca_coeff_new = pca_coeff;
%     pca_score_new = surveyData_new*pca_coeff_new;
% 
%     pc1 = reshape(pca_score_new(:,1),nSub, nSurvey_max);
%     pc2 = reshape(pca_score_new(:,2),nSub, nSurvey_max);
% 
% 
%     %%%%% organize data %%%%%
%     pc1_pre = pc1(:,1);
%     pc2_pre = pc2(:,1);
% 
%     pc1_post = pc1(:,end);
%     pc2_post = pc2(:,end);
%     % pc1_post = pc1(:,2);
%     % pc2_post = pc2(:,2);
% 
% 
%     param_mood = allData{v}.model_happiness_raw{1}.parameter(:,1+list_block);
%     param_rewSen = allData{v}.model_learning{2}.parameter(:,1+list_block);
% 
% 
% 
%     param_mood_pre = nanmean(param_mood(:,1:2),2);
%     param_mood_post = nanmean(param_mood(:,end-1:end),2);
% 
%     param_rewSen_pre = nanmean(param_rewSen(:,1:2),2);
%     param_rewSen_post = nanmean(param_rewSen(:,end-1:end),2);
% 
% 
%     for idx_type = 1:nType
% 
%         idx_plot = idx_plot + 1;
% 
%         name_type = list_data_type{idx_type};
% 
%         switch name_type
%             case {'PC1'}
%                 x = pc1_pre;
%                 y = pc1_post - pc1_pre;
%             case {'PC2'}
%                 x = pc2_pre;
%                 y = pc2_post - pc2_pre;
%             case {'Mood'}
%                 x = param_mood_pre;
%                 y = param_mood_post - param_mood_pre;
%             case {'rewSen'}
%                 x = param_rewSen_pre;
%                 y = param_rewSen_post - param_rewSen_pre;
%         end
% 
%         % figure;
%         subplot(2,4,idx_plot);
%         fg = fig_setting_default;
%         hold on
% 
%         plot(x, y,...
%             'linestyle', 'none',...
%             'linewidth', 2,...
%             'marker', 'o',...
%             'markersize', 8,...
%             'markeredgecolor', 'k',...
%             'markerfacecolor', [0.5,0.5,0.5]);
% 
%         hold off
%         set(gca,'fontsize',24,'linewidth',2);
%         xlabel('Initial value');
%         ylabel('Change')
%         [rho,pval] = corr(x,y,'type','spearman','rows','pairwise');
%         text_title = sprintf('%s: %s\nrho=%.3f, p=%.3f', text_version, name_type, rho, pval);
%         title(text_title);
% 
% 
%         switch name_type
%             case {'PC1'}
%                 xlim([-12,12]);
%                 ylim([-12,12]);
%             case {'PC2'}
%                 xlim([-12,12]);
%                 ylim([-12,12]);
%             case {'Mood'}
%                 xlim([0,100]);
%                 ylim([-50,50]);
%             case {'rewSen'}
%                 xlim([-60,0]);
%                 ylim([-50,50]);
%         end
% 
%     end
% 
% 
% end


%% relationshiop between PC changes and parameter changes
% 
% pc1_all = [];
% pc2_all = [];
% param_mood_all = [];
% param_rewSen_all = [];
% 
% for v = 1:nVersion
% 
%     switch v
%         case {1}
%             text_version = 'depressed';
%         case {2}
%             text_version = 'non-depressed';
%     end
% 
%     %%%%% get pc score %%%%%
%     nSub = size(allData{v}.questionnaire.PHQ_total,1);
% 
%     list_block = list_version{v,2};
%     % list_block = [1:4];
%     nBlock = numel(list_block);
% 
%     nPlay = numel(list_block);
%     % switch v
%     %     case {1}
%     %         list_block = list_version{v,2};
%     %     case {2}
%     %         % list_block = list_version{v,2};
%     %         list_block = [1:4];
%     % end
% 
%     nSurvey_max = list_version{v,5};
% 
%     % apply to questionnaire at different times
%     pca_coeff = combined_data_coeff;
%     surveyData = [];
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
%             allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             allData{v}.questionnaire.GAD_item(:,:,i),...
%             allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
%     surveyData_new = surveyData;
%     surveyData_new = surveyData_new - combined_data_mu;
%     pca_coeff_new = pca_coeff;
%     pca_score_new = surveyData_new*pca_coeff_new;
% 
%     pc1 = reshape(pca_score_new(:,1),nSub, nSurvey_max);
%     pc2 = reshape(pca_score_new(:,2),nSub, nSurvey_max);
% 
% 
%     %%%%% organize data %%%%%
%     pc1_pre = pc1(:,1);
%     pc2_pre = pc2(:,1);
% 
%     % pc1_post = pc1(:,end);
%     % pc2_post = pc2(:,end);
%     pc1_post = pc1(:,2);
%     pc2_post = pc2(:,2);
% 
% 
%     param_mood = allData{v}.model_happiness_raw{1}.parameter(:,1+list_block);
% 
%     % param_rewSen = allData{v}.model_learning{2}.parameter(:,1+list_block);
%     param_rewSen = allData{v}.model_learning{3}.parameter(:,nBlock+list_block);
% 
%     blockno = repmat(list_block, nSub, 1);
% 
% 
%     xval = blockno(:);
%     yval = param_mood(:);
%     [reg_beta,dev,stats] = glmfit(xval, yval);
%     param_mood = stats.resid;
%     param_mood = reshape(param_mood, nSub, nPlay);
% 
%     xval = blockno(:);
%     yval = param_rewSen(:);
%     [reg_beta,dev,stats] = glmfit(xval, yval);
%     param_rewSen = stats.resid;
%     param_rewSen = reshape(param_rewSen, nSub, nPlay);
% 
% 
% 
% 
%     param_mood_pre = nanmean(param_mood(:,1:2),2);
%     param_mood_post = nanmean(param_mood(:,end-1:end),2);
% 
%     param_rewSen_pre = nanmean(param_rewSen(:,1:2),2);
%     param_rewSen_post = nanmean(param_rewSen(:,end-1:end),2);
% 
% 
% 
%     %%%%% change %%%%%
%     pc1_change = pc1_post - pc1_pre;
%     pc2_change = pc2_post - pc2_pre;
%     param_mood_change = param_mood_post - param_mood_pre;
%     param_rewSen_change = param_rewSen_post - param_rewSen_pre;
% 
%     %%%%% get correct initial %%%%%
%     [reg_beta,dev,stats] = glmfit(pc1_pre, pc1_change);
%     pc1_change = stats.resid;
% 
%     [reg_beta,dev,stats] = glmfit(pc2_pre, pc2_change);
%     pc2_change = stats.resid;
% 
%     [reg_beta,dev,stats] = glmfit(param_mood_pre, param_mood_change);
%     param_mood_change = stats.resid;
% 
%     [reg_beta,dev,stats] = glmfit(param_rewSen_pre, param_rewSen_change);
%     param_rewSen_change = stats.resid;
% 
% 
% 
%     % [rho,pval] = corr(pc1_change, param_mood_change,...
%     %     'type', 'spearman',...
%     %     'rows', 'pairwise')
%     % 
%     % [rho,pval] = corr(pc2_change, param_rewSen_change,...
%     %     'type', 'spearman',...
%     %     'rows', 'pairwise')
% 
% 
% 
%     % [rho,pval] = corr(pc1_pre, param_mood_pre,...
%     %     'type', 'spearman',...
%     %     'rows', 'pairwise')
%     % 
%     % [rho,pval] = corr(pc1_post, param_mood_post,...
%     %     'type', 'spearman',...
%     %     'rows', 'pairwise')
%     % 
%     % [rho,pval] = corr(pc2_pre, param_rewSen_pre,...
%     %     'type', 'spearman',...
%     %     'rows', 'pairwise')
%     % 
%     % [rho,pval] = corr(pc2_post, param_rewSen_post,...
%     %     'type', 'spearman',...
%     %     'rows', 'pairwise')
% 
% 
% 
%     % sign_pc1 = sign(pc1_change);
%     % sign_pc2 = sign(pc2_change);
%     % sign_param_mood = sign(param_mood_change);
%     % sign_param_rewSen = sign(param_rewSen_change);
%     % 
%     % x1 = param_mood_change(sign_pc1==-1);
%     % x2 = param_mood_change(sign_pc1==1);
%     % [nanmean(x1), nanmean(x2)]
%     % ranksum(x1,x2)
%     % 
%     % x1 = param_rewSen_change(sign_pc2==-1);
%     % x2 = param_rewSen_change(sign_pc2==1);
%     % [nanmean(x1), nanmean(x2)]
%     % ranksum(x1,x2)
% 
% 
% 
% 
%     pc1_all = [pc1_all; [pc1_pre,pc1_post,pc1_change]];
%     pc2_all = [pc2_all; [pc2_pre,pc2_post,pc2_change]];
%     param_mood_all = [param_mood_all; [param_mood_pre, param_mood_post, param_mood_change]];
%     param_rewSen_all = [param_rewSen_all; [param_rewSen_pre, param_rewSen_post, param_rewSen_change]];
% 
% 
% 
% end
% 
% 
% [rho,pval] = corr(pc1_all(:,1), param_mood_all(:,1), 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc1_all(:,2), param_mood_all(:,2), 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc1_all(:,3), param_mood_all(:,3), 'type', 'spearman', 'rows', 'pairwise')
% xval = [pc1_all(:,1), pc1_all(:,3), param_mood_all(:,1)];
% yval = param_mood_all(:,3);
% [reg_beta, dev, stats] = glmfit(xval, yval);
% [stats.beta, stats.p]
% 
% 
% [rho,pval] = corr(pc2_all(:,1), param_rewSen_all(:,1), 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc2_all(:,2), param_rewSen_all(:,2), 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc2_all(:,3), param_rewSen_all(:,3), 'type', 'spearman', 'rows', 'pairwise')
% xval = [pc2_all(:,1), pc2_all(:,3), param_rewSen_all(:,1)];
% yval = param_rewSen_all(:,3);
% [reg_beta, dev, stats] = glmfit(xval, yval);
% [stats.beta, stats.p]
% 
% 
% [rho,pval] = corr(pc1_all(:,1), param_mood_all(:,2), 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc1_all(:,2), param_mood_all(:,1), 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc2_all(:,1), param_rewSen_all(:,2), 'type', 'spearman', 'rows', 'pairwise')
% [rho,pval] = corr(pc2_all(:,2), param_rewSen_all(:,1), 'type', 'spearman', 'rows', 'pairwise')
% 
% 
% 
% xval = [pc1_all(:,1), pc1_all(:,3), param_mood_all(:,1)];
% yval = param_mood_all(:,3);
% 
% idx_select = pc1_all(:,1)<=0;
% [reg_beta, dev, stats] = glmfit(xval(idx_select,:), yval(idx_select,:));
% [stats.beta, stats.p]
% 
% idx_select = pc1_all(:,1)>0;
% [reg_beta, dev, stats] = glmfit(xval(idx_select,:), yval(idx_select,:));
% [stats.beta, stats.p]
% 
% 
% 
% xval = [pc2_all(:,1), pc2_all(:,3), param_rewSen_all(:,1)];
% yval = param_rewSen_all(:,3);
% 
% idx_select = pc2_all(:,1)<=0;
% [reg_beta, dev, stats] = glmfit(xval(idx_select,:), yval(idx_select,:));
% [stats.beta, stats.p]
% 
% idx_select = pc2_all(:,1)>0;
% [reg_beta, dev, stats] = glmfit(xval(idx_select,:), yval(idx_select,:));
% [stats.beta, stats.p]


%% longitudinal: dense sampling (w0, w2) & monthly (m2-m6)
% % parameter over plays: split groups, initial <0/>0 X worse/better
% 
% pc_type = 'pc1';
% % pc_type = 'pc2';
% 
% data_type = 'pc1';
% % data_type = 'pc2';
% % data_type = 'mood';
% % data_type = 'rewSen';
% % data_type = 'alpha';
% 
% %%%%% get pc score %%%%%
% nSub = size(longitudinalData{1}.questionnaire.PHQ_total,1);
% 
% nSurvey_total = 0;
% surveyData = [];
% for v = [1,3]
% 
%     nSurvey_max = list_version{v,5};
%     nSurvey_total = nSurvey_total + nSurvey_max;
% 
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [longitudinalData{v}.questionnaire.PHQ_item(:,:,i),...
%             longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             longitudinalData{v}.questionnaire.GAD_item(:,:,i),...
%             longitudinalData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
% 
% end
% 
% % apply to questionnaire at different times
% pca_coeff = combined_data_coeff;
% 
% surveyData_new = surveyData;
% surveyData_new = surveyData_new - combined_data_mu;
% pca_coeff_new = pca_coeff;
% pca_score_new = surveyData_new*pca_coeff_new;
% 
% pc1 = reshape(pca_score_new(:,1), nSub, nSurvey_total);
% pc2 = reshape(pca_score_new(:,2), nSub, nSurvey_total);
% 
% 
% % data
% param_mood = [];
% param_rewSen = [];
% for v = [1,3]
% 
%     list_block = list_version{v, 2};
% 
%     % mood
%     data_mood = longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block);
%     if v==1
%         param_mood = [param_mood,...
%             nanmean(data_mood(:,[1:2]),2),...
%             nanmean(data_mood(:,[end-1:end]),2)];
%     else
%         param_mood = [param_mood, data_mood];
%     end
% 
%     % rewSen
%     data_rewSen = longitudinalData{v}.model_learning{2}.parameter(:,1+list_block);
%     if v==1
%         param_rewSen = [param_rewSen,...
%             nanmean(data_rewSen(:,[1:2]),2),...
%             nanmean(data_rewSen(:,[end-1:end]),2)];
%     else
%         param_rewSen = [param_rewSen, data_rewSen];
%     end
% 
% end
% 
% 
% %%%%% organize data %%%%%
% pc1_pre = pc1(:,1);
% pc2_pre = pc2(:,1);
% 
% pc1_post = pc1(:,end);
% pc2_post = pc2(:,end);
% 
% switch pc_type
%     case {'pc1'}
%         qval = pc1_pre;
%         yData = pc1_post-pc1_pre;
%     case {'pc2'}
%         qval = pc2_pre;
%         yData = pc2_post-pc2_pre;
% end
% 
% switch data_type
%     case {'mood'}
%         xData = param_mood;
%     case {'rewSen'}
%         xData = param_rewSen;
%     case {'pc1'}
%         xData = pc1;
%     case {'pc2'}
%         xData = pc2;
% end
% 
% 
% 
% 
% nPlay = size(xData,2);
% % xData = xData - repmat(xData(:,1), 1, nPlay);
% clear h_data
% list_color = {
%     [0.6,0.6,1];
%     [0.2,0.2,1];
%     [1,0.6,0.6];
%     [1,0.2,0.2];
%     };
% list_linestyle = {
%     '--';
%     '-';
%     '--';
%     '-';
%     };
% list_marker = {
%     'o';
%     '^';
%     'o';
%     '^';
%     };
% 
% 
% nSub_group = NaN(4,1);
% idx_plot = 0;
% figure;
% fg = fig_setting_default();
% fg.pp(4) = fg.pp(4)*1.2;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% hold on
% for i = 1:2
%     for j = 1:2
% 
%         idx_plot = idx_plot + 1;
% 
%         if i==1
%             % idx_q = qval<=nanmedian(qval);
%             idx_q = qval<=0;
%         elseif i==2
%             % idx_q = qval>nanmedian(qval);
%             idx_q = qval>0;
%         end
%         if j==1
%             idx_change = (yData<0);
%         elseif j==2
%             idx_change = (yData>0);
%         end
%         idx_select = idx_q & idx_change;
% 
%         data_select = xData(idx_select,:);
%         nSub_select = size(data_select,1);
%         nSub_group(idx_plot) = nSub_select;
% 
%         xval = [1:size(data_select,2)];
%         meanData = nanmean(data_select,1);
%         semData = nanstd(data_select,0,1)./sqrt(nSub_select);
% 
%         h = plot(xval, meanData,...
%             'linestyle', list_linestyle{idx_plot},...
%             'linewidth', 2,...
%             'color', list_color{idx_plot},...
%             'marker', list_marker{idx_plot},...
%             'markersize', 12,...
%             'markerfacecolor', list_color{idx_plot}, ...
%             'markeredgecolor', 'k');
%         h_data(idx_plot) = h;
%         e = errorbar(xval, meanData, semData,...
%             'linestyle', 'none',...
%             'linewidth', 2,...
%             'color', 'k');
% 
%     end
% end
% hold off
% set(gca, 'fontsize', 24, 'linewidth', 2);
% xlim([0.5,7.5]);
% 
% switch data_type
%     case {'mood'}
%         ylim([40,80]);
%     case {'rewSen'}
%         ylim([-40,-10]);
%     case {'pc1'}
%         ylim([-7, 7]);
%     case {'pc2'}
%         ylim([-7, 7]);
% 
% end
% 
% list_xtick_label = {
%     'w0';
%     'w2';
%     'm2';
%     'm3';
%     'm4';
%     'm5';
%     'm6';
%     };
% set(gca,...
%     'XTick',[1:numel(list_xtick_label)],...
%     'XTickLabel', list_xtick_label);
% 
% xlabel('time');
% ylabel(data_type);
% 
% text_legend = {
%     sprintf('pc initial<0, getting better (change<0) (n=%d)', nSub_group(1));
%     sprintf('pc initial<0, getting worse (change>0) (n=%d)', nSub_group(2));
%     sprintf('pc initial>0, getting better (change<0) (n=%d)', nSub_group(3));
%     sprintf('pc initial>0, getting worse (change>0) (n=%d)', nSub_group(4));
%     };
% legend(h_data, text_legend,...
%     'location', 'SouthOutside',...
%     'fontsize', 20);
% 
% rho_pval_all = NaN(nPlay, 2);
% for i = 1:nPlay
% 
%     % x = pc1(:,i);
%     % y = param_mood(:,i);
% 
%     x = pc2(:,i);
%     y = param_rewSen(:,i);
% 
%     % sum(~isnan(x+y))
% 
%     [rho,pval] = corr(x,y,...
%         'type','spearman',...
%         'rows', 'pairwise');
%     rho_pval_all(i,:) = [rho,pval];
% 
% end
% rho_pval_all
% 
% 
% 
% % idx_play_select = [6,7];
% % [rho,pval] = corr(nanmean(pc2(:,idx_play_select),2),nanmean(param_rewSen(:,idx_play_select),2),...
% %         'type','spearman',...
% %         'rows', 'pairwise')




%% longitudinal: monthly (m2-m6)
%%%%% get pc score %%%%%
nSub = size(longitudinalData{1}.questionnaire.PHQ_total,1);

nSurvey_total = 0;
surveyData = [];
v = 3;

nSurvey_max = list_version{v,5};
nSurvey_total = nSurvey_total + nSurvey_max;

for i = 1:nSurvey_max

    temp_surveyData = [longitudinalData{v}.questionnaire.PHQ_item(:,:,i),...
        longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
        longitudinalData{v}.questionnaire.GAD_item(:,:,i),...
        longitudinalData{v}.questionnaire.AMI_behavioral_item(:,:,i)];

    surveyData = [surveyData; temp_surveyData];

end


% apply to questionnaire at different times
pca_coeff = combined_data_coeff;

surveyData_new = surveyData;
surveyData_new = surveyData_new - combined_data_mu;
pca_coeff_new = pca_coeff;
pca_score_new = surveyData_new*pca_coeff_new;

pc1 = reshape(pca_score_new(:,1), nSub, nSurvey_total);
pc2 = reshape(pca_score_new(:,2), nSub, nSurvey_total);


% data
list_block = list_version{v, 2};

% mood
param_mood = longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block);

% rewSen
param_rewSen = longitudinalData{v}.model_learning{2}.parameter(:,1+list_block);

% outcome
outcome = longitudinalData{v}.behavior.outcome;
score = (outcome==0)*10 + (outcome==1)*30;
task_score = sum(score,2);
idx_nan = isnan(sum(outcome,2));
task_score(idx_nan) = NaN;
task_score = reshape(task_score, size(param_rewSen));

% performance
task_performance = longitudinalData{v}.behavior.choice_pGood_average;

[rho,pval] = corr(task_score, task_performance,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(pc1, pc2,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(pc1, task_score,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(pc1, task_performance,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(pc2, task_score,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(pc2, task_performance,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(param_mood, task_score,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(param_mood, task_performance,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(param_rewSen, task_score,...
    'type', 'spearman',...
    'rows','pairwise')

[rho,pval] = corr(param_rewSen, task_performance,...
    'type', 'spearman',...
    'rows','pairwise')





%%%%% regression: predicting future with mean and change %%%%
nMonth = size(pc1,2);
list_month = [1:nMonth];
demo = [
    longitudinalData{1}.demographics.age,...
    double(longitudinalData{1}.demographics.gender==1),...
    longitudinalData{1}.demographics.education];

for m = 1:nMonth
% for m = nMonth
    
    % select months
    idx_month = m;
    % idx_mean = list_month(list_month~=m);
    idx_mean = list_month;

    % organize data
    pc1_mean = nanmean(pc1(:, idx_mean),2);
    pc2_mean = nanmean(pc2(:, idx_mean),2);
    mood_mean = nanmean(param_mood(:, idx_mean),2);
    rewSen_mean = nanmean(param_rewSen(:, idx_mean),2);

    task_score_mean = nanmean(task_score(:, idx_mean),2);

    xData = [
        pc1(:,idx_month),...
        pc2(:,idx_month),...
        pc1_mean, pc2_mean,...
        mood_mean, param_mood(:,idx_month)-mood_mean,...
        rewSen_mean, param_rewSen(:,idx_month)-rewSen_mean,...
        task_score_mean, task_score(:, idx_month)-task_score_mean];

    xData = [xData, demo];

    idx_valid = ~isnan(sum(xData,2));
    xData = xData(idx_valid,:);
    nSub_valid = sum(idx_valid);
    fprintf('month %d: n=%d\n', m+1, nSub_valid);

    % standarization
    xData = (xData - repmat(nanmean(xData,1),nSub_valid,1)) ./ repmat(nanstd(xData,0,1),nSub_valid,1);

    % convert to table
    tbl = array2table(xData,...
        'VariableNames',...
        {'pc1_t',...
        'pc2_t',...
        'pc1_mean', 'pc2_mean',...
        'mood_mean', 'mood_change',...
        'rewSen_mean', 'rewSen_change',...
        'task_score_mean', 'task_score_change',...
        'age', 'gender', 'education'});

    % model
    % model_baseline = fitlm(tbl(idx_select,:), 'pc1_m6 ~ pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
    % model_mood = fitlm(tbl(idx_select,:), 'pc1_m6 ~ mood_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
    % model_rewSen = fitlm(tbl(idx_select,:), 'pc1_m6 ~ rewSen_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')

    % pc1
    model_full = fitlm(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education');
    model_no_mood_change = fitlm(tbl, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education');
    model_no_mood_mean = fitlm(tbl, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education');
    model_no_rewSen_change = fitlm(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education');
    model_no_rewSen_mean = fitlm(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_change + age + gender + education');
    model_no_mood = fitlm(tbl, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education');
    model_no_rewSen = fitlm(tbl, 'pc1_t ~ mood_mean + mood_change + age + gender + education');
    

    % pc2
    % model_full = fitlm(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education');
    % model_no_mood_change = fitlm(tbl, 'pc2_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education');
    % model_no_mood_mean = fitlm(tbl, 'pc2_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education');
    % model_no_rewSen_change = fitlm(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education');
    % model_no_rewSen_mean = fitlm(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_change + age + gender + education');
    % model_no_mood = fitlm(tbl, 'pc2_t ~ rewSen_mean + rewSen_change + age + gender + education');
    % model_no_rewSen = fitlm(tbl, 'pc2_t ~ mood_mean + mood_change + age + gender + education');


    model_1 = model_full;

    % model_0 = model_no_mood_mean;
    % model_0 = model_no_mood_change;
    % model_0 = model_no_mood;
    model_0 = model_no_rewSen_mean;
    % model_0 = model_no_rewSen_change;
    % model_0 = model_no_rewSen;
    
    

    LR = 2*(model_1.LogLikelihood - model_0.LogLikelihood); % has a X2 distribution with a df equals to number of constrained parameters
    df = model_1.NumEstimatedCoefficients - model_0.NumEstimatedCoefficients;
    pval = 1 - chi2cdf(LR, df)


end






%%%%% combined: mean vs change %%%%
valid_play = sum(~isnan(pc1+pc2+param_mood+param_rewSen),2);
idx_valid = (valid_play>=3);
nSub_valid = sum(idx_valid);


nMonth = size(pc1,2);
list_month = [1:nMonth];
demo = [
    longitudinalData{1}.demographics.age,...
    double(longitudinalData{1}.demographics.gender==1),...
    longitudinalData{1}.demographics.education];

clear xData_combined
list_subno_combined= [];
list_monthno_combined = [];
for m = 1:nMonth

    % select months
    idx_month = m;
    % idx_mean = list_month(list_month~=m);
    idx_mean = list_month;

    % organize data
    pc1_mean = nanmean(pc1(:, idx_mean),2);
    pc2_mean = nanmean(pc2(:, idx_mean),2);
    mood_mean = nanmean(param_mood(:, idx_mean),2);
    rewSen_mean = nanmean(param_rewSen(:, idx_mean),2);

    task_score_mean = nanmean(task_score(:, idx_mean),2);
    task_performance_mean = nanmean(task_performance(:, idx_mean),2);

    xData = [
        pc1(:,idx_month),...
        pc2(:,idx_month),...
        pc1_mean, pc1(:,idx_month)-pc1_mean,...
        pc2_mean, pc2(:,idx_month)-pc2_mean,...
        mood_mean, param_mood(:,idx_month)-mood_mean,...
        rewSen_mean, param_rewSen(:,idx_month)-rewSen_mean,...
        task_score_mean, task_score(:,idx_month)-task_score_mean,...
        task_performance_mean, task_performance(:,idx_month)-task_performance_mean,...
        param_mood(:,idx_month), mood_mean-param_mood(:,idx_month),...
        param_rewSen(:,idx_month), rewSen_mean-param_rewSen(:,idx_month)];

    xData = [xData, demo];

    % keep valid subjects
    xData = xData(idx_valid,:);
    

    list_subno = [1:size(xData,1)]';
    list_monthno = ones(size(xData,1),1)*m;

    if m==1
        xData_combined = xData;
        list_subno_combined = list_subno;
        list_monthno_combined = list_monthno;
    else
        xData_combined = [xData_combined; xData];
        list_subno_combined = [list_subno_combined; list_subno];
        list_monthno_combined = [list_monthno_combined; list_monthno];
    end

end

% standarization
xData_combined = (xData_combined - repmat(nanmean(xData_combined,1),size(xData_combined,1),1)) ./ repmat(nanstd(xData_combined,0,1),size(xData_combined,1),1);

% convert to table
tbl = array2table([xData_combined, list_subno_combined, list_monthno_combined],...
    'VariableNames',...
    {'pc1_t',...
    'pc2_t',...
    'pc1_mean', 'pc1_change',...
    'pc2_mean', 'pc2_change',...
    'mood_mean', 'mood_change',...
    'rewSen_mean', 'rewSen_change',...
    'task_score_mean', 'task_score_change',...
    'task_performance_mean', 'task_performance_change',...
    'mood_t', 'mood_det',...
    'rewSen_t', 'rewSen_det',...
    'age', 'gender', 'education',...
    'subno', 'monthno'});


% model
% pc1
% model_full = fitlme(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change|subno)')
% model_without_mood_mean = fitlme(tbl, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_mean + rewSen_change|subno)')
% model_without_mood_change = fitlme(tbl, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + rewSen_mean + rewSen_change|subno)')
% model_without_mood = fitlme(tbl, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_mean + rewSen_change|subno)')

model_full = fitlme(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
model_without_mood_mean = fitlme(tbl, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
model_without_mood_change = fitlme(tbl, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_change|subno)')
model_without_mood = fitlme(tbl, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_change|subno)')


% model_full = fitlme(tbl, 'pc1_t ~ mood_t + mood_det + rewSen_t + rewSen_det + age + gender + education + (1 + mood_t + mood_det + rewSen_t + rewSen_det|subno)')

model_1 = model_full;
% model_2 = model_without_mood_mean;
% model_2 = model_without_mood_change;
model_2 = model_without_mood;

% model comparison
% note: df = fixed + unique variance-covariance varaibel + residual (1)
model_comparison = compare(model_2, model_1)

% color
% mood: [0.9098    0.2588    0.3608]
% rewSen: [0.1647    0.2000    0.3961]


x = tbl.mood_mean;
y = tbl.pc1_mean;
x = nanmean(reshape(x,[],5),2);
y = nanmean(reshape(y,[],5),2);
[rho,pval] = corr(x,y,'type','spearman')
figure;
hold on
reg_beta = glmfit(x(:),y(:));
xval = [min(x(:));max(x(:))];
yval = glmval(reg_beta,xval,'identity');
plot(xval,yval,...
    'linestyle','-',...
    'linewidth', 4,...
    'color', 'k');
plot(x(:),y(:),...
    'linestyle','none',...
    'marker', 'o',...
    'markersize', 8,...
    'markerfacecolor', [0.5020, 0, 0.4549],...
    'markeredgecolor', 'w',...
    'linewidth', 1);
hold off
xlim([0,100]);
ylim([-12,12]);


x = tbl.mood_change;
y = tbl.pc1_t - tbl.pc1_mean;
x = reshape(x,[],5);
y = reshape(y,[],5);
[rho,pval] = corr(x,y,'type','spearman','row','pairwise')
% plot(x,y,'ko')

% color_mat = sky;
% list_color = {
%     color_mat(20,:);
%     color_mat(70,:);
%     color_mat(120,:);
%     color_mat(170,:);
%     color_mat(220,:);
%     };

% color_mood = [0.9098    0.2588    0.3608];
% color_mood = [0.1647    0.2000    0.3961];
% color_base = [0.8, 0.8, 0.8];
% color_noise = {
%     [0.1608, 0.5490, 0.5490];
%     [0.5020, 0, 0.4549]
%     };

color_mood = [0.5020, 0, 0.4549];
color_base = [0.8, 0.8, 0.8];
color_mat = [linspace(color_base(1), color_mood(1), 7)',...
    linspace(color_base(2), color_mood(2), 7)',...
    linspace(color_base(3), color_mood(3), 7)'];
list_color = {
    color_mat(2,:);
    color_mat(3,:);
    color_mat(4,:);
    color_mat(5,:);
    color_mat(6,:);
    };

figure;
hold on
reg_beta = glmfit(x(:),y(:));
xval = [min(x(:));max(x(:))];
yval = glmval(reg_beta,xval,'identity');
plot(xval,yval,...
    'linestyle','-',...
    'linewidth', 4,...
    'color', 'k');
for i = 1:5
    plot(x(:,i),y(:,i),...
        'linestyle','none',...
        'marker', 'o',...
        'markersize', 6,...
        'markerfacecolor', list_color{i},...
        'markeredgecolor', 'w',...
        'linewidth', 0.5);
end
hold off
xlim([-50,50]);
ylim([-12,12]);



x = tbl.rewSen_mean;
y = tbl.pc2_mean;
x = nanmean(reshape(x,[],5),2);
y = nanmean(reshape(y,[],5),2);
[rho,pval] = corr(x,y,'type','spearman')
% plot(x,y,'ko')


x = tbl.rewSen_change;
y = tbl.pc2_t - tbl.pc2_mean;
x = reshape(x,[],5);
y = reshape(y,[],5);
[rho,pval] = corr(x,y,'type','spearman','row','pairwise')
plot(x,y,'ko')




% coef_estimate = model_full.Coefficients.Estimate(2:3);
% coef_se = model_full.Coefficients.SE(2:3);
% zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1)
% else
%     pval_diff = cdf('normal',zval_diff,0,1)
% end


% model_full = fitlme(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + pc2_mean + pc2_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + pc2_mean + pc2_change|subno)')
% 
% coef_estimate = model_full.Coefficients.Estimate(4:5);
% coef_se = model_full.Coefficients.SE(4:5);
% zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1)
% else
%     pval_diff = cdf('normal',zval_diff,0,1)
% end


% pc2
% model_full = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change|subno)')
% model_without_rewSen_mean = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_change|subno)')
% model_without_rewSen_change = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean|subno)')
% model_without_rewSen = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + age + gender + education + (1 + mood_mean + mood_change|subno)')

model_full = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
model_without_rewSen_mean = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_change + age + gender + education + (1 + mood_change + rewSen_change|subno)')
model_without_rewSen_change = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + (1 + mood_change|subno)')
model_without_rewSen = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + age + gender + education + (1 + mood_change|subno)')

% model_full = fitlme(tbl, 'pc2_t ~ mood_t + mood_det + rewSen_t + rewSen_det + age + gender + education + (1 + mood_t + mood_det + rewSen_t + rewSen_det|subno)')

model_1 = model_full
% model_2 = model_without_rewSen_mean
model_2 = model_without_rewSen_change
% model_2 = model_without_rewSen

% model comparison
model_comparison = compare(model_2, model_1)


coef_estimate = model_full.Coefficients.Estimate(4:5);
coef_se = model_full.Coefficients.SE(4:5);
zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1)
else
    pval_diff = cdf('normal',zval_diff,0,1)
end



% model_full = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + pc1_mean + pc1_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + pc1_mean + pc1_change|subno)')
% 
% coef_estimate = model_full.Coefficients.Estimate(6:7);
% coef_se = model_full.Coefficients.SE(6:7);
% zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1)
% else
%     pval_diff = cdf('normal',zval_diff,0,1)
% end






%%%%% combined: past vs future %%%%
valid_play = sum(~isnan(pc1+pc2+param_mood+param_rewSen),2);
idx_valid = (valid_play>=3);
% idx_valid = idx_valid & (longitudinalData{1}.scid.current_mde==1 | longitudinalData{1}.scid.past_mde==1);
nSub_valid = sum(idx_valid);


nMonth = size(pc1,2);
list_month = [1:nMonth];
demo = [
    longitudinalData{1}.demographics.age,...
    double(longitudinalData{1}.demographics.gender==1),...
    longitudinalData{1}.demographics.education];
% scid_info = double(longitudinalData{1}.scid.current_mde==1 | longitudinalData{1}.scid.past_mde==1);

xData_combined = [];
list_subno_combined= [];
list_monthno_combined = [];
% for m = 1:nMonth
for m = 3:nMonth

    % select months
    idx_month = m;
    idx_mean = list_month(list_month<m);

    % organize data
    pc1_mean = nanmean(pc1(:, idx_mean),2);
    pc2_mean = nanmean(pc2(:, idx_mean),2);
    mood_mean = nanmean(param_mood(:, idx_mean),2);
    rewSen_mean = nanmean(param_rewSen(:, idx_mean),2);

    task_score_mean = nanmean(task_score(:, idx_mean),2);
    task_performance_mean = nanmean(task_performance(:, idx_mean),2);

    xData = [
        pc1(:,idx_month),...
        pc2(:,idx_month),...
        pc1_mean, pc1(:,idx_month)-pc1_mean,...
        pc2_mean, pc2(:,idx_month)-pc2_mean,...
        mood_mean, param_mood(:,idx_month)-mood_mean,...
        rewSen_mean, param_rewSen(:,idx_month)-rewSen_mean,...
        task_score_mean, task_score(:,idx_month)-task_score_mean,...
        task_performance_mean, task_performance(:,idx_month)-task_performance_mean];

    xData = [xData, demo];

    % keep valid subjects
    xData = xData(idx_valid,:);
    

    list_subno = [1:size(xData,1)]';
    list_monthno = ones(size(xData,1),1)*m;

    xData_combined = [xData_combined; xData];
    list_subno_combined = [list_subno_combined; list_subno];
    list_monthno_combined = [list_monthno_combined; list_monthno];

end

% standarization
xData_combined = (xData_combined - repmat(nanmean(xData_combined,1),size(xData_combined,1),1)) ./ repmat(nanstd(xData_combined,0,1),size(xData_combined,1),1);

% convert to table
tbl = array2table([xData_combined, list_subno_combined, list_monthno_combined],...
    'VariableNames',...
    {'pc1_t',...
    'pc2_t',...
    'pc1_mean', 'pc1_change',...
    'pc2_mean', 'pc2_change',...
    'mood_mean', 'mood_change',...
    'rewSen_mean', 'rewSen_change',...
    'task_score_mean', 'task_score_change',...
    'task_performance_mean', 'task_performance_change',...
    'age', 'gender', 'education',...
    'subno', 'monthno'});


% model
% model_baseline = fitlm(tbl(idx_select,:), 'pc1_m6 ~ pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_mood = fitlm(tbl(idx_select,:), 'pc1_m6 ~ mood_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_rewSen = fitlm(tbl(idx_select,:), 'pc1_m6 ~ rewSen_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')

% pc1
model_full = fitlme(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change|subno)')
model_without_mood_mean = fitlme(tbl, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_change + rewSen_mean + rewSen_change|subno)')
model_without_mood_change = fitlme(tbl, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + rewSen_mean + rewSen_change|subno)')
model_without_mood = fitlme(tbl, 'pc1_t ~ rewSen_mean + rewSen_change + age + gender + education + (1 + rewSen_mean + rewSen_change|subno)')

model_1 = model_full
% model_2 = model_without_mood_mean
% model_2 = model_without_mood_change
model_2 = model_without_mood

LR = 2*(model_1.LogLikelihood - model_2.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = (numel(model_1.randomEffects)+model_1.NumEstimatedCoefficients) - (numel(model_2.randomEffects)+model_2.NumEstimatedCoefficients)
pval = 1 - chi2cdf(LR, df)


coef_estimate = model_full.Coefficients.Estimate(2:3);
coef_se = model_full.Coefficients.SE(2:3);
zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1)
else
    pval_diff = cdf('normal',zval_diff,0,1)
end

model_full = fitlme(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + task_score_mean + task_score_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + task_score_mean + task_score_change|subno)')
model_full = fitlme(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + task_performance_mean + task_performance_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + task_performance_mean + task_performance_change|subno)')

% model_full = fitlme(tbl, 'pc1_mean ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change|subno)')

model_full = fitlme(tbl, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + pc2_mean + pc2_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + pc2_mean + pc2_change|subno)')

coef_estimate = model_full.Coefficients.Estimate(4:5);
coef_se = model_full.Coefficients.SE(4:5);
zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1)
else
    pval_diff = cdf('normal',zval_diff,0,1)
end


% pc2
model_full = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change|subno)')
model_without_rewSen_mean = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_change|subno)')
model_without_rewSen_change = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean|subno)')
model_without_rewSen = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + age + gender + education + (1 + mood_mean + mood_change|subno)')

model_1 = model_full
% model_2 = model_without_rewSen_mean
% model_2 = model_without_rewSen_change
model_2 = model_without_rewSen

LR = 2*(model_1.LogLikelihood - model_2.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = (numel(model_1.randomEffects)+model_1.NumEstimatedCoefficients) - (numel(model_2.randomEffects)+model_2.NumEstimatedCoefficients)
pval = 1 - chi2cdf(LR, df)


coef_estimate = model_full.Coefficients.Estimate(4:5);
coef_se = model_full.Coefficients.SE(4:5);
zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1)
else
    pval_diff = cdf('normal',zval_diff,0,1)
end


model_full = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + task_score_mean + task_score_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + task_score_mean + task_score_change|subno)')
model_full = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + task_performance_mean + task_performance_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + task_performance_mean + task_performance_change|subno)')

% model_full = fitlme(tbl, 'pc2_change ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change|subno)')
% model_full = fitlme(tbl, 'pc2_mean ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change|subno)')


model_full = fitlme(tbl, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + pc1_mean + pc1_change + age + gender + education + (1 + mood_mean + mood_change + rewSen_mean + rewSen_change + pc1_mean + pc1_change|subno)')

coef_estimate = model_full.Coefficients.Estimate(6:7);
coef_se = model_full.Coefficients.SE(6:7);
zval_diff = (coef_estimate(1)-coef_estimate(2))./sqrt(coef_se(1)^2+coef_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1)
else
    pval_diff = cdf('normal',zval_diff,0,1)
end






%% longitudinal: monthly (m2-m6)
% parameter over plays: split groups, initial <0/>0 X worse/better

pc_type = 'pc1';
% pc_type = 'pc2';

data_type = 'pc1';
% data_type = 'pc2';
% data_type = 'mood';
% data_type = 'rewSen';
% data_type = 'alpha';

%%%%% get pc score %%%%%
nSub = size(longitudinalData{1}.questionnaire.PHQ_total,1);

nSurvey_total = 0;
surveyData = [];
v = 3;

nSurvey_max = list_version{v,5};
nSurvey_total = nSurvey_total + nSurvey_max;

for i = 1:nSurvey_max

    temp_surveyData = [longitudinalData{v}.questionnaire.PHQ_item(:,:,i),...
        longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
        longitudinalData{v}.questionnaire.GAD_item(:,:,i),...
        longitudinalData{v}.questionnaire.AMI_behavioral_item(:,:,i)];

    surveyData = [surveyData; temp_surveyData];

end

% apply to questionnaire at different times
pca_coeff = combined_data_coeff;

surveyData_new = surveyData;
surveyData_new = surveyData_new - combined_data_mu;
pca_coeff_new = pca_coeff;
pca_score_new = surveyData_new*pca_coeff_new;

pc1 = reshape(pca_score_new(:,1), nSub, nSurvey_total);
pc2 = reshape(pca_score_new(:,2), nSub, nSurvey_total);


% data
param_mood = [];
param_rewSen = [];
v = 3;

list_block = list_version{v, 2};

% mood
data_mood = longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block);
param_mood = data_mood;

% rewSen
data_rewSen = longitudinalData{v}.model_learning{2}.parameter(:,1+list_block);
param_rewSen = data_rewSen;



%%%%% organize data %%%%%
% pc1_pre = pc1(:,1);
% pc2_pre = pc2(:,1);

pc1_post = pc1(:,end);
pc2_post = pc2(:,end);

pc1_mean = nanmean(pc1,2);
pc2_mean = nanmean(pc2,2);

switch pc_type
    case {'pc1'}
        % qval = pc1_pre;
        % yData = pc1_post-pc1_pre;
        qval = pc1_mean;
        yData = pc1_post-pc1_mean;
    case {'pc2'}
        % qval = pc2_pre;
        % yData = pc2_post-pc2_pre;
        qval = pc2_mean;
        yData = pc2_post-pc2_mean;
end

switch data_type
    case {'mood'}
        xData = param_mood;
    case {'rewSen'}
        xData = param_rewSen;
    case {'pc1'}
        xData = pc1;
    case {'pc2'}
        xData = pc2;
end




nPlay = size(xData,2);
% xData = xData - repmat(xData(:,1), 1, nPlay);
clear h_data
list_color = {
    [0.6,0.6,1];
    [0.2,0.2,1];
    [1,0.6,0.6];
    [1,0.2,0.2];
    };
list_linestyle = {
    '--';
    '-';
    '--';
    '-';
    };
list_marker = {
    'o';
    '^';
    'o';
    '^';
    };


nSub_group = NaN(4,1);
idx_plot = 0;
figure;
fg = fig_setting_default();
fg.pp(4) = fg.pp(4)*1.2;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on
for i = 1:2
    for j = 1:2

        idx_plot = idx_plot + 1;

        if i==1
            % idx_q = qval<=nanmedian(qval);
            idx_q = qval<=0;
        elseif i==2
            % idx_q = qval>nanmedian(qval);
            idx_q = qval>0;
        end
        if j==1
            idx_change = (yData<0);
        elseif j==2
            idx_change = (yData>0);
        end
        idx_select = idx_q & idx_change;

        data_select = xData(idx_select,:);
        nSub_select = size(data_select,1);
        nSub_group(idx_plot) = nSub_select;

        xval = [1:size(data_select,2)];
        meanData = nanmean(data_select,1);
        semData = nanstd(data_select,0,1)./sqrt(nSub_select);

        h = plot(xval, meanData,...
            'linestyle', list_linestyle{idx_plot},...
            'linewidth', 2,...
            'color', list_color{idx_plot},...
            'marker', list_marker{idx_plot},...
            'markersize', 12,...
            'markerfacecolor', list_color{idx_plot}, ...
            'markeredgecolor', 'k');
        h_data(idx_plot) = h;
        e = errorbar(xval, meanData, semData,...
            'linestyle', 'none',...
            'linewidth', 2,...
            'color', 'k');

    end
end
hold off
set(gca, 'fontsize', 24, 'linewidth', 2);
xlim([0.5,5.5]);

switch data_type
    case {'mood'}
        ylim([40,80]);
    case {'rewSen'}
        ylim([-40,-10]);
    case {'pc1'}
        ylim([-7, 7]);
    case {'pc2'}
        ylim([-7, 7]);

end

list_xtick_label = {
    'm2';
    'm3';
    'm4';
    'm5';
    'm6';
    };
set(gca,...
    'XTick',[1:numel(list_xtick_label)],...
    'XTickLabel', list_xtick_label);

xlabel('time');
ylabel(data_type);

text_legend = {
    sprintf('pc initial<0, getting better (change<0) (n=%d)', nSub_group(1));
    sprintf('pc initial<0, getting worse (change>0) (n=%d)', nSub_group(2));
    sprintf('pc initial>0, getting better (change<0) (n=%d)', nSub_group(3));
    sprintf('pc initial>0, getting worse (change>0) (n=%d)', nSub_group(4));
    };
legend(h_data, text_legend,...
    'location', 'SouthOutside',...
    'fontsize', 20);




%%%%% regression cross-section %%%%
% % predict parameter
% demo = [
%     longitudinalData{1}.demographics.age,...
%     double(longitudinalData{1}.demographics.gender==1),...
%     longitudinalData{1}.demographics.education];
% 
% 
% xData = [
%     pc1,...
%     pc2,...
%     param_mood,...
%     param_rewSen,...
%     demo];
% 
% xData = (xData - repmat(nanmean(xData,1),nSub,1)) ./ repmat(nanstd(xData,0,1),nSub,1);
% 
% tbl = array2table(xData,...
%         'VariableNames',...
%         {'pc1_m0', 'pc1_m2', 'pc1_m3', 'pc1_m4', 'pc1_m5', 'pc1_m6',...
%         'pc2_m0', 'pc2_m2', 'pc2_m3', 'pc2_m4', 'pc2_m5', 'pc2_m6',...
%         'mood_m0', 'mood_m2', 'mood_m3', 'mood_m4', 'mood_m5', 'mood_m6',...
%         'rewSen_m0', 'rewSen_m2', 'rewSen_m3', 'rewSen_m4', 'rewSen_m5', 'rewSen_m6',...
%         'age', 'gender', 'education'});



%%%%% regression: predicting future with mean and change %%%%
list_month = [1:5];
nMonth = numel(list_month);
demo = [
    longitudinalData{1}.demographics.age,...
    double(longitudinalData{1}.demographics.gender==1),...
    longitudinalData{1}.demographics.education];

for m = 1:nMonth
    
    idx_month = m;
    idx_mean = list_month(list_month~=m);




end



















% compare between mood and rewSen
% model_pc1_m6 = fitlm(tbl, 'pc1_m6 ~ mood_pre + mood_post + rewSen_pre + rewSen_post + pc1_pre + age + gender + education')
% model_pc1 = fitlm(tbl, 'pc1_post ~ mood_pre + re
% wSen_pre + rewSen_post + pc1_pre + age + gender 
% + education')
% model_pc2 = fitlm(tbl, 'pc2_post ~ mood_pre + mood_post + rewSen_pre + rewSen_post + pc2_pre + age + gender + education')
% model_pc1 = fitlm(tbl, 'pc1_post ~ mood_pre + mood_post + rewSen_pre + rewSen_post + age + gender + education')

%%%%% m6 %%%%%
% idx_select = ~isnan(sum(tbl(:,{'pc1_m0', 'pc1_m6', 'pc2_m0', 'pc2_m6', 'mood_m0', 'mood_m6', 'rewSen_m0', 'rewSen_m6', 'age', 'gender', 'education'}),2).Variables);

% model_baseline = fitlm(tbl(idx_select,:), 'pc1_m6 ~ pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_mood = fitlm(tbl(idx_select,:), 'pc1_m6 ~ mood_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_rewSen = fitlm(tbl(idx_select,:), 'pc1_m6 ~ rewSen_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_full = fitlm(tbl(idx_select,:), 'pc1_m6 ~ mood_m6 + rewSen_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')

% model_baseline = fitlm(tbl(idx_select,:), 'pc2_m6 ~ pc2_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_mood = fitlm(tbl(idx_select,:), 'pc2_m6 ~ mood_m6 + pc2_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_rewSen = fitlm(tbl(idx_select,:), 'pc2_m6 ~ rewSen_m6 + pc2_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_full = fitlm(tbl(idx_select,:), 'pc2_m6 ~ mood_m6 + rewSen_m6 + pc2_m0 + mood_m0 + rewSen_m0 + age + gender + education')

%%%%% m2 %%%%%
% % idx_select = ~isnan(sum(tbl(:,{'pc1_m0', 'pc1_m2', 'pc2_m0', 'pc2_m2', 'mood_m0', 'mood_m2', 'rewSen_m0', 'rewSen_m2', 'age', 'gender', 'education'}),2).Variables);
idx_select = ~isnan(sum(tbl(:,{'pc1_m0', 'pc1_m6', 'pc2_m0', 'pc2_m6', 'mood_m0', 'mood_m6', 'rewSen_m0', 'rewSen_m6', 'age', 'gender', 'education'}),2).Variables);
% 
% model_full = fitlm(tbl(idx_select,:), 'pc1_m6 ~ mood_m6 + rewSen_m6 + pc1_m2 + mood_m2 + rewSen_m2 + age + gender + education')
% % model_full = fitlm(tbl, 'pc1_m4 ~ mood_m4 + rewSen_m4 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% 
% model_full = fitlm(tbl(idx_select,:), 'pc2_m5 ~ mood_m5 + rewSen_m5 + pc2_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% model_full = fitlm(tbl(idx_select,:), 'pc2_m6 ~ mood_m6 + rewSen_m6 + pc2_m2 + mood_m2 + rewSen_m2 + age + gender + education')

model_0 = model_baseline;
model_1 = model_mood;
LR = 2*(model_1.LogLikelihood - model_0.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = model_1.NumEstimatedCoefficients - model_0.NumEstimatedCoefficients
pval = 1 - chi2cdf(LR, df)

model_0 = model_rewSen;
model_1 = model_full;
LR = 2*(model_1.LogLikelihood - model_0.LogLikelihood) % has a X2 distribution with a df equals to number of constrained parameters
df = model_1.NumEstimatedCoefficients - model_0.NumEstimatedCoefficients
pval = 1 - chi2cdf(LR, df)


% reg_beta = model_full.Coefficients.Estimate(2:end);
% reg_se = model_full.Coefficients.SE(2:end);

% % mood: m0 vs m6
% zval_diff = (reg_beta(2)-reg_beta(3))./sqrt(reg_se(2)^2+reg_se(3)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1);
% else
%     pval_diff = cdf('normal',zval_diff,0,1);
% end
% pval_diff
% 
% % rewSen: m0 vs m6
% zval_diff = (reg_beta(4)-reg_beta(5))./sqrt(reg_se(4)^2+reg_se(5)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1);
% else
%     pval_diff = cdf('normal',zval_diff,0,1);
% end
% pval_diff
% 
% % m6: mood vs rewSen
% zval_diff = (reg_beta(3)-reg_beta(5))./sqrt(reg_se(3)^2+reg_se(5)^2);
% if zval_diff>0
%     pval_diff = 1-cdf('normal',zval_diff,0,1);
% else
%     pval_diff = cdf('normal',zval_diff,0,1);
% end
% pval_diff


%%%%% figure: pc1 ~ mood + rewSen %%%%%
% idx_select = ~isnan(sum(tbl(:,{'pc1_m0', 'pc1_m6', 'pc2_m0', 'pc2_m6', 'mood_m0', 'mood_m6', 'rewSen_m0', 'rewSen_m6', 'age', 'gender', 'education'}),2).Variables);
% model_full = fitlm(tbl(idx_select,:), 'pc1_m6 ~ mood_m6 + rewSen_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education');
% reg_beta = model_full.Coefficients.Estimate(2:end);
% reg_se = model_full.Coefficients.SE(2:end);
% 
% clear result_summay
% result_summary.beta = model_full.Coefficients.Estimate(3:6);
% result_summary.se = model_full.Coefficients.SE(3:6);
% result_summary.p = model_full.Coefficients.pValue(3:6);
% 
% yrange = [-0.6,0.6];
% 
% clear h_data
% yscale = max(yrange)-min(yrange);
% 
% list_facecolor = {
%     [1,1,1];
%     [0.8320, 0.3672, 0];
%     [1,1,1];
%     [0, 0.4453, 0.6953];
%     };
% list_edgecolor = {
%     [0.8320, 0.3672, 0];
%     [0,0,0];
%     [0, 0.4453, 0.6953];
%     [0,0,0];
%     };
% 
% figure;
% fg = fig_setting_default();
% fg.pp(3) = fg.pp(3)*1;
% fg.pp(4) = fg.pp(4)*1.2;
% set(gcf,...
%     'Position',fg.pp,...
%     'PaperPosition', fg.pp,...
%     'PaperSize', fg.pp([3:4]));
% set(gcf, 'PaperPositionMode', 'Auto');
% 
% hold on
% plot([0.5,4.5],[0,0],...
%     'linestyle', '--',...
%     'linewidth', 2,...
%     'color', [0.5,0.5,0.5]);
% for i = 1:4
% 
%     xData = i;
%     yData = result_summary.beta(i);
%     yData_sem = result_summary.se(i);
%     yData_pval = result_summary.p(i);
% 
%     h = bar(xData, yData,...
%         'linewidth', 2,...
%         'barwidth', 0.3,...
%         'facecolor', list_facecolor{i},...
%         'edgecolor', list_edgecolor{i});
% 
%     errorbar(xData, yData, yData_sem,...
%         'linestyle', 'none',...
%         'linewidth', 2,...
%         'color', 'k',...
%         'CapSize',16);
% 
% 
%     pval = yData_pval;
%     if pval<0.05
%         if pval<0.001
%             text_pval = 'P<.001';
%         else
%             text_pval = sprintf('P=%.3f',pval);
%             text_pval(3) = [];
%         end
%         xpos = xData;
%         ypos = yData - yData_sem - yscale*0.05;
%         text(xpos, ypos, text_pval,...
%             'fontsize',24,...
%             'horizontalalignment', 'center',...
%             'verticalalignment', 'middle',...
%             'color', 'k');
%     end
% 
% 
% end
% 
% % idx_sig = 0;
% % for i = 1:3
% % 
% %     pval_diff = result_summary.pval_diff(i,3);
% %     if pval_diff<0.05
% %         idx_sig = idx_sig + 1;
% %         if pval_diff<0.001
% %             text_pval = 'P<.001';
% %         else
% %             text_pval = sprintf('P=%.3f',pval_diff);
% %             text_pval(3) = [];
% %         end
% %         xpos = result_summary.pval_diff(i,[1,2]);
% %         ypos = max(max(result_summary.beta+result_summary.se),0)*[1,1] + yscale*(0.1);
% %         plot(xpos,ypos,...
% %             'linestyle', '-',...
% %             'linewidth', 4,...
% %             'color', 'k');
% %         text(mean(xpos), mean(ypos), text_pval,...
% %             'fontsize',24,...
% %             'horizontalalignment', 'center',...
% %             'verticalalignment', 'bottom',...
% %             'color', 'k');
% % 
% %     end
% % end
% 
% hold off
% set(gca,'fontsize',30,'linewidth',2);
% % xlabel('Regressor');
% xlabel(sprintf('\n\n'));
% ylabel('Regression coefficient');
% 
% xlim([0.5,4.5]);
% ylim(yrange);
% set(gca,'YTick',[-0.6:0.3:0.6]);
% 
% set(gca,'XTick',[1,2,3,4], ...
%     'XTickLabel',{'T0', ''});
% text_xticklabel = {sprintf('General\ndepression\ndimension'), sprintf('Anhedonia\ndimension'), sprintf('MDD\ndiagnosis')};
% list_xShift = [-0.15, 0, 0.15];
% for i = 1:3
%     xpos = i + list_xShift(i);
%     ypos = min(yrange) - (max(yrange)-min(yrange))*0.02;
%     text(xpos, ypos, text_xticklabel{i},...
%         'fontsize', 30,...
%         'HorizontalAlignment', 'Center',...
%         'VerticalAlignment', 'top');
% end
% 
% % output figure
% % fig_file = fullfile(dirFig, sprintf('%s_reg_mood_pca_acrossSubject', dataset_name));
% fig_file = fullfile(dirFig, sprintf('%s_reg_learning_pca_acrossSubject', dataset_name));
% print(fig_file, '-dpdf');







%%%%% figure: change, mood X pc1 %%%%%
x = param_mood(:,6) - param_mood(:,1);
y = pc1(:,6) - pc1(:,1);
% y = pc2(:,6) - pc2(:,1);

[rho,pval] = corr(x,y,'type','spearman','rows','pairwise')
figure;
fg = fig_setting_default;
fg.pp(3) = fg.pp(3)*1.1;
fg.pp(4) = fg.pp(4)*1.1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on

[reg_beta] = glmfit(x,y);
xval = [min(x),max(x)];
yval = glmval(reg_beta,xval,'identity');
plot(xval, yval,...
    'linestyle', '-',...
    'color', 'k',...
    'linewidth', 4);

plot(x,y,...
    'linestyle', 'none',...
    'marker', 'o',...
    'markersize', 10,...
    'markerfacecolor', [0.8320, 0.3672, 0],...
    'markeredgecolor', 'w');

hold off
set(gca, 'fontsize', 24, 'linewidth', 2);
xlabel(sprintf('Changes in 6 months\n baseline mood'));
ylabel(sprintf('Changes in 6 months\n general depression dimension'));
xlim([-40,40]);
ylim([-10,10]);
set(gca,...
    'xtick',[-40:20:40],...
    'ytick',[-10:5:10]);
fig_file = fullfile(dirFig, 'monthly_change_corr_mood_pc1');
print(fig_file, '-dpdf');




%%%%% figure: avg mood X avg pc1 %%%%%
x = nanmean(param_mood(:,2:6),2);
y = nanmean(pc1(:,2:6),2);
% y = nanmean(pc2(:,2:6),2);

[rho,pval] = corr(x,y,'type','spearman','rows','pairwise')
figure;
fg = fig_setting_default;
fg.pp(3) = fg.pp(3)*1.1;
fg.pp(4) = fg.pp(4)*1.1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on

[reg_beta] = glmfit(x,y);
xval = [min(x),max(x)];
yval = glmval(reg_beta,xval,'identity');
plot(xval, yval,...
    'linestyle', '-',...
    'color', 'k',...
    'linewidth', 4);

plot(x,y,...
    'linestyle', 'none',...
    'marker', 'o',...
    'markersize', 10,...
    'markerfacecolor', [0.8320, 0.3672, 0],...
    'markeredgecolor', 'w');

hold off
set(gca, 'fontsize', 24, 'linewidth', 2);
xlabel(sprintf('Average across month 2-6\n baseline mood'));
ylabel(sprintf('Average across month 2-6\n general depression dimension'));
xlim([0,100]);
ylim([-15,15]);
set(gca,...
    'xtick',[0:20:100],...
    'ytick',[-15:5:15]);
fig_file = fullfile(dirFig, 'monthly_avg_corr_mood_pc1');
print(fig_file, '-dpdf');



%%%%% figure: change, rewSen X pc2 %%%%%
x = param_rewSen(:,6) - param_rewSen(:,1);
y = pc2(:,6) - pc2(:,1);
% y = pc1(:,6) - pc1(:,1);

% control_var = [pc2(:,1), param_rewSen(:,1), demo, pc1, param_mood];
% [reg_beta,dev,stats] = glmfit(control_var, x);
% x = stats.resid;
% [reg_beta,dev,stats] = glmfit(control_var, y);
% y = stats.resid;

[rho,pval] = corr(x,y,'type','spearman','rows','pairwise')
figure;
fig_setting_default;
hold on

[reg_beta] = glmfit(x,y);
xval = [min(x),max(x)];
yval = glmval(reg_beta,xval,'identity');
plot(xval, yval,...
    'linestyle', '-',...
    'color', 'k',...
    'linewidth', 4);

plot(x,y,...
    'linestyle', 'none',...
    'marker', 'o',...
    'markersize', 10,...
    'markerfacecolor', [0, 0.4453, 0.6953],...
    'markeredgecolor', 'w');

hold off
set(gca, 'fontsize', 24, 'linewidth', 2);
xlabel(sprintf('Changes in 6 months\n reward sensitivity'));
ylabel(sprintf('Changes in 6 months\n anhedonia dimension'));
xlim([-60,60]);
ylim([-10,10]);
set(gca,...
    'xtick',[-60:30:60],...
    'ytick',[-10:5:10]);
fig_file = fullfile(dirFig, 'monthly_change_corr_rewSen_pc2');
print(fig_file, '-dpdf');


%%%%% figure: avg rewSen X avg pc2 %%%%%
x = nanmean(param_rewSen(:,2:6),2);
y = nanmean(pc2(:,2:6),2);
% y = nanmean(pc1(:,2:6),2);

[rho,pval] = corr(x,y,'type','spearman','rows','pairwise')
figure;
fg = fig_setting_default;
fg.pp(3) = fg.pp(3)*1.1;
fg.pp(4) = fg.pp(4)*1.1;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');

hold on

[reg_beta] = glmfit(x,y);
xval = [min(x),max(x)];
yval = glmval(reg_beta,xval,'identity');
plot(xval, yval,...
    'linestyle', '-',...
    'color', 'k',...
    'linewidth', 4);

plot(x,y,...
    'linestyle', 'none',...
    'marker', 'o',...
    'markersize', 10,...
    'markerfacecolor', [0, 0.4453, 0.6953],...
    'markeredgecolor', 'w');

hold off
set(gca, 'fontsize', 24, 'linewidth', 2);
xlabel(sprintf('Average across month 2-6\n reward sensitivity'));
ylabel(sprintf('Average across month 2-6\n anhedonia dimension'));
xlim([-60,0]);
ylim([-10,10]);
set(gca,...
    'xtick',[-60:20:0],...
    'ytick',[-10:5:10]);
fig_file = fullfile(dirFig, 'monthly_avg_corr_rewSen_pc2');
print(fig_file, '-dpdf');



% % % xData = [nanmean(param_mood(:,[2:5]),2), param_mood(:,6),...
% % %     nanmean(param_rewSen(:,[2:5]),2), param_rewSen(:,6),...
% % %     param_mood(:,1), param_rewSen(:,1),...
% % %     pc1(:,1), demo];
% % % xData = [nanmean(param_mood(:,[1:5]),2), param_mood(:,6),...
% % %     nanmean(param_rewSen(:,[1:5]),2), param_rewSen(:,6)];
% % % xData = [nanmean(param_mood(:,[1:5]),2),...
% % %     nanmean(param_rewSen(:,[1:5]),2)];
% % % xData = [nanmean(param_mood(:,[1:5]),2), param_mood(:,6)];
% % % xData = [nanmean(param_mood(:,[1:5]),2)];
% % 
% % % xData = [nanmean(param_mood(:,2:5),2), param_mood(:,6)];
% % % xData = [nanmean(param_mood(:,2:5),2)];
% xData = [nanmean(param_mood(:,2:5),2), param_mood(:,6)-nanmean(param_mood(:,2:5),2)];
% 
% 
% xData = [xData, demo];
% % xData = [xData, pc1(:,1)];
% % yData = pc1(:,6);
% yData = pc2(:,6);


% xData = [nanmean(param_mood(:,[2:5]),2), param_mood(:,6),...
%     nanmean(param_rewSen(:,[2:5]),2), param_rewSen(:,6),...
%     param_mood(:,1), param_rewSen(:,1)];
% xData = [nanmean(param_rewSen(:,[1:5]),2), param_rewSen(:,6),...
%     nanmean(param_mood(:,[1:5]),2), param_mood(:,6)];
% xData = [nanmean(param_rewSen(:,[1:5]),2), param_rewSen(:,6)];
% xData = [nanmean(param_rewSen(:,[1:5]),2)];
% xData = [nanmean(param_mood(:,[1:5]),2), param_mood(:,6)];


% xData = [nanmean(param_rewSen(:,2:5),2), param_rewSen(:,6)];
% xData = [nanmean(param_rewSen(:,2:5),2)];
% xData = [nanmean(param_rewSen(:,2:5),2), param_rewSen(:,6)-nanmean(param_rewSen(:,2:5),2)];
% xData = [nanmean(param_rewSen(:,[2,6]),2), param_rewSen(:,6)-nanmean(param_rewSen(:,[2,6]),2)];
% xData = [nanmean(param_rewSen(:,2:6),2), param_rewSen(:,6)-param_rewSen(:,2)];

% xData = [nanmean(param_mood(:,2:5),2), param_mood(:,6)-nanmean(param_mood(:,2:5),2),...
%     nanmean(param_rewSen(:,2:5),2), param_rewSen(:,6)-nanmean(param_rewSen(:,2:5),2)];


xData = [xData, demo];
% xData = [xData, pc2(:,2)];
% xData = [xData, nanmean(pc2(:,[2:5]),2)];
yData = pc2(:,6);
% yData = pc1(:,6);
% yData = nanmean(pc2(:,6),2);


xData = (xData - repmat(nanmean(xData,1),nSub,1)) ./ repmat(nanstd(xData,0,1),nSub,1);
[reg_beta,dev,stats] = glmfit(xData, yData)
[stats.beta, stats.p]

reg_se = stats.se;

zval_diff = (reg_beta(2)-reg_beta(3))./sqrt(reg_se(2)^2+reg_se(3)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]


% [rho,pval] = corr(param_rewSen,pc1,'type','spearman','rows','pairwise')
% [rho,pval] = corr(param_rewSen,pc1,'type','spearman','rows','pairwise')
% [rho,pval] = corr(param_rewSen,,'type','spearman','rows','pairwise')
% [rho,pval] = corr(param_rewSen,pc1,'type','spearman','rows','pairwise')




%%%%% history %%%%%
% idx_select = ~isnan(sum(tbl(:,{'pc1_m0', 'pc1_m6', 'pc2_m0', 'pc2_m6', 'mood_m0', 'mood_m6', 'rewSen_m0', 'rewSen_m6', 'age', 'gender', 'education'}),2).Variables);
% 
% model_history = fitlm(tbl(idx_select,:), 'pc1_m5 ~ mood_m0 + mood_m2 + mood_m3 + mood_m4 + mood_m5 + mood_m6 + pc1_m0 + mood_m0 + rewSen_m0 + age + gender + education')
% 




%%%%% correlation %%%%%
nTime = size(pc1,2)-1;
rho_pval_all = NaN(nTime, 2);
for i = 1:nTime

    %%%%% pc1 X mood %%%%%
    x_baseline = pc1(:,1);
    y_baseline = param_mood(:,1);
    % x = pc1(:,i+1);
    x = pc1(:,4);
    y = param_mood(:,i+1);

    x = x - x_baseline;
    y = y - y_baseline;

    %%%%% pc2 X rewSen %%%%%
    % x_baseline = pc2(:,1);
    % y_baseline = param_rewSen(:,1);
    % x = pc2(:,i+1);
    % y = param_rewSen(:,i+1);

    % %%%%% regressing out baseline and demo %%%%%
    % [reg_beta,dev,stats] = glmfit([x_baseline, demo], x);
    % x = stats.resid;
    % 
    % [reg_beta,dev,stats] = glmfit([y_baseline, demo], y);
    % y = stats.resid;

    %%%%% correlation %%%%%
    [rho,pval] = corr(x,y,...
        'type','spearman',...
        'rows', 'pairwise');
    rho_pval_all(i,:) = [rho,pval];

end
rho_pval_all









%% SM: reliability: single plays
% clear data_reliability
% for v = 1:3
% 
%     sublist = allData{v}.sublist;
% 
%     version_data = list_version{v,1};
%     list_block = list_version{v,2};
%     nBlock = numel(list_block);
%     nSurvey_max = list_version{v,5};
% 
%     % apply to questionnaire at different times
%     pca_coeff = combined_data_coeff;
%     surveyData = [];
%     for i = 1:nSurvey_max
% 
%         temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
%             allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
%             allData{v}.questionnaire.GAD_item(:,:,i),...
%             allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
% 
%         surveyData = [surveyData; temp_surveyData];
% 
%     end
%     surveyData_new = surveyData;
%     surveyData_new = surveyData_new - combined_data_mu;
%     pca_coeff_new = pca_coeff;
%     pca_score_new = surveyData_new*pca_coeff_new;
% 
%     nSub = size(pca_score_new,1)/nSurvey_max;
%     pca_score = NaN(nSub,nSurvey_max,2);
%     for i = 1:2
%         temp_data = reshape(pca_score_new(:,i), nSub, nSurvey_max);
%         pca_score(:,:,i) = temp_data;
%     end
% 
%     % merge
%     data_reliability{v}.phq = allData{v}.questionnaire.PHQ_total;
%     data_reliability{v}.gad = allData{v}.questionnaire.GAD_total;
%     data_reliability{v}.anhedonia = allData{v}.questionnaire.MASQ_anhedonic_depression;
%     data_reliability{v}.bami = allData{v}.questionnaire.AMI_behavioral;
%     data_reliability{v}.pc1 = pca_score(:,:,1);
%     data_reliability{v}.pc2 = pca_score(:,:,2);
% 
%     data_reliability{v}.choice_pGood_average = allData{v}.behavior.choice_pGood_average;
%     data_reliability{v}.mean_happiness = allData{v}.behavior.happiness_mean;
% 
% 
%     % RL model
%     model_name = 'hbi_RL_outcomeSmall_initSmall_blockparam_single';
%     for b = 1:nBlock
%         block_model_name = sprintf('%s_block_%d-%d', model_name, b, b);
%         dirModel = fullfile('../../data/modelData', version_data, 'learning', block_model_name);
%         filename = sprintf('mle_%s_group.mat', block_model_name);
%         filename = fullfile(dirModel, filename);
%         load(filename);
% 
%         for i = 1:2
%              data_reliability{v}.rl_param(:,b,i) = cbm.model_info.subject.parameter(:,i);
%         end
% 
%     end
% 
% end
% 
% list_var = {
%     'phq';
%     'gad';
%     'anhedonia';
%     'bami';
%     'pc1';
%     'pc2'};
% nVar = numel(list_var);
% 
% for v = 3
%     for i = 1:nVar
% 
%         var_name = list_var{i};
%         fprintf('v=%d, var=%s\n', v, var_name);
% 
%         current_data = data_reliability{v}.(var_name);
%         [rho,pval] = corr(current_data,...
%             'type', 'pearson',...
%             'rows', 'pairwise');
%         rho
% 
%     end
% end
% 
% 
% 
% list_var = {
%     'choice_pGood_average';
%     'mean_happiness'};
% nVar = numel(list_var);
% 
% for v = 3
%     for i = 1:nVar
% 
%         var_name = list_var{i};
%         fprintf('v=%d, var=%s\n', v, var_name);
% 
%         current_data = data_reliability{v}.(var_name);
%         [rho,pval] = corr(current_data,...
%             'type', 'pearson',...
%             'rows', 'pairwise');
%         rho
% 
%     end
% end
% 
% 
% list_var = {
%     'alpha';
%     'rewSen'};
% for v = 3
%     for i = 1:2
% 
%         var_name = list_var{i};
%         fprintf('v=%d, var=%s\n', v, var_name);
% 
%         current_data = data_reliability{v}.rl_param(:,:,i);
%         [rho,pval] = corr(current_data,...
%             'type', 'pearson',...
%             'rows', 'pairwise');
%         rho
% 
%     end
% end
% 
% 
% v = 1;
% x1 = nanmean(data_reliability{v}.rl_param(:,[1:2:7],2),2);
% x2 = nanmean(data_reliability{v}.rl_param(:,[2:2:7],2),2);
% [rho,pval] = corr(x1,x2,...
%             'type', 'pearson',...
%             'rows', 'pairwise');
% rho
% 
% v = 2;
% x1 = nanmean(data_reliability{v}.rl_param(:,[1:2:6],2),2);
% x2 = nanmean(data_reliability{v}.rl_param(:,[2:2:6],2),2);
% [rho,pval] = corr(x1,x2,...
%             'type', 'pearson',...
%             'rows', 'pairwise');
% rho
% 
% v = 3;
% x1 = nanmean(data_reliability{v}.rl_param(:,[1:2:5],2),2);
% x2 = nanmean(data_reliability{v}.rl_param(:,[2:2:5],2),2);
% [rho,pval] = corr(x1,x2,...
%             'type', 'pearson',...
%             'rows', 'pairwise');
% rho
% 
% 
% 
% 
% list_var = {
%     'phq';
%     'gad';
%     'anhedonia';
%     'bami';
%     'pc1';
%     'pc2'};
% nVar = numel(list_var);
% 
% v = 3;
% for i = 1:nVar
%     varname = list_var{i};
%     x1 = nanmean(data_reliability{v}.(varname)(:,[1:2:end]),2);
%     x2 = nanmean(data_reliability{v}.(varname)(:,[2:2:end]),2);
%     [rho,pval] = corr(x1,x2,...
%         'type', 'pearson',...
%         'rows', 'pairwise');
%     rho
% end




%% SM: reliability: odd vs even
clear data_reliability
for v = 1:3

    sublist = allData{v}.sublist;
    data_reliability{v}.sublist = sublist;

    version_data = list_version{v,1};
    list_block = list_version{v,2};
    nBlock = numel(list_block);
    nSurvey_max = list_version{v,5};

    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    surveyData = [];
    for i = 1:nSurvey_max

        temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
            allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            allData{v}.questionnaire.GAD_item(:,:,i),...
            allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];

        surveyData = [surveyData; temp_surveyData];

    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;

    nSub = size(pca_score_new,1)/nSurvey_max;
    pca_score = NaN(nSub,nSurvey_max,2);
    for i = 1:2
        temp_data = reshape(pca_score_new(:,i), nSub, nSurvey_max);
        pca_score(:,:,i) = temp_data;
    end

    %%%%% questionnaires %%%%%
    clear odd_q even_q
    switch version_data
        case {'depression_denseSampling_remote'}
            odd_q  = [1];
            even_q = [2];
        case {'community_remote'}
            odd_q  = [1, 3];
            even_q = [2];
        case {'depression_monthly_remote'}
            odd_q  = [1, 3, 5];
            even_q = [2, 4];
    end

    % merge
    for i = 1:2
        if i==1
            idx_select = odd_q;
        elseif i==2
            idx_select = even_q;
        end

        data_reliability{v}.symptom.phq(:,i) = nanmean(allData{v}.questionnaire.PHQ_total(:,idx_select),2);
        data_reliability{v}.symptom.gad(:,i) = nanmean(allData{v}.questionnaire.GAD_total(:,idx_select),2);
        data_reliability{v}.symptom.anhedonia(:,i) = nanmean(allData{v}.questionnaire.MASQ_anhedonic_depression(:,idx_select),2);
        data_reliability{v}.symptom.bami(:,i) = nanmean(allData{v}.questionnaire.AMI_behavioral(:,idx_select),2);
        data_reliability{v}.symptom.pc1(:,i) = nanmean(pca_score(:,idx_select,1),2);
        data_reliability{v}.symptom.pc2(:,i) = nanmean(pca_score(:,idx_select,2),2);

    end

    %%%%% behavior & happiness %%%%%
    clear odd_play even_play
    switch version_data
        case {'depression_denseSampling_remote'}
            odd_play  = [1, 3, 5, 7];
            even_play = [2, 4, 6];
        case {'community_remote'}
            odd_play  = [1, 3, 5];
            even_play = [2, 4, 6];
        case {'depression_monthly_remote'}
            odd_play  = [1, 3, 5];
            even_play = [2, 4];
    end

    % merge
    for i = 1:2
        if i==1
            idx_select = odd_play;
        elseif i==2
            idx_select = even_play;
        end
        
        data_reliability{v}.behavior.choice_pGood_average(:,i) = nanmean(allData{v}.behavior.choice_pGood_average(:,idx_select),2);
        data_reliability{v}.behavior.mean_happiness(:,i) = nanmean(allData{v}.behavior.happiness_mean(:,idx_select),2);

    end

    %%%%% model: chocie %%%%%
    % merge
    model_name = 'hbi_RL_outcomeSmall_initSmall_distSmall_combined';
    for i = 1:2
        if i==1
            idx_select = odd_play;
            block_name = 'block_odd';
        elseif i==2
            idx_select = even_play;
            block_name = 'block_even';
        end

        block_model_name = sprintf('%s_%s', model_name, block_name);
        dirModel = fullfile('../../data/modelData', version_data, 'learning', block_model_name);
        filename = sprintf('mle_%s_group.mat', block_model_name);
        filename = fullfile(dirModel, filename);
        load(filename);

        param = cbm.model_info.subject.parameter;
        
        data_reliability{v}.model_choice.alpha(:,i) = param(:,1);
        data_reliability{v}.model_choice.rewSen(:,i) = param(:,2);

    end

    %%%%% model: happiness %%%%%
    clear odd_play even_play
    switch version_data
        case {'depression_denseSampling_remote'}
            odd_play  = [1, 3, 5, 7];
            even_play = [2, 4, 6];
        case {'community_remote'}
            odd_play  = [1, 3, 5];
            even_play = [2, 4, 6];
        case {'depression_monthly_remote'}
            odd_play  = [1, 3, 5];
            even_play = [2, 4];
    end

    % merge
    happiness_type = 'raw';
    model_name = 'hbi_happy_p_ppe_hbiRL_distSmall_combined';
    for i = 1:2
        if i==1
            idx_select = odd_play;
            block_name = 'block_odd';
        elseif i==2
            idx_select = even_play;
            block_name = 'block_even';
        end

        block_model_name = sprintf('%s_%s', model_name, block_name);
        dirModel = fullfile('../../data/modelData', version_data, 'happiness', happiness_type, block_model_name);
        filename = sprintf('mle_%s_%s_group.mat', happiness_type, block_model_name);
        filename = fullfile(dirModel, filename);
        load(filename);

        param = cbm.model_info.subject.parameter;
        param_baseline = param(:, 1+[1:numel(idx_select)]);
        
        data_reliability{v}.model_happiness.baseline(:,i) = nanmean(param_baseline,2);
        data_reliability{v}.model_happiness.w_p(:,i) = param(:,end-2);
        data_reliability{v}.model_happiness.w_ppe(:,i) = param(:,end-1);
        data_reliability{v}.model_happiness.gamma(:,i) = param(:,1);
        

    end


end

%%%%% combined dense sampling and monthly %%%%%
current_sublist = data_reliability{3}.sublist;
data_reliability{4}.sublist = current_sublist;

% symptoms
list_var = {
    'phq';
    'gad';
    'anhedonia';
    'bami';
    'pc1';
    'pc2'};
nVar = numel(list_var);
for i = 1:nVar
    
    var_name = list_var{i};
    x1 = data_reliability{3}.symptom.(var_name);

    % select from dense sampling
    x2 = NaN(size(x1));
    for s = 1:numel(current_sublist)

        subname = current_sublist{s};
        idx_subject = strcmp(data_reliability{1}.sublist, subname);
        x2(s,:) = data_reliability{1}.symptom.(var_name)(idx_subject,:);

    end

    data_reliability{4}.symptom.(var_name) = (x1+x2)/2;


end

% behavior
list_var = {
    'choice_pGood_average';
    'mean_happiness'};
nVar = numel(list_var);
for i = 1:nVar
    
    var_name = list_var{i};
    x1 = data_reliability{3}.behavior.(var_name);

    % select from dense sampling
    x2 = NaN(size(x1));
    for s = 1:numel(current_sublist)

        subname = current_sublist{s};
        idx_subject = strcmp(data_reliability{1}.sublist, subname);
        x2(s,:) = data_reliability{1}.behavior.(var_name)(idx_subject,:);

    end

    data_reliability{4}.behavior.(var_name) = (x1+x2)/2;

end

% model_choice
list_var = {
    'alpha';
    'rewSen'};
nVar = numel(list_var);
for i = 1:nVar
    
    var_name = list_var{i};
    x1 = data_reliability{3}.model_choice.(var_name);

    % select from dense sampling
    x2 = NaN(size(x1));
    for s = 1:numel(current_sublist)

        subname = current_sublist{s};
        idx_subject = strcmp(data_reliability{1}.sublist, subname);
        x2(s,:) = data_reliability{1}.model_choice.(var_name)(idx_subject,:);

    end

    data_reliability{4}.model_choice.(var_name) = (x1+x2)/2;

end

% model_happiness
list_var = {
    'baseline';
    'w_p';
    'w_ppe';
    'gamma'};
nVar = numel(list_var);
for i = 1:nVar
    
    var_name = list_var{i};
    x1 = data_reliability{3}.model_happiness.(var_name);

    % select from dense sampling
    x2 = NaN(size(x1));
    for s = 1:numel(current_sublist)

        subname = current_sublist{s};
        idx_subject = strcmp(data_reliability{1}.sublist, subname);
        x2(s,:) = data_reliability{1}.model_happiness.(var_name)(idx_subject,:);

    end

    data_reliability{4}.model_happiness.(var_name) = (x1+x2)/2;

end







%%%%%%%%%%%%%%%%%%%%
%%%%% symptoms %%%%%
%%%%%%%%%%%%%%%%%%%%
list_var = {
    'phq';
    'anhedonia';
    'gad';
    'bami';
    'pc1';
    'pc2'};
nVar = numel(list_var);

for v = 1:4
    for i = 1:nVar

        var_name = list_var{i};
        current_data = data_reliability{v}.symptom.(var_name);

        % test-retest reliability
        [rho,pval] = corr(current_data(:,1),current_data(:,2),...
            'type', 'pearson',...
            'rows', 'pairwise');

        % ICC(A,1): absolute agreement
        [icc_val] = ICC(current_data, '2-1');

        % summary
        fprintf('v=%d, %s, r=%.2f, icc=%.2f\n', v, var_name, rho, icc_val);

    end
    fprintf('\n');
end



%%%%%%%%%%%%%%%%%%
%%%%% choice %%%%%
%%%%%%%%%%%%%%%%%%
list_var = {
    'choice_pGood_average'};
nVar = numel(list_var);

for v = 1:4
    for i = 1:nVar

        var_name = list_var{i};
        current_data = data_reliability{v}.behavior.(var_name);

        % test-retest reliability
        [rho,pval] = corr(current_data(:,1),current_data(:,2),...
            'type', 'pearson',...
            'rows', 'pairwise');

        % ICC(A,1): absolute agreement
        [icc_val] = ICC(current_data, '2-1');

        % summary
        fprintf('v=%d, %s, r=%.2f, icc=%.2f\n', v, var_name, rho, icc_val);

    end
    fprintf('\n');
end

%%%%%%%%%%%%%%%%%%%%%
%%%%% happiness %%%%%
%%%%%%%%%%%%%%%%%%%%%
list_var = {
    'mean_happiness'};
nVar = numel(list_var);

for v = 1:4
    for i = 1:nVar

        var_name = list_var{i};
        current_data = data_reliability{v}.behavior.(var_name);

        % test-retest reliability
        [rho,pval] = corr(current_data(:,1),current_data(:,2),...
            'type', 'pearson',...
            'rows', 'pairwise');

        % ICC(A,1): absolute agreement
        [icc_val] = ICC(current_data, '2-1');

        % summary
        fprintf('v=%d, %s, r=%.2f, icc=%.2f\n', v, var_name, rho, icc_val);

    end
    fprintf('\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% model: choice %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%
list_var = {
    'rewSen';
    'alpha'};
nVar = numel(list_var);

for v = 1:4
    for i = 1:nVar

        var_name = list_var{i};
        current_data = data_reliability{v}.model_choice.(var_name);

        % test-retest reliability
        [rho,pval] = corr(current_data(:,1),current_data(:,2),...
            'type', 'pearson',...
            'rows', 'pairwise');

        % ICC(A,1): absolute agreement
        [icc_val] = ICC(current_data, '2-1');

        % summary
        fprintf('v=%d, %s, r=%.2f, icc=%.2f\n', v, var_name, rho, icc_val);

    end
    fprintf('\n');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% model: happiness %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
list_var = {
    'baseline';
    'w_p';
    'w_ppe'};
nVar = numel(list_var);

for v = 1:4
    for i = 1:nVar

        var_name = list_var{i};
        current_data = data_reliability{v}.model_happiness.(var_name);

        % test-retest reliability
        [rho,pval] = corr(current_data(:,1),current_data(:,2),...
            'type', 'pearson',...
            'rows', 'pairwise');

        % ICC(A,1): absolute agreement
        [icc_val] = ICC(current_data, '2-1');

        % summary
        fprintf('v=%d, %s, r=%.2f, icc=%.2f\n', v, var_name, rho, icc_val);

    end
    fprintf('\n');
end









list_var = {
    'choice_pGood_average';
    'mean_happiness'};
nVar = numel(list_var);

for v = 3
    for i = 1:nVar

        var_name = list_var{i};
        fprintf('v=%d, var=%s\n', v, var_name);

        current_data = data_reliability{v}.(var_name);
        [rho,pval] = corr(current_data,...
            'type', 'pearson',...
            'rows', 'pairwise');
        rho

    end
end


list_var = {
    'alpha';
    'rewSen'};
for v = 3
    for i = 1:2

        var_name = list_var{i};
        fprintf('v=%d, var=%s\n', v, var_name);

        current_data = data_reliability{v}.rl_param(:,:,i);
        [rho,pval] = corr(current_data,...
            'type', 'pearson',...
            'rows', 'pairwise');
        rho

    end
end


v = 1;
x1 = nanmean(data_reliability{v}.rl_param(:,[1:2:7],2),2);
x2 = nanmean(data_reliability{v}.rl_param(:,[2:2:7],2),2);
[rho,pval] = corr(x1,x2,...
            'type', 'pearson',...
            'rows', 'pairwise');
rho

v = 2;
x1 = nanmean(data_reliability{v}.rl_param(:,[1:2:6],2),2);
x2 = nanmean(data_reliability{v}.rl_param(:,[2:2:6],2),2);
[rho,pval] = corr(x1,x2,...
            'type', 'pearson',...
            'rows', 'pairwise');
rho

v = 3;
x1 = nanmean(data_reliability{v}.rl_param(:,[1:2:5],2),2);
x2 = nanmean(data_reliability{v}.rl_param(:,[2:2:5],2),2);
[rho,pval] = corr(x1,x2,...
            'type', 'pearson',...
            'rows', 'pairwise');
rho




list_var = {
    'phq';
    'gad';
    'anhedonia';
    'bami';
    'pc1';
    'pc2'};
nVar = numel(list_var);

v = 3;
for i = 1:nVar
    varname = list_var{i};
    x1 = nanmean(data_reliability{v}.(varname)(:,[1:2:end]),2);
    x2 = nanmean(data_reliability{v}.(varname)(:,[2:2:end]),2);
    [rho,pval] = corr(x1,x2,...
        'type', 'pearson',...
        'rows', 'pairwise');
    rho
end


%% supp fig: stability of between-subject association
nPlay_stability = 6;


xData = [];
yData = [];
pca_data = [];
survey_mean = [];
demo = [];
dummy_group = [];

category_subgroup = [];

for v = 1:2

    list_block = list_version{v,2};
    nBlock = numel(list_block);
    nSurvey_max = list_version{v,5};

    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    surveyData = [];
    for i = 1:nSurvey_max
        
        temp_surveyData = [allData{v}.questionnaire.PHQ_item(:,:,i),...
            allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            allData{v}.questionnaire.GAD_item(:,:,i),...
            allData{v}.questionnaire.AMI_behavioral_item(:,:,i)];
        
        surveyData = [surveyData; temp_surveyData];
        
    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;
    
    nSub = size(pca_score_new,1)/nSurvey_max;
    pca_score = NaN(nSub,2);
    for i = 1:2
        temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
        pca_score(:,i) = nanmean(temp_data,2);
    end

    pca_data = [pca_data; pca_score];

    demo = [demo;
        [allData{v}.demographics.age,...
        allData{v}.demographics.gender==1,...
        allData{v}.demographics.education]];
    dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];

    behavior_data = [allData{v}.model_happiness_raw{1}.parameter(:,1+[1:nPlay_stability])]; % baseline mood
    % behavior_data = allData{v}.model_learning{2}.parameter(:,1+[1:nPlay_stability]); % rewSen


    yData = [yData; behavior_data];
end
pc1 = pca_data(:,1);
pc2 = pca_data(:,2);


% dummy_group_residual
[reg_beta] = glmfit(pca_data, dummy_group);
yval = glmval(reg_beta, pca_data, 'identity');
dummy_group_residual = dummy_group - yval;

% pc1_residual
[reg_beta] = glmfit(dummy_group, pc1);
yval = glmval(reg_beta, dummy_group, 'identity');
pc1_residual = pc1 - yval;

% pc2_residual
[reg_beta] = glmfit(dummy_group, pc2);
yval = glmval(reg_beta, dummy_group, 'identity');
pc2_residual = pc2 - yval;



% standardization
xData = [pc1, pc2, pc1_residual, pc2_residual, dummy_group, demo];
nSub = size(xData,1);
xData = (xData - repmat(nanmean(xData,1),nSub,1)) ./ repmat(nanstd(xData,0,1),nSub,1);


% regression
reg_result_all = NaN(nPlay_stability, 3, 3);
for b = 1:nPlay_stability

    yData_select = nanmean(yData(:,1:b),2);

    tbl = array2table([yData_select, xData],...
        'VariableNames',...
        {'yData', 'pc1', 'pc2', 'pc1_residual', 'pc2_residual', 'dummy_group',...
        'age', 'gender', 'education'});

    % model_dummy_pcresidual = fitlm(tbl, 'yData ~ pc1_residual + pc2_residual + dummy_group + age + gender + education')
    %
    % reg_beta = model_dummy_pcresidual.Coefficients.Estimate(2:4);
    % reg_se = model_dummy_pcresidual.Coefficients.SE(2:4);
    % reg_pval = model_dummy_pcresidual.Coefficients.pValue(2:4);
    %
    % for i = 1:3
    %     reg_result_all(b,:,i) = [reg_beta(i), reg_se(i), reg_pval(i)];
    % end

    for i = 1:3
        switch i
            case {1}
                x = tbl.pc1_residual;
            case {2}
                x = tbl.pc2_residual;
            case {3}
                x = tbl.dummy_group;
        end
        [rho,pval] = corr(x, yData_select,...
                    'type', 'spearman',...
                    'rows', 'pairwise');
        reg_result_all(b,:,i) = [rho, NaN, pval];
    end

end



%% check: dissocaition between symptom dimensions and between mood and learning
% current_data = matchData;
current_data = nonmatchData;

param_learning = [];
param_mood = [];
behavior_learning = [];
behavior_mood = [];

pca_data = [];
survey_total = [];
demo = [];
dummy_group = [];

for v = 1:2

    list_block = list_version{v,2};
    nBlock = numel(list_block);
    nSurvey_max = list_version{v,5};

    % survey_total
    survey_total = [survey_total;
        [nanmean(current_data{v}.questionnaire.PHQ_total,2),...
        nanmean(current_data{v}.questionnaire.MASQ_anhedonic_depression,2),...
        nanmean(current_data{v}.questionnaire.GAD_total,2),...
        nanmean(current_data{v}.questionnaire.AMI_behavioral,2)]];

    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    surveyData = [];
    for i = 1:nSurvey_max
        
        temp_surveyData = [current_data{v}.questionnaire.PHQ_item(:,:,i),...
            current_data{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            current_data{v}.questionnaire.GAD_item(:,:,i),...
            current_data{v}.questionnaire.AMI_behavioral_item(:,:,i)];
        
        surveyData = [surveyData; temp_surveyData];
        
    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;
    
    nSub = size(pca_score_new,1)/nSurvey_max;
    pca_score = NaN(nSub,2);
    for i = 1:2
        temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
        pca_score(:,i) = nanmean(temp_data,2);
    end

    pca_data = [pca_data; pca_score];

    demo = [demo;
        [current_data{v}.demographics.age,...
        current_data{v}.demographics.gender==1,...
        current_data{v}.demographics.education]];

    dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];


    behavior_learning = [behavior_learning; nanmean(current_data{v}.behavior.choice_pGood_average,2)];
    behavior_mood = [behavior_mood; nanmean(current_data{v}.behavior.happiness_mean,2)];

    param_learning = [param_learning; current_data{v}.model_learning{1}.parameter]; % alpha, rewSen

    temp_param = [nanmean(current_data{v}.model_happiness_raw{1}.parameter(:,1+list_block),2),...
        current_data{v}.model_happiness_raw{1}.parameter(:,end-2),... % EV
        current_data{v}.model_happiness_raw{1}.parameter(:,end-1)... % RPE
        ];
    param_mood = [param_mood; temp_param];
end
pc1 = pca_data(:,1);
pc2 = pca_data(:,2);


%%%%% all sample %%%%%
[rho,pval] = corr(behavior_learning, behavior_mood, 'type', 'spearman')

[rho,pval] = corr(behavior_learning, param_learning, 'type', 'spearman')
[rho,pval] = corr(behavior_mood, param_mood, 'type', 'spearman')

[rho,pval] = corr(param_learning, param_mood, 'type', 'spearman')

%%%%% depression %%%%%
idx_depression = (dummy_group==1);

[rho,pval] = corr(behavior_learning(idx_depression,:), behavior_mood(idx_depression,:), 'type', 'spearman')

xData = [pc1, pc2, demo];
xData_select = xData(idx_depression,:);

nSub = size(xData_select,1);
xData_select = (xData_select - repmat(nanmean(xData_select,1),nSub,1)) ./ repmat(nanstd(xData_select,0,1),nSub,1);

% regression
tbl = array2table([param_mood(idx_depression,1), param_learning(idx_depression,2), xData_select],...
    'VariableNames',...
    {'baseline_mood', 'rewSen',...
    'pc1', 'pc2',...
    'age', 'gender', 'education'});

model_mood = fitlm(tbl, 'baseline_mood ~ pc1 + pc2 + age + gender + education')
reg_beta = model_mood.Coefficients.Estimate(2:end);
reg_se = model_mood.Coefficients.SE(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]

model_rewSen = fitlm(tbl, 'rewSen ~ pc1 + pc2 + age + gender + education')
reg_beta = model_rewSen.Coefficients.Estimate(2:end);
reg_se = model_rewSen.Coefficients.SE(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]



%%%%% community %%%%%
idx_community = (dummy_group==0);

[rho,pval] = corr(behavior_learning(idx_community,:), behavior_mood(idx_community,:), 'type', 'spearman')

xData = [pc1, pc2, demo];
xData_select = xData(idx_community,:);

nSub = size(xData_select,1);
xData_select = (xData_select - repmat(nanmean(xData_select,1),nSub,1)) ./ repmat(nanstd(xData_select,0,1),nSub,1);

% regression
tbl = array2table([param_mood(idx_community,1), param_learning(idx_community,2), xData_select],...
    'VariableNames',...
    {'baseline_mood', 'rewSen',...
    'pc1', 'pc2',...
    'age', 'gender', 'education'});

model_mood = fitlm(tbl, 'baseline_mood ~ pc1 + pc2 + age + gender + education')
reg_beta = model_mood.Coefficients.Estimate(2:end);
reg_se = model_mood.Coefficients.SE(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]

model_rewSen = fitlm(tbl, 'rewSen ~ pc1 + pc2 + age + gender + education')
reg_beta = model_rewSen.Coefficients.Estimate(2:end);
reg_se = model_rewSen.Coefficients.SE(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% longitudla monthly data %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
v = 3;

%%%%% get pc score %%%%%
nSub = size(longitudinalData{v}.questionnaire.PHQ_total,1);

nSurvey_total = 0;
surveyData = [];

nSurvey_max = list_version{v,5};
nSurvey_total = nSurvey_total + nSurvey_max;

for i = 1:nSurvey_max

    temp_surveyData = [longitudinalData{v}.questionnaire.PHQ_item(:,:,i),...
        longitudinalData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
        longitudinalData{v}.questionnaire.GAD_item(:,:,i),...
        longitudinalData{v}.questionnaire.AMI_behavioral_item(:,:,i)];

    surveyData = [surveyData; temp_surveyData];

end

% apply to questionnaire at different times
pca_coeff = combined_data_coeff;

surveyData_new = surveyData;
surveyData_new = surveyData_new - combined_data_mu;
pca_coeff_new = pca_coeff;
pca_score_new = surveyData_new*pca_coeff_new;

pc1 = reshape(pca_score_new(:,1), nSub, nSurvey_total);
pc2 = reshape(pca_score_new(:,2), nSub, nSurvey_total);

% data
list_block = list_version{v, 2};

% mood
param_mood = longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block);

% rewSen
param_rewSen = longitudinalData{v}.model_learning{2}.parameter(:,1+list_block);


%%%%% average item score %%%%%
survey_mean = [];
for i = 1:nSurvey_max
    survey_mean = [survey_mean;
        [mean(allData{v}.questionnaire.PHQ_item(:,:,i),2),...
        mean(allData{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),2),...
        mean(allData{v}.questionnaire.GAD_item(:,:,i),2),...
        mean(allData{v}.questionnaire.AMI_behavioral_item(:,:,i),2)]];
end
anhedonia_minus_anxiety = survey_mean(:,2)-survey_mean(:,3);

%%%%% combined: mean vs change %%%%
nMonth = size(pc1,2);
list_month = [1:nMonth];
demo = [
    longitudinalData{v}.demographics.age,...
    double(longitudinalData{v}.demographics.gender==1),...
    longitudinalData{v}.demographics.education];

clear xData_combined
list_subno_combined= [];
list_monthno_combined = [];
for m = 1:nMonth

    % select months
    idx_month = m;
    % idx_mean = list_month(list_month~=m);
    idx_mean = list_month;

    % organize data
    pc1_mean = nanmean(pc1(:, idx_mean),2);
    pc2_mean = nanmean(pc2(:, idx_mean),2);
    mood_mean = nanmean(param_mood(:, idx_mean),2);
    rewSen_mean = nanmean(param_rewSen(:, idx_mean),2);

    % residual
    pc1_t = pc1(:, idx_month);
    pc2_t = pc2(:, idx_month);

    [reg_beta, dev, stats] = glmfit(pc2_t, pc1_t);
    pc1_t_residual = stats.resid + reg_beta(1); % residual + constant

    [reg_beta, dev, stats] = glmfit(pc1_t, pc2_t);
    pc2_t_residual = stats.resid + reg_beta(1); % residual + constant


    xData = [
        pc1(:,idx_month),...
        pc2(:,idx_month),...
        pc1_mean, pc1(:,idx_month)-pc1_mean,...
        pc2_mean, pc2(:,idx_month)-pc2_mean,...
        param_mood(:,idx_month), mood_mean, param_mood(:,idx_month)-mood_mean,...
        param_rewSen(:,idx_month), rewSen_mean, param_rewSen(:,idx_month)-rewSen_mean,...
        pc1_t_residual, pc2_t_residual];

    xData = [xData, demo];

    list_subno = [1:size(xData,1)]';
    list_monthno = ones(size(xData,1),1)*m;

    if m==1
        xData_combined = xData;
        list_subno_combined = list_subno;
        list_monthno_combined = list_monthno;
    else
        xData_combined = [xData_combined; xData];
        list_subno_combined = [list_subno_combined; list_subno];
        list_monthno_combined = [list_monthno_combined; list_monthno];
    end

end
xData_combined = [xData_combined, anhedonia_minus_anxiety];


% standarization
xData_zscore = (xData_combined - repmat(nanmean(xData_combined,1),size(xData_combined,1),1)) ./ repmat(nanstd(xData_combined,0,1),size(xData_combined,1),1);

% convert to table
tbl = array2table([xData_combined, list_subno_combined, list_monthno_combined],...
    'VariableNames',...
    {'pc1_t',...
    'pc2_t',...
    'pc1_mean', 'pc1_change',...
    'pc2_mean', 'pc2_change',...
    'mood_t', 'mood_mean', 'mood_change',...
    'rewSen_t', 'rewSen_mean', 'rewSen_change',...
    'pc1_t_residual', 'pc2_t_residual',...
    'age', 'gender', 'education',...
    'anhedonia_minus_anxiety',...
    'subno', 'monthno'});

tbl_zscore = array2table([xData_zscore, list_subno_combined, list_monthno_combined],...
    'VariableNames',...
    {'pc1_t',...
    'pc2_t',...
    'pc1_mean', 'pc1_change',...
    'pc2_mean', 'pc2_change',...
    'mood_t', 'mood_mean', 'mood_change',...
    'rewSen_t', 'rewSen_mean', 'rewSen_change',...
    'pc1_t_residual', 'pc2_t_residual',...
    'age', 'gender', 'education',...
    'anhedonia_minus_anxiety',...
    'subno', 'monthno'});



lme_formula = 'pc1_change ~ pc2_change + age + gender + education + (1 + pc2_change|subno)';
% lme_formula = 'pc2_change ~ pc1_change + age + gender + education + (1 + pc1_change|subno)';
model_pc = fitlme(tbl_zscore, lme_formula)

% lme_formula = 'mood_change ~ rewSen_change + age + gender + education + (1 + rewSen_change|subno)';
lme_formula = 'rewSen_change ~ mood_change + age + gender + education + (1 + mood_change|subno)';
model_param = fitlme(tbl_zscore, lme_formula)


rho_all = NaN(nSub,1);
for s = 1:nSub

    idx_sub = (tbl_zscore.subno==s);
    x1 = tbl_zscore.pc1_change(idx_sub);
    x2 = tbl_zscore.pc2_change(idx_sub);

    rho = corr(x1,x2,...
        'type','spearman',...
        'rows','pairwise');
    rho_all(s) = rho;

end
mean(rho_all)
signrank(rho_all)


rho_all = NaN(nSub,1);
for s = 1:nSub

    idx_sub = (tbl_zscore.subno==s);
    x1 = tbl_zscore.mood_change(idx_sub);
    x2 = tbl_zscore.rewSen_change(idx_sub);

    rho = corr(x1,x2,...
        'type','spearman',...
        'rows','pairwise');
    rho_all(s) = rho;

end
mean(rho_all)
signrank(rho_all)





%% check adherence after message time
current_data = nonmatchData;
% v = 1;
v = 3;

%%%%% message time %%%%%
subject_timegap = current_data{v}.task_timegap;
subject_messageTime = hours(timeofday(current_data{v}.messageTime));
idx_valid = subject_messageTime>=7;

subject_timegap = subject_timegap(idx_valid,:);
subject_messageTime = subject_messageTime(idx_valid,:);



idx_select = (subject_timegap>0 & abs(subject_timegap)<120);
val_adherence = double(idx_select);

avg_timegap = nanmean(subject_timegap,2);
nanmean(avg_timegap)
nanstd(avg_timegap)
hist(avg_timegap)

% adherence: after message, within 1 hour
idx_select = (subject_timegap>0 & abs(subject_timegap)<60);
val_adherence = double(idx_select);

summary_nPlay = sum(val_adherence,2);
figure;
fg = fig_setting_default();
hold on
histogram(summary_nPlay, [-0.5:1:7.5]);
hold off
xlabel('Number of completed plays');
ylabel('Number of participants');
set(gca, 'fontsize', 16, 'linewidth', 2);
set(gca,'Xtick',[0:7]);
xlim([-0.5,7.5]);
ylim([0,80]);

% adherence: within 1 hour
idx_select = (abs(subject_timegap)<60);
val_adherence = double(idx_select);

summary_nPlay = sum(val_adherence,2);
figure;
fg = fig_setting_default();
hold on
histogram(summary_nPlay, [-0.5:1:7.5]);
hold off
xlabel('Number of completed plays');
ylabel('Number of participants');
set(gca, 'fontsize', 16, 'linewidth', 2);
set(gca,'Xtick',[0:7]);
xlim([-0.5,7.5]);
ylim([0,80]);

% adherence: after message, within 2 hours
idx_select = (subject_timegap>0 & abs(subject_timegap)<120);
val_adherence = double(idx_select);

summary_nPlay = sum(val_adherence,2);
figure;
fg = fig_setting_default();
hold on
histogram(summary_nPlay, [-0.5:1:7.5]);
hold off
xlabel('Number of completed plays');
ylabel('Number of participants');
set(gca, 'fontsize', 16, 'linewidth', 2);
set(gca,'Xtick',[0:7]);
xlim([-0.5,7.5]);
ylim([0,80]);

% adherence: within 2 hours
idx_select = (abs(subject_timegap)<120);
val_adherence = double(idx_select);

summary_nPlay = sum(val_adherence,2);
figure;
fg = fig_setting_default();
hold on
histogram(summary_nPlay, [-0.5:1:7.5]);
hold off
xlabel('Number of completed plays');
ylabel('Number of participants');
set(gca, 'fontsize', 16, 'linewidth', 2);
set(gca,'Xtick',[0:7]);
xlim([-0.5,7.5]);
ylim([0,80]);


hist(sum(~isnan(subject_timegap),2))


data_check = [subject_messageTime, subject_timegap];



%%%%% when to play %%%%%
list_bin = [-180, -120, -90, -75, -60, -30, -15, 0, 15, 30, 60, 75, 90, 120, 180];
nBin = numel(list_bin);
data = subject_timegap(:);
data = data(~isnan(data));

summary_p = NaN(nBin-1,1);
list_cutoff = NaN(nBin-1,1);
for i = 1:nBin-1
    
    if i==1
        idx_select = (data>=list_bin(i) & data<=list_bin(i+1));
    else
        idx_select = (data>list_bin(i) & data<=list_bin(i+1));
    end
    
    summary_p(i) = mean(idx_select);
    
    val_cutoff = (list_bin(i)+list_bin(i+1))/2;
    list_cutoff(i) = val_cutoff;
    
end
low_p = mean(data<list_bin(1));
high_p = mean(data>list_bin(end));
summary_p = [low_p; summary_p; high_p];

list_cutoff = [-190; list_cutoff; 190];

figure;
fg = fig_setting_default;
fg.pp(3) = fg.pp(3)*2;
set(gcf,...
    'Position',fg.pp,...
    'PaperPosition', fg.pp,...
    'PaperSize', fg.pp([3:4]));
set(gcf, 'PaperPositionMode', 'Auto');
hold on
plot([0;0],[0;0.25],...
    'linestyle', '--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);
plot([60;60],[0;0.25],...
    'linestyle', '--',...
    'linewidth', 2,...
    'color', [0.5,0.5,0.5]);

plot(list_cutoff, summary_p,...
    'color', [0.2,0.2,0.8],...
    'linewidth', 2,...
    'marker', 'o',...
    'markersize', 12,...
    'markeredgecolor', 'w',...
    'markerfacecolor', 'k');
hold off

set(gca, 'fontsize', 16, 'linewidth', 2);
set(gca, 'XTick', [list_bin]);
xlabel('Minutes after message');
ylabel('p(play is completed)');
xlim([-200,200]);
ylim([0,0.25]);

text(0, 0.26, '1st message',...
    'fontsize', 12,...
    'horizontalalignment', 'center');
text(60, 0.26, '2nd message',...
    'fontsize', 12,...
    'horizontalalignment', 'center');



%%%%% percent of plays within 30min, 60min for participants %%%%%
% val_adherence = double((subject_timegap>0 & abs(subject_timegap)<=30));
% val_adherence = double((abs(subject_timegap)<=30));
% val_adherence = double((subject_timegap>0 & abs(subject_timegap)<=60));
% val_adherence = double((abs(subject_timegap)<=60));
val_adherence = double((subject_timegap>0 & abs(subject_timegap)<=120));
val_adherence(isnan(subject_timegap)) = NaN;
subject_adherence = nanmean(val_adherence,2);
hist(subject_adherence)
val_mean = mean(subject_adherence)
val_sd = std(subject_adherence)



%%%%% timegap after a message %%%%%
message_timegap = subject_timegap;
message_timegap(subject_timegap<0) = NaN;
message_timegap = message_timegap(~isnan(message_timegap));
val_median = nanmedian(message_timegap)
mean((message_timegap<=val_median+15) & (message_timegap>=val_median-15))
mean((message_timegap<=val_median+30) & (message_timegap>=val_median-30))
mean((message_timegap<=val_median+45) & (message_timegap>=val_median-45))
mean((message_timegap<=val_median+60) & (message_timegap>=val_median-60))

mean((message_timegap<=val_median+90) & (message_timegap>=val_median-90))
mean((message_timegap<=val_median+120) & (message_timegap>=val_median-120))






%%%%% between-subject effect %%%%%
param_learning = [];
param_mood = [];
behavior_learning = [];
behavior_mood = [];

pca_data = [];
survey_total = [];
demo = [];
dummy_group = [];

list_block = list_version{v,2};
nBlock = numel(list_block);
nSurvey_max = list_version{v,5};

% survey_total
survey_total = [survey_total;
    [nanmean(current_data{v}.questionnaire.PHQ_total,2),...
    nanmean(current_data{v}.questionnaire.MASQ_anhedonic_depression,2),...
    nanmean(current_data{v}.questionnaire.GAD_total,2),...
    nanmean(current_data{v}.questionnaire.AMI_behavioral,2)]];

% apply to questionnaire at different times
pca_coeff = combined_data_coeff;
surveyData = [];
for i = 1:nSurvey_max

    temp_surveyData = [current_data{v}.questionnaire.PHQ_item(:,:,i),...
        current_data{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
        current_data{v}.questionnaire.GAD_item(:,:,i),...
        current_data{v}.questionnaire.AMI_behavioral_item(:,:,i)];

    surveyData = [surveyData; temp_surveyData];

end
surveyData_new = surveyData;
surveyData_new = surveyData_new - combined_data_mu;
pca_coeff_new = pca_coeff;
pca_score_new = surveyData_new*pca_coeff_new;

nSub = size(pca_score_new,1)/nSurvey_max;
pca_score = NaN(nSub,2);
for i = 1:2
    temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
    pca_score(:,i) = nanmean(temp_data,2);
end

pca_data = [pca_data; pca_score];

demo = [demo;
    [current_data{v}.demographics.age,...
    current_data{v}.demographics.gender==1,...
    current_data{v}.demographics.education]];

dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];


behavior_learning = [behavior_learning; nanmean(current_data{v}.behavior.choice_pGood_average,2)];
behavior_mood = [behavior_mood; nanmean(current_data{v}.behavior.happiness_mean,2)];

param_learning = [param_learning; current_data{v}.model_learning{1}.parameter]; % alpha, rewSen

temp_param = [nanmean(current_data{v}.model_happiness_raw{1}.parameter(:,1+list_block),2),...
    current_data{v}.model_happiness_raw{1}.parameter(:,end-2),... % EV
    current_data{v}.model_happiness_raw{1}.parameter(:,end-1)... % RPE
    ];
param_mood = [param_mood; temp_param];

pc1 = pca_data(:,1);
pc2 = pca_data(:,2);


% select based on adherence after message
nPlay_afterMessage = sum((subject_timegap>0 & abs(subject_timegap)<60), 2);
% nPlay_afterMessage = sum((subject_timegap>0 & abs(subject_timegap)<30), 2);

% idx_select = (nPlay_afterMessage>=3);
idx_select = (nPlay_afterMessage>=2);

% idx_select = ~idx_select;
sum(idx_select)

xData = [pc1, pc2, demo];
xData_select = xData(idx_select,:);

nSub = size(xData_select,1);
xData_select = (xData_select - repmat(nanmean(xData_select,1),nSub,1)) ./ repmat(nanstd(xData_select,0,1),nSub,1);

% regression
tbl = array2table([param_mood(idx_select,1), param_learning(idx_select,2), xData_select],...
    'VariableNames',...
    {'baseline_mood', 'rewSen',...
    'pc1', 'pc2',...
    'age', 'gender', 'education'});

model_mood = fitlm(tbl, 'baseline_mood ~ pc1 + pc2 + age + gender + education')
reg_beta = model_mood.Coefficients.Estimate(2:end);
reg_se = model_mood.Coefficients.SE(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]

model_rewSen = fitlm(tbl, 'rewSen ~ pc1 + pc2 + age + gender + education')
reg_beta = model_rewSen.Coefficients.Estimate(2:end);
reg_se = model_rewSen.Coefficients.SE(2:end);

zval_diff = (reg_beta(1)-reg_beta(2))./sqrt(reg_se(1)^2+reg_se(2)^2);
if zval_diff>0
    pval_diff = 1-cdf('normal',zval_diff,0,1);
else
    pval_diff = cdf('normal',zval_diff,0,1);
end
comp_12_pval = [1,2,pval_diff]




%% adherence X symptom severity
current_data = nonmatchData;

pca_data = [];
study_group = [];
for v = 1:2

    list_block = list_version{v,2};
    nBlock = numel(list_block);
    nSurvey_max = list_version{v,5};

    % apply to questionnaire at different times
    pca_coeff = combined_data_coeff;
    surveyData = [];
    for i = 1:nSurvey_max
        
        temp_surveyData = [current_data{v}.questionnaire.PHQ_item(:,:,i),...
            current_data{v}.questionnaire.MASQ_anhedonic_depression_item(:,:,i),...
            current_data{v}.questionnaire.GAD_item(:,:,i),...
            current_data{v}.questionnaire.AMI_behavioral_item(:,:,i)];
        
        surveyData = [surveyData; temp_surveyData];
        
    end
    surveyData_new = surveyData;
    surveyData_new = surveyData_new - combined_data_mu;
    pca_coeff_new = pca_coeff;
    pca_score_new = surveyData_new*pca_coeff_new;
    
    nSub = size(pca_score_new,1)/nSurvey_max;
    pca_score = NaN(nSub,2);
    for i = 1:2
        temp_data = reshape(pca_score_new(:,i),nSub, nSurvey_max);
        pca_score(:,i) = nanmean(temp_data,2);
    end

    pca_data = [pca_data; pca_score];


    study_group = [study_group; ones(nSub,1)*v];

end
median_pc1 = median(pca_data(:,1));
median_pc2 = median(pca_data(:,2));




v = 2;

pc1 = pca_data(study_group==v,1);
pc2 = pca_data(study_group==v,2);

subject_nPlay = sum(~isnan(allData{v}.behavior.choice_pGood_average),2);
max_play = max(list_version{v,2});

table_summary = NaN(max_play,2);
for i = 1:2
    
    switch i
        case {1}
%             idx_select = pc1<=median_pc1;
            idx_select = pc2<=median_pc2;
        case {2}
%             idx_select = pc1>median_pc1;
            idx_select = pc2>median_pc2;
    end
    
    subject_nPlay_select = subject_nPlay(idx_select,1);
    summary_nPlay = tabulate(subject_nPlay_select);
    table_summary(:,i) = summary_nPlay(:,3);
    
end

figure;
fig_setting_default();
hold on
h = bar(table_summary);
hold off

set(gca, 'fontsize', 16, 'linewidth', 2);
xlabel('Number of completed plays');
ylabel('Proportion of participants (%)');

set(gca,'XTick', [1:max_play]);
xlim([0.5,max_play+0.5]);
ylim([0,100]);

legend(h, {'Low severity', 'High severity'},...
    'location', 'NorthWest',...
    'fontsize', 16);














