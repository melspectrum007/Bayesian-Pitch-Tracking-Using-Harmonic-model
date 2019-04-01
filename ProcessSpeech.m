clear
clc
close all;
addpath ./util/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read data from wave file
[cleanspeech, samplingFreq] = audioread(['wb2ext.wav']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Add noise to the data
SNR=0;
noise=addnoise_strict_snr(cleanspeech,randn(size(cleanspeech)),SNR);
speechSignal=cleanspeech+noise;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Data normalization step
sumE = sqrt(speechSignal'*speechSignal/length(speechSignal));
scale = sqrt(3.1623e-5)/sumE; % scale to -45-dB loudness level
speechSignal=speechSignal*scale;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initiate the estimator
nData = length(speechSignal);
segmentTime = 0.025; %     seconds
segmentLength = round(segmentTime*samplingFreq); % samples
segmentShift = 0.010; % seconds
nShift = round(segmentShift*samplingFreq); % samples
nSegments = floor((nData+segmentLength/2-segmentLength)/nShift)+1;
f0Bounds = [70, 400]/samplingFreq; % cycles/sample
maxNoHarmonics = 10;
f0Estimator = BayesianfastF0NLS(segmentLength, maxNoHarmonics, f0Bounds,2/samplingFreq,.7);
speechSignal_padded=[zeros(segmentLength/2,1);speechSignal];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% do the analysis
idx = 1:segmentLength;
f0Estimates = nan(1,nSegments); % cycles/sample
scaled_alpha=nan;
for ii = 1:nSegments
    speechSegment = speechSignal_padded(idx);
    [f0Estimates(ii),order(ii),voicing_prob(ii)]=f0Estimator.estimate(speechSegment,1);    
    idx = idx + nShift;
end
f0Estimates_remove_unvoiced=f0Estimates;
unvoiced_indicator=voicing_prob<.5;
f0Estimates_remove_unvoiced(unvoiced_indicator)=nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot the spectrogram
h=figure;
subplot(313)
timeVector = (0:nSegments-1)*segmentShift+segmentTime/2;
window = gausswin(segmentLength);
nOverlap = round(3*segmentLength/4);
nDft = 2048;
[stft, stftFreqVector, stftTimeVector] = ...
    spectrogram(cleanspeech, window, nOverlap, nDft, samplingFreq);
powerSpectrum = abs(stft).^2;
maxDynamicRange = 60; % dB
imagesc(stftTimeVector, stftFreqVector, ...
    10*log10(dynamicRangeLimiting(powerSpectrum, maxDynamicRange)));
set(gca,'YDir','normal')
hold on
plot(timeVector,f0Estimates_remove_unvoiced*samplingFreq, 'r-', 'linewidth',2);
xlim([min(timeVector),max(timeVector)])
ylim([0,500]);
ylabel('Frequency [Hz]');
xlabel('Time [s]');

%% plot the order estimates
subplot(312)
plot(timeVector,order,'r.')
xlim([min(timeVector),max(timeVector)])
ylabel('Order');
%% plot the voicing probability
subplot(311)
plot(timeVector,voicing_prob,'r-')
xlim([min(timeVector),max(timeVector)])
ylabel('Voicing Probability');






function output_noise=addnoise_strict_snr(sig,input_noise,snr)
noise=input_noise;
noise_std_var=sqrt(10^(-snr/10)*(sig(:)'*sig(:))/(noise(:)'*noise(:)));
output_noise=noise_std_var*noise;
end