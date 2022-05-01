%% PELP_LFP.m
% Runs PELP on a combinedDataTable from analysis-rcs-data
%
%% Inputs:
%
%   tbl         : the table of LFP data to correct
%   Period      : the period of stimulation (determined used FindPeriodLFP.m)
%   m           : number of sinusoidal components to fit to the artifact
%   unc         : uncertainty in the loss estimates
%   channel     : name of the channel in the table to use for correction
%% Outputs:
%
%   newtbl      : new table with corrected loss sizes

function newtbl = PELP_LFP(tbl,Period,m,unc,channel)
    lfp=tbl.(channel);
    lossMat=isnan(lfp); % Mark losses as True
    S=regionprops(lossMat,'Area'); % Gets you information on each loss region
    ests=[S.Area]; % Estimated length of each loss
    dataInds=find(~lossMat); % Indices for received data
    idx=find(diff(dataInds)~=1); % Starting indices for each continuous run
    As=[idx(1);diff(idx);numel(dataInds)-idx(end)];  
    inds=dataInds([idx;numel(dataInds)]);
    runs=mat2cell(lfp(~lossMat),As,1); % Continuous runs in each cell
    lossSizes=PELP(runs,ests,inds,Period,m,unc); % Apply PELP to timeseries
    % Find the sampling rate
    fs=rmmissing(tbl.TD_samplerate);
    fs=fs(1);
    % Correct the derived times
    derivedTimes=tbl.DerivedTime(1)+[0;cumsum(1000/fs*ones(sum(As)+sum(lossSizes)-1,1))];
    % Correct the local times
    localTimes=tbl.localTime(1)+milliseconds(derivedTimes-derivedTimes(1));
    newtbl=table();
    newtbl.localTime=localTimes;
    newtbl.DerivedTime=derivedTimes;
    % Correct all remaining columns using updated loss sizes
    for i=3:width(tbl)
        cname=tbl.Properties.VariableNames{i};
        runs=mat2cell(table2array(tbl(~lossMat,i)),As,1);
        newcol=nan(sum(As)+sum(lossSizes),1);
        ind=1;
        % Put all runs in the right spots
        for r=1:length(lossSizes)
            newcol(ind:ind+length(runs{r})-1)=runs{r};
            ind=ind+length(runs{r})+lossSizes(r);
        end
        newcol(ind:end)=runs{end};
        newtbl.(cname)=newcol;
    end
end