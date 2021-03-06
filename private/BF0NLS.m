function result=BF0NLS(speechSignal,samplingFreq,plot_flag,prew_flag)
% format of the input and output arguments
% input:
% input arguments --> as the names suggested
% output:
% result.tt         -->     time vector
% result.ff         -->     Fundamental frequency estimates (when all the frames are considered as voiced)
% result.oo         -->     order estimates  (when all the frames are considered as voiced)
% result.vv         -->     voicing probability
% result.best_ff    -->     Best fundamental frequency estimates (setting the F0=nan when voicing probability is less than .5)
% result.best_order -->     Best harmonic order estimates (setting the order=nan when voicing probability is less than .5)

% Written by Liming Shi, Aalborg 9000, Denmark
% Email: ls@create.aau.dk


if nargin<3
%   do not use prewhitening in default, and do not plot
    plot_flag=0;
    prew_flag=0; 
end
if nargin<4
%   do not use prewhitening in default
    prew_flag=0; 
end

%% resample to 16 KHz for the best results
fs_fine_tuned=16000;
speechSignal=resample(speechSignal,fs_fine_tuned,samplingFreq);
samplingFreq=fs_fine_tuned;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% normalization step
sumE = sqrt(speechSignal'*speechSignal/length(speechSignal));
scale = sqrt(3.1623e-5)/sumE; % scale to -45-dB loudness level
speechSignal=speechSignal*scale;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nData = length(speechSignal);

% set up
segmentTime = 0.025; %     seconds
segmentLength = round(segmentTime*samplingFreq/2)*2; % samples
segmentShift = 0.010; % seconds
nShift = round(segmentShift*samplingFreq); % samples
nSegments = floor((nData+segmentLength/2-segmentLength)/nShift)+1;
f0Bounds = [70, 400]/samplingFreq; % cycles/sample
if prew_flag==0
    maxNoHarmonics = 10;
else
    if prew_flag==1
        maxNoHarmonics = 30;
    end
end
f0Estimator = BayesianfastF0NLS(segmentLength, maxNoHarmonics, f0Bounds,2/samplingFreq,.7);
speechSignal_padded=[zeros(segmentLength/2,1);speechSignal];
% do the analysis
idx = 1:segmentLength;
f0Estimates = nan(nSegments,1); % cycles/sample
order=nan(nSegments,1);
voicing_prob=nan(nSegments,1);
if prew_flag==0
    for ii = 1:nSegments
        speechSegment = speechSignal_padded(idx);
        [f0Estimates(ii),order(ii),voicing_prob(ii)]=f0Estimator.estimate(speechSegment,0);
        idx = idx + nShift;
    end
else
    if prew_flag==1
        for ii = 1:nSegments
            speechSegment = speechSignal_padded(idx);
            [f0Estimates(ii),order(ii),voicing_prob(ii)]=f0Estimator.estimate(speechSegment,1,segmentShift);
            idx = idx + nShift;
        end
    end
end


f0Estimates_remove_unvoiced=f0Estimates;
unvoiced_indicator=voicing_prob<.5;;
f0Estimates_remove_unvoiced(unvoiced_indicator)=nan;
order_remove_unvoiced=order;
order_remove_unvoiced(unvoiced_indicator)=nan;
timeVector = [(0:nSegments-1)*segmentShift]';

result.tt=timeVector;
result.ff=f0Estimates*samplingFreq;
result.oo=order;
result.vv=voicing_prob;
result.best_ff=f0Estimates_remove_unvoiced*samplingFreq;
result.best_order=order_remove_unvoiced;
if plot_flag==1
    figure;
    subplot(4,1,4)
    plot([0:length(speechSignal_padded)-1]/samplingFreq,speechSignal_padded/max(abs(speechSignal_padded)));
    xlim([0,(length(speechSignal_padded)-1)/samplingFreq])
    xlabel('Time [s]');
    ylabel('Amplitude');
    subplot(4,1,3)    
%   plot the spectrogram
    window = gausswin(segmentLength);
    nOverlap = segmentLength-nShift;
    nDft = 2048;
    [stft, stftFreqVector] = ...
        spectrogram(speechSignal_padded, window, nOverlap, nDft, samplingFreq);
    powerSpectrum = abs(stft).^2;
    imagesc(timeVector, stftFreqVector, ...
    10*log10(dynamicRangeLimiting(powerSpectrum, 60)));
    axis xy;
    ylim([0,500])
    hold on;
    plot(timeVector, result.best_ff, 'r-', 'linewidth',2);
    ylabel('Frequency [Hz]');
    subplot(4,1,2)    
    plot(timeVector,result.best_order,'r.', 'linewidth',2)
    xlim([timeVector(1),timeVector(end)])
    ylabel('Order estimate')
    subplot(4,1,1)    
    plot(timeVector,result.vv,'r-', 'linewidth',2)
    xlim([timeVector(1),timeVector(end)])
    ylabel('Voicing probability')
end
    
end