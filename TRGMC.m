clear all
warning off

displayIntermediateFigures = true;

datapath =  ('.\');
fileName = 'input1.mp4';

initialize;
initializeTRGMC;
denseKeypointMatching;
iterativeUpdates;
display = 0;
createReliabilityMap;
display = 0;
congealLinksBetween;
toc

%%
mkdir('.\TRGMCoutputFiles')
save(['.\TRGMCoutputFiles','\',fileName,'.mat'])

%% Create the Panorama
prepareForPanorama;
renderOutputVideo;

