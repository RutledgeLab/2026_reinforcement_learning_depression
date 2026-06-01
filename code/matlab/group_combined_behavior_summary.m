function group_combined_behavior_summary()

%%%%% list_version %%%%%
% version_data, list_block, list_prob, list_outcome, nSurvey_max
list_version = {
    'depression_denseSampling_remote',      [1:7], [0.75, 0.25], [30,10], 2;
    'community_remote',                     [1:6], [0.75, 0.25], [30,10], 3;
    'depression_monthly_remote',            [1:5], [0.75, 0.25], [30,10], 5;
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
    };
nModel_learning = numel(list_model_learning);


% list_model_happiness
list_model_happiness = {
    'hbi_happy_p_ppe_hbiRL_distSmall_combined'; % pre-fit distSmall RL model on behavior
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
        if v==1
            
            % message check
            allData{v}.messageCheck(s,1) = subjectData.info.messageCheck;
            
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
filename = 'scid_info.mat';
load(filename); % data_scid

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
dataset_name = 'match';
% dataset_name = 'nonmatch';

switch dataset_name
    case {'match'}
        allData = matchData;
    case {'nonmatch'}
        allData = nonmatchData;
end

%%%%% PCA %%%%%
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



%% fig 2: between-subject effect
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

    % survey mean
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


    dummy_group = [dummy_group; ones(nSub,1)*(v-2)*-1];

    category_subgroup = [category_subgroup;
        [allData{v}.demographics.gender,...
        allData{v}.redcap_info.antidepressant,...
        allData{v}.redcap_info.smoke_history,...
        allData{v}.redcap_info.substance_history]];

    behavior_data = [nanmean(allData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2)]; % baseline mood
    % behavior_data = allData{v}.model_learning{1}.parameter(:,2); % rewSen

    yData = [yData; behavior_data];
end
pc1 = pca_data(:,1);
pc2 = pca_data(:,2);

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
            text_pval = 'P<0.001';
        elseif pval_diff<0.01
            text_pval = sprintf('P=%.3f',pval_diff);
        else
            text_pval = sprintf('P=%.2f',pval_diff);
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
fig_file = fullfile(dirFig, sprintf('%s_reg_mood_pca_acrossSubject', dataset_name));
% fig_file = fullfile(dirFig, sprintf('%s_reg_learning_pca_acrossSubject', dataset_name));
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
model_true = fitlme(tbl_zscore, lme_formula);
model_mean = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)');

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
model_true = fitlme(tbl_zscore, lme_formula);
model_mean = fitlme(tbl_zscore, 'pc2_t ~ mood_mean + mood_change + rewSen_mean + age + gender + education + pc1_t + (1 + mood_change + pc1_t|subno)');

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
% RMSE
rmse_state = sqrt(nanmean((all_yhat_state(:)-all_y(:)).^2));
rmse_trait = sqrt(nanmean((all_yhat_trait(:)-all_y(:)).^2));
result_rmse = [rmse_state, rmse_trait]
100*(rmse_trait-rmse_state)/max(result_rmse)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% linear mixed-effect model %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% pc1 %%%%%
model_full = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + mood_change + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_change + rewSen_change + pc2_t|subno)')

model_mood_t = fitlme(tbl_zscore, 'pc1_t ~ mood_t + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_t + rewSen_change + pc2_t|subno)')
model_mood_mean = fitlme(tbl_zscore, 'pc1_t ~ mood_mean + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + rewSen_change + pc2_t|subno)')

model_mood_change = fitlme(tbl_zscore, 'pc1_t ~ mood_change + rewSen_mean + rewSen_change + age + gender + education + pc2_t + (1 + mood_change + rewSen_change + pc2_t|subno)')


% Bayes factor: state vs trait model
bic_best = model_mood_t.ModelCriterion.BIC;
bic_alternative = model_mood_mean.ModelCriterion.BIC;
bayes_factor = exp((bic_alternative-bic_best)/2)


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





%%%%% mood_mean X pc1_mean (quantile) %%%%%
nBin = 20;

x = tbl.mood_mean;

y = tbl.pc1_mean;

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
xlim([0,100]);
ylim([-7,7]);

set(gca,...
    'xtick',[0:25:100],...
    'ytick', [-6:3:6]);

xrange = xlim;
yrange = ylim;
if pval<0.001
    text_rho = sprintf('%.2f', rho);
    text_rho_pval = sprintf('$\\rho=%s$\n$P<0.001$', text_rho);
else
    text_rho = sprintf('%.2f', rho);
    text_pval = sprintf('%.3f', pval);
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

y = tbl.pc2_mean;



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
xlim([-60,0]);
ylim([-2.5,2.5]);

set(gca,...
    'xtick',[-60:20:0],...
    'ytick', [-2:1:2]);

xrange = xlim;
yrange = ylim;
if pval<0.001
    text_rho = sprintf('%.2f', rho);
    text_rho_pval = sprintf('$\\rho=%s$\n$P<0.001$', text_rho);
else
    text_rho = sprintf('%.2f', rho);
    text_pval = sprintf('%.3f', pval);
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

y = tbl.pc1_t - tbl.pc1_mean;

x = reshape(x,[],nMonth);
y = reshape(y,[],nMonth);

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
        text_pval = 'P<0.001';
    elseif pval_diff<0.01
        text_pval = sprintf('P=%.3f',pval_diff);
    else
        text_pval = sprintf('P=%.2f',pval_diff);
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

xlim([0.5,2.5]);
ylim([0,2]);
set(gca,'YTick',[0:0.5:2]);
set(gca,'XTick',[1,2],'XTickLabel',{'Decrease', 'Increase'});

% output figure
fig_file = fullfile(dirFig, 'monthly_moodChange_pc1Change_bar');
print(fig_file, '-dpdf');



%%%%% rewSen_change X pc2_change (bar) %%%%%
x = tbl.rewSen_change;

y = tbl.pc2_t - tbl.pc2_mean;

x = reshape(x,[],nMonth);
y = reshape(y,[],nMonth);

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

xlim([0.5,2.5]);
ylim([-0.4,0.4]);
set(gca,'YTick',[-0.4:0.2:0.4]);
set(gca,'XTick',[1,2],'XTickLabel',{'Decrease', 'Increase'});

fig_file = fullfile(dirFig, 'monthly_rewSenChange_pc2Change_bar');
print(fig_file, '-dpdf');







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

    
    scid_mde = current_mde+past_mde;
    dummy_group = [dummy_group; scid_mde];

    behavior_data = [nanmean(longitudinalData{v}.model_happiness_raw{1}.parameter(:,1+list_block),2)];
    % behavior_data = longitudinalData{v}.model_learning{1}.parameter(:,2);
    

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







