%% Do an initial match to find the translation between frames
tic
clear transX
clear transY
clear HomoAccu
keyFrames = unique([startF:minStride:endF, endF]);
tau_s = 200; 
distanceThr = 1;

for src = 1:length(keyFrames)
%     pointsACell{src} = detectSURFFeatures(I{keyFrames(src)},'MetricThreshold',tau_s);
%     [featuresACell{src}, pointsACell{src}] = extractFeatures(I{keyFrames(src)}, pointsACell{src}); 
    I = rgb2gray(imresize(read(vidObj, keyFrames(src)), resizeFactor));
    pointsACellInit{src} = detectSURFFeatures(I,'MetricThreshold',tau_s);
    [featuresACellInit{src}, pointsACellInit{src}] = extractFeatures(I, pointsACellInit{src});     
end

findTranslation;

pointsACell= pointsACellInit;
featuresACell= featuresACellInit;      

% findTranslation;

clear pointsACellInit;
clear featuresACellInit;
clear transXAll;
clear transYAll;

for src = 1:length(keyFrames) - 1
    for dst = (src + 1):length(keyFrames)
        temp = sum(transX((src) : (dst - 1)));
        transXAll(keyFrames(src), keyFrames(dst)) = temp(end);
        transXAll(keyFrames(dst), keyFrames(src)) = -transXAll(keyFrames(src), keyFrames(dst));
        temp = sum(transY((src) : (dst - 1)));
        transYAll(keyFrames(src), keyFrames(dst)) = temp(end);
        transYAll(keyFrames(dst), keyFrames(src)) = -transYAll(keyFrames(src), keyFrames(dst));        
    end
end