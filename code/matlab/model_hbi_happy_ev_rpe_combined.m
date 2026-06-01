function [LL, model_var] = model_hbi_happy_ev_rpe_combined(param, data, idx_free, param_default, isSim)

if nargin<5
    isSim = 0;
end

nBlock = numel(data);

% parameter
idx_param = 0;

idx_param = idx_param + 1;
if idx_free(idx_param)==1
    nd_gamma = param(idx_param);
    gamma = 1/(1+exp(-nd_gamma)); % [0,1]
else
    gamma = param_default(idx_param);
end

b0_block = NaN(1,nBlock);
for b = 1:nBlock
    idx_param = idx_param + 1;
    if idx_free(idx_param)==1
        nd_b0_block = param(idx_param);
        b0_block(b) = 100/(1+exp(-nd_b0_block)); % [0,100]
    else
        b0_block(b) = param_default(idx_param);
    end
end

idx_param = idx_param + 1;
if idx_free(idx_param)==1
    b_ev = param(idx_param);
else
    b_ev = param_default(idx_param);
end

idx_param = idx_param + 1;
if idx_free(idx_param)==1
    b_pe = param(idx_param);
else
    b_pe = param_default(idx_param);
end

idx_param = idx_param + 1;
if idx_free(idx_param)==1
    nd_sd_residual = param(idx_param);
    sd_residual = exp(nd_sd_residual);
    sd_residual = sd_residual + 0.001; % [0.001, inf]
else
    sd_residual = param_default(idx_param);
end


LL = 0;
for b = 1:nBlock

    b0 = b0_block(b);

    % data
    rating_happiness_data = data{b}.rating_happiness_data;
    rating_trialno = data{b}.rating_trialno;
    trial_ev = data{b}.trial_ev;
    trial_pe = data{b}.trial_pe;

    nTrial = numel(trial_ev);

    if isempty(rating_trialno) & isSim==0
        model_var{b} = data{b};

        model_var{b}.rating_happiness_pred = [];
        model_var{b}.rating_happiness_residual = [];

        model_var{b}.trial_happiness_pred = NaN(nTrial,1);

        model_var{b}.sse = NaN;

        continue

    else

        influence_mtx = NaN(nTrial,1);
        for t = 1:nTrial

            influence_mtx(t) = b_ev*trial_ev(t) + b_pe*trial_pe(t);

            if t~=1
                influence_mtx(t) = influence_mtx(t) + gamma*influence_mtx(t-1);
            end

        end
        trial_happiness_pred = b0 + influence_mtx;

        % add noise if simulation
        if isSim==1
            trial_happiness_pred = trial_happiness_pred + randn(size(trial_happiness_pred))*sd_residual;
        end

        rating_happiness_pred = trial_happiness_pred(rating_trialno);

        % sse
        rating_happiness_residual = rating_happiness_data - rating_happiness_pred;
        sse = sum(rating_happiness_residual.^2); %sum least-squares error
        LL = sum(log(normpdf(rating_happiness_residual, 0, sd_residual))) + LL;

        % model_var
        model_var{b} = data{b};

        model_var{b}.rating_happiness_pred = rating_happiness_pred;
        model_var{b}.rating_happiness_residual = rating_happiness_residual;

        model_var{b}.trial_happiness_pred = trial_happiness_pred;
        
        model_var{b}.sse = sse;

    end

end

