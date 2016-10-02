% Initialization of robust matching
conf.method = 'VFC';
if ~exist('conf', 'var'), conf = []; end
conf = VFC_init(conf);

% Get video object and calculate resize factor for speed-up
filename = strcat(datapath, fileName);
vidObj = VideoReader(filename);

resizeFactorX = 640 / vidObj.width;
resizeFactorY = 640 / vidObj.Height;
resizeFactor = min(1, min(resizeFactorX, resizeFactorY));

% Settings
removeTranslationFirst = true;
W_F = 1;
W_B = 1;
backwardForward = true;
justBackward = false; 
if (backwardForward)
    justBackward = false;
end

count = 0;
startF = 1;
endF = vidObj.NumberOfFrames;
% stride = 20;
[height, width] = size(rgb2gray(imresize(read(vidObj, startF), resizeFactor)));
minStride = 10;

tau1 = 0.0005
T_M = 300;
phi = .005;
gamma = 10e4;
