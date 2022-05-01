%% PELP.m
% Corrects estimates of loss sizes by forward predicting a harmonic
% regression model from the data preceding the loss.
%
%% Inputs:
%
%   runs        : cell array of continuous runs of data
%   ests        : estimate for each loss length between runs
%   inds        : index corresponding to the beginning of each loss
%   Period      : the period of stimulation (determined used FindPeriodLFP.m)
%   m           : number of sinusoidal components to fit to the artifact
%   unc         : uncertainty in the loss estimates
%% Outputs:
%
%   lossSizes   : corrected loss sizes

function lossSizes = PELP(runs,ests,inds,Period,m,unc)
    runLens=cellfun(@length,runs); % Length of each run
    startTimes=inds-runLens+1; % Start index of each run
    lossSizes=zeros(size(ests));
    % Correct each loss estimate
    for i=1:length(ests)
        % Estimate coefficients using run prior to loss
        [~,B]=lfpreg([(startTimes(i):inds(i))',runs{i}],Period,m);
        mses=zeros(2*unc+1,1);
        % Calculate MSE for harmonic regression model with each possible loss size
        for j=1:length(mses)
            % Generate a model for the run after the loss corresponding to 
            % the current loss size
            model=timeShift((startTimes(i+1):inds(i+1))+(j-unc-1),B,Period,m);
            mses(j)=mean((runs{i+1}-model).^2);
        end
        % Choose the loss size that minimizes MSE
        [~,I]=min(mses);
        lossSizes(i)=ests(i)+I-unc-1;
    end
end

function model = timeShift(t,B,Period,m)
    t = t*(2*pi/Period); % Define periodic time vector
    X = ones(length(t),2*m+1);
    % Initialize sum of sines for time vector
    for j = 1:m
        jt = j*t;
        X(:,2*j) = sin(jt);
        X(:,2*j+1) = cos(jt);
    end
    % Multiply by coefficients
    model=X*B;
end