%% Add necessary libraries
addpath('C:\Users\Evan\Documents\GitHub\PARRM')
addpath('C:\Users\Evan\Documents\GitHub\Analysis-rcs-data\code')
%% Correct using analysis-rcs-data pipeline
% Other tables can be included if desired
[unifiedDerivedTimes, timeDomainData, ~, ~, ~, ~, ~, ~, ~, ~,...
    ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, metaData] = ProcessRCS('E:\PELP\sample_data',2,1);
dataStreams = {timeDomainData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);
%% Apply PELP
fs=rmmissing(combinedDataTable.TD_samplerate); % Determine the sampling rate
fs=fs(1);

% The code below is used to find the longest run for period finding or to
% split data at losses in a desired way
losses=isnan(combinedDataTable.TD_key0);
losses=diff(losses);
regions=diff([1;find(losses);length(losses)]); % Sections of data and losses
contLengths=regions(1:2:end); % Continuous lengths of data
lossLens=regions(2:2:end); % The estimated length of all losses
segEnds=cumsum(contLengths)+[0;cumsum(lossLens)]+1; % The end of each continuous segment
segEnds(end)=segEnds(end)+1; 
segStarts=[1;cumsum(contLengths(1:end-1))+cumsum(lossLens)+2]; % The start of each continuous segment

% The commented code can be used if you wish to only apply PELP for losses
% less than a chosen length

% maxLen=6;
% longLossInds=[0;find(lossLens/fs>maxLen);length(lossLens)+1];
% tables=cell(length(longLossInds)-1,1);
% len=0;
% for i=1:length(tables)
%     tables{i}=combinedDataTable(segStarts(longLossInds(i)+1):segEnds(longLossInds(i+1)),:);
%     len=len+height(tables{i});
% end

stimFreq=150.6; % Stimulation frequency for the sample data
[~,I]=max(contLengths);
longestRun=combinedDataTable.TD_key0(segStarts(I):segEnds(I));

% Find the period
Period=FindPeriodLFP(longestRun,[1,length(longestRun)-1],fs/stimFreq);
% Apply PELP using the first column (TD_key0)
m=2; % Number of sinusoidal components to fit
uncertainty=3; % Uncertainty in the loss estimates
newtbl = PELP_LFP(combinedDataTable,Period,m,uncertainty,"TD_key0");

%% Compute new runs
lossesNew=isnan(newtbl.TD_key0);
lossesNew=diff(lossesNew);
regionsNew=diff([1;find(lossesNew);length(lossesNew)]); % Sections of data and losses
contLengthsNew=regionsNew(1:2:end); % Continuous lengths of data
lossLensNew=regionsNew(2:2:end); % The estimated length of all losses
segEndsNew=cumsum(contLengthsNew)+[0;cumsum(lossLensNew)]+1; % The end of each continuous segment
segEndsNew(end)=segEndsNew(end)+1; 
segStartsNew=[1;cumsum(contLengthsNew(1:end-1))+cumsum(lossLensNew)+2]; % The start of each continuous segment

%% Plot results (first nseg runs for clarity)
nseg=80;
diffOld=diff(combinedDataTable.TD_key0(segStarts(1):segEnds(nseg)));
timesOld=find(~isnan(diffOld));
artifactOld = diffOld(timesOld)-lfpreg([timesOld,diffOld(timesOld)],Period,2);
[timesOld,I] = sort(mod(timesOld,Period));
artifactOld = artifactOld(I);
diffNew=diff(newtbl.TD_key0(segStartsNew(1):segEndsNew(nseg)));
timesNew=find(~isnan(diffNew));
artifactNew = diffNew(timesNew)-lfpreg([timesNew,diffNew(timesNew)],Period,2);
[timesNew,I] = sort(mod(timesNew,Period));
artifactNew = artifactNew(I);
%load('cmap')
figure
subplot(1,2,1)
hold on
for i=1:nseg
    scatter(mod(segStarts(i):segEnds(i)-1,Period),diff(combinedDataTable.TD_key0(segStarts(i):segEnds(i))),'MarkerEdgeColor',cmap(i,:))
end
plot(timesOld,artifactOld,'b','LineWidth',2)
axis tight
ylim([-0.03,0.03])
title('Raw Data')
xlabel('Sample in Period')
ylabel('Amplitude (mV)')
subplot(1,2,2)
hold on
for i=1:nseg
    scatter(mod(segStartsNew(i):segEndsNew(i)-1,Period),diff(newtbl.TD_key0(segStartsNew(i):segEndsNew(i))),'MarkerEdgeColor',cmap(i,:))
end
plot(timesNew,artifactNew,'b','LineWidth',2)
axis tight
ylim([-0.03,0.03])
title('PELP Corrected')
xlabel('Sample in Period')