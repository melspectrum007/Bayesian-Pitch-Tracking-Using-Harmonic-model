clear
clc
close all;
%% read speech signals
[cleanspeech, samplingFreq] = audioread(['CleanSpeech.wav']);cleanspeech=cleanspeech(:,1);
%% generate noisy data
SNR=0;
noise=randn(size(cleanspeech)); % White Gaussian noise
scaled_noise=addnoise(cleanspeech,noise,SNR);
NoisySignal=cleanspeech+scaled_noise;
%% process the data 
% the third argument is the pre-whitening flag,
% when prew_flag=0,  pre-whitening will be disabled, and 
% when prew_flag=1,  pre-whitening will be enabled
plot_flag=1;
prew_flag=0;
F0_result=BF0NLS(NoisySignal,samplingFreq,plot_flag,prew_flag);





