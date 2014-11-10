%% Visualize the EEG 
% The reporting function expects that EEG will be in the base workspace
% with an EEG.etc.noisyParameters structure containing the report. It
% also expects a variable called sumReportName in the base workspace
% which contains the file name of a summary report. 
% The reporting function appends a summary to this report. 

%% Open the summary report file
summaryReportLocation = [summaryFolder filesep summaryReportName];
summaryFile = fopen(summaryReportLocation, 'a+', 'n', 'UTF-8');
relativeReportLocation = [sessionFolder filesep sessionReportName];
%% Output the report header
summaryHeader = [EEG.etc.noisyParameters.name '[' ...
    num2str(size(EEG.data, 1)) ' channels, ' num2str(size(EEG.data, 2)) ' frames]'];
fprintf('%s...\n', summaryHeader);
summaryHeader = [summaryHeader ' <a href="' relativeReportLocation ...
    '">Report details</a>'];
writeSummaryHeader(summaryFile,  summaryHeader);
writeSummaryItem(summaryFile, '', 'first');
%% Setup visualization parameters
numbersPerRow = 15;
indent = '  ';
headColor = [0.7, 0.7, 0.7];
elementColor = [0, 0, 0];
showColorbar = true;
scalpMapInterpolation = 'v4';
noisyParameters = EEG.etc.noisyParameters;
original = noisyParameters.reference.noisyOutOriginal;
referenced = noisyParameters.reference.noisyOut;

[originalLocations, originalInformation, originalChannels] = ...
        getReportChannelInformation(original);
[referencedLocations, referencedInformation, referencedChannels] = ...
        getReportChannelInformation(referenced);
referenceChannels = noisyParameters.reference.referenceChannels;
%% Report high pass filtering step
summary = reportHighPass(1, noisyParameters, numbersPerRow, indent);
writeSummaryItem(summaryFile, summary);

%% Report line noise removal step
summary = reportLineNoise(1, noisyParameters, numbersPerRow, indent);
writeSummaryItem(summaryFile, summary);

%% Spectrum after line noise removal
channels = noisyParameters.lineNoise.lineNoiseChannels;
tString = noisyParameters.name;
showSpectrum(EEG, channels, tString);

%% Report rereferencing step parameters
summary = reportRereference(1, noisyParameters, numbersPerRow, indent);
writeSummaryItem(summaryFile, summary);

%% Scalp map of robust channel deviation (original)
tString = 'Robust channel deviation';
dataOriginal = original.robustChannelDeviation;
dataReferenced = referenced.robustChannelDeviation;
scale = max(max(abs(dataOriginal), max(abs(dataReferenced))));
clim = [-scale, scale];

nosedir = originalInformation.nosedir;
plotScalpMap(dataOriginal, originalLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(original)'])

%% Scalp map of robust channel deviation (referenced)
nosedir = referencedInformation.nosedir;
plotScalpMap(dataReferenced, referencedLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(referenced)'])

%% Scalp map of HF noise Z-score (original)
tString = 'Z-score HF SNR';
dataOriginal = original.zscoreHFNoise;
dataReferenced = referenced.zscoreHFNoise;
scale = max(max(abs(dataOriginal), max(abs(dataReferenced))));
clim = [-scale, scale];

nosedir = originalInformation.nosedir;
plotScalpMap(dataOriginal, originalLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(original)'])

%% Scalp map of HF noise Z-score (referenced)
nosedir = referencedInformation.nosedir;
plotScalpMap(dataReferenced, referencedLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(referenced)'])

%% Scalp map of median max correlation (original)
tString = 'Median max correlation';
dataOriginal = original.medianMaxCorrelation;
dataReferenced = referenced.medianMaxCorrelation;
clim = [0, 1];

nosedir = originalInformation.nosedir;
plotScalpMap(dataOriginal, originalLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(original)'])

%% Scalp map of median max correlation (referenced)
nosedir = referencedInformation.nosedir;
plotScalpMap(dataReferenced, referencedLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(referenced)'])
 
%% Scalp map of bad ransac fraction (original)
tString = 'Ransac fraction failed';
dataOriginal = original.ransacBadWindowFraction;
dataReferenced = referenced.ransacBadWindowFraction;
clim = [0, 1];

nosedir = originalInformation.nosedir;
plotScalpMap(dataOriginal, originalLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(original)'])
%% Scalp map of bad ransac fraction (referenced)
nosedir = referencedInformation.nosedir;
plotScalpMap(dataReferenced, referencedLocations, scalpMapInterpolation, ...
    showColorbar, headColor, elementColor, clim, nosedir, [tString '(referenced)'])
 
  
%% Channels with bad noise levels before and after reference
legendStrings = {'Before referencing', 'After referencing'};
beforeNoise = original.noiseLevels(referenceChannels, :);
beforeNoise = sum(beforeNoise >= original.highFrequencyNoiseThreshold);
afterNoise = referenced.noiseLevels(referenceChannels, :);
afterNoise = sum(afterNoise >= referenced.highFrequencyNoiseThreshold);
beforeTimeScale = (0:length(beforeNoise)-1)*original.correlationWindowSeconds;
afterTimeScale = (0:length(afterNoise)-1)*referenced.correlationWindowSeconds;
thresholdName = 'HF noise threshold';
showBadWindows(beforeNoise, afterNoise, beforeTimeScale, afterTimeScale, ...
     length(referenceChannels), legendStrings, noisyParameters.name, thresholdName);
              
%% Channels with large robust deviation before and after reference
beforeDeviation = original.channelDeviations(referenceChannels, :);
beforeDeviation = sum(beforeDeviation >= original.robustDeviationThreshold);
afterDeviation = referenced.channelDeviations(referenceChannels, :);
afterDeviation = sum(afterDeviation >= referenced.robustDeviationThreshold);
beforeTimeScale = (0:length(beforeDeviation)-1)*original.correlationWindowSeconds;
afterTimeScale = (0:length(afterDeviation)-1)*referenced.correlationWindowSeconds;
thresholdName = 'robust amplitude threshold';
showBadWindows(beforeDeviation, afterDeviation, beforeTimeScale, afterTimeScale, ...
      length(referenceChannels), legendStrings, noisyParameters.name, thresholdName);
              
%% Channels with low median max correlation before and after reference
beforeCorrelation = original.maximumCorrelations(referenceChannels, :);
beforeCorrelation = sum(beforeCorrelation < original.correlationThreshold);
afterCorrelation = referenced.maximumCorrelations(referenceChannels, :);
afterCorrelation = sum(afterCorrelation < referenced.correlationThreshold);
beforeTimeScale = (1:length(beforeCorrelation))*original.correlationWindowSeconds;
afterTimeScale = (1:length(afterCorrelation))*referenced.correlationWindowSeconds;
thresholdName = 'median max correlation threshold';
showBadWindows(beforeCorrelation, afterCorrelation, beforeTimeScale, afterTimeScale, ...
   length(referenceChannels), legendStrings, noisyParameters.name, thresholdName);
%% Channels with poor ransac correlations before and after reference
beforeRansac = original.ransacCorrelations(referenceChannels, :);
beforeRansac = sum(beforeRansac < original.ransacCorrelationThreshold);
afterRansac = referenced.ransacCorrelations(referenceChannels, :);
afterRansac = sum(afterRansac < referenced.ransacCorrelationThreshold);
beforeTimeScale = (1:length(beforeRansac))*original.ransacWindowSeconds;
afterTimeScale = (1:length(afterRansac))*referenced.ransacWindowSeconds;
thresholdName = 'ransac correlation threshold';
showBadWindows(beforeRansac, afterRansac, beforeTimeScale, afterTimeScale, ...
      length(referenceChannels), legendStrings, noisyParameters.name, thresholdName);

%% Comparison of noisy average reference and robust average reference
tString = { noisyParameters.name, 'Comparison of reference signals'}; 
figure('Name', tString{2})
plot(noisyParameters.reference.averageReference, ...
     noisyParameters.reference.averageReferenceWithNoisyChannels, '.k');
xlabel('Robust reference')
ylabel('Noisy reference');
title(tString, 'Interpreter', 'None');

%% Comparison of noisy average reference and robust average reference
tString = { noisyParameters.name, 'noisy - robust reference signals'}; 
t = length(noisyParameters.reference.averageReference)/EEG.srate;
figure('Name', tString{2})
plot(noisyParameters.reference.averageReferenceWithNoisyChannels - ...
     noisyParameters.reference.averageReference, '.k');
xlabel('seconds')
ylabel('Difference');
title(tString, 'Interpreter', 'None');

%% Close the summary file
writeSummaryItem(summaryFile, '', 'last');
fclose(summaryFile);