avgHInv = eye(3);

replayStride = 1;

clear tforms
extraTrans = eye(3);
extraTrans(3,1) = 100;
extraTrans(3,2) = 100;

src = keyFrames(1);
H1 = HomoAccuBest{src};
src = keyFrames(1);
H2 = HomoAccuBest{src};

equalizer = inv(0.5 * H1 + 0.5 * H2);
avgHInv = equalizer * extraTrans;

for src = keyFrames
    try
        initH2{src};
    catch
        initH2{src} = eye(3);
    end
    if (size(initH2{src},1) == 0)
        initH2{src} = eye(3);
    end

    tforms{src} = initH{src} * HomoAccuBest{src} * avgHInv;
end
[minX, minY, maxX, maxY] = findCanvasSize(tforms, [height, width]);
if (maxX - minX > 4000)
    maxX = maxX * 4000/(maxX - minX);
    minX = minX * 4000/(maxX - minX);
end
if (maxY - minY > 4000)
    maxY = maxY * 4000/(maxY - minY);
    minY = minY * 4000/(maxY - minY);
end

tempref = imref2d(double(round([(abs(maxY-minY)+1),(abs(maxX-minX)+1)])));
tempref.XWorldLimits = [minX maxX];
tempref.YWorldLimits = [minY maxY]; 

try
    close(writerObj)   
end


mkdir('.\TRGMCOutputVideo')
writerObj = VideoWriter(['.\TRGMCOutputVideo\ov_',fileName],'MPEG-4'); 
writerObj.FrameRate = vidObj.FrameRate;
open(writerObj)



figure(1)

src = keyFrames(1);
Iw{src} = imwarp(rgb2gray(imresize(read(vidObj, src), resizeFactor)), projective2d(initH{src} * HomoAccuBest{src} * avgHInv), 'OutputView',tempref);


Im = (imresize(read(vidObj, 1), resizeFactor));
Imw = imwarp(Im, projective2d(eye(3)), 'OutputView',tempref);    
overlaid = zeros(size(Imw));
ImForOverlay = imresize(Im, max(160/size(Im, 2), (maxX-minX)/(10*size(Im, 2)) ) );

diffI = zeros(size(Iw{keyFrames(1)}));
borderPprev = zeros(size(Iw{keyFrames(1)}));
Iw{keyFrames(1)} = diffI;
se = strel('disk', 5);  

scaleY = 1086 / (maxY-minY);
scaleX = 1918 / (maxX-minX);
scale = min([1, scaleX, scaleY]);

s1 = size(overlaid, 1) - 10 - size(ImForOverlay, 1);
s2 = size(overlaid, 1) - 11;
s3 = 10;
s4 = s3-1+size(ImForOverlay, 2);
polygon = [s3 s1 s4-s3+1 s2-s1+1];

