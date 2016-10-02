try
    close(writerObj)
    open(writerObj)
end

figure(1)
clear Iw;
se = strel('disk',5); 
red = double([255 0 0]); 
shapeInserter = vision.ShapeInserter('Shape','Rectangles','BorderColor','Custom','CustomBorderColor',red);

for src = keyFrames(1):1:keyFrames(end)
    try
        initH2{src};
    catch
        initH2{src} = eye(3);
    end
    if (size(initH2{src},1) == 0)
        initH2{src} = eye(3);
    end

    if (resizeFactor ~= 1)
        Im = (imresize(read(vidObj, src), resizeFactor));
    else
        Im = (read(vidObj, src));
    end    
    
    ImForOverlay = imresize(Im, max(160/size(Im, 2), (maxX-minX)/(10*size(Im, 2)) ) );
    
    if (norm(HomoAccu{src}) > 10000)
        HomoAccu{src} = eye(3);
    end
    
    finalH{src} = initH{src} * initH2{src} * HomoAccu{src} * avgHInv;% * diag(0.001*src^.7*(rand(1,3)-0.5)+1);
    Imw = imwarp(Im, projective2d(finalH{src}), 'OutputView',tempref);    

    figure(1)
    
    [U, V] = transformPointsForward(projective2d(finalH{src}), [1, width, width, 1], [1 1 height height]);
    borderP = roipoly(zeros(size(Imw, 1), size(Imw, 2)), U - tempref.XWorldLimits(1) , V - tempref.YWorldLimits(1));           
    
    temp = borderP > 0;                    
    erodedTemp = imerode(temp,se);
    erodedTemp = repmat(erodedTemp, [1, 1, 3]);
    overlaid(erodedTemp(:)) = Imw(erodedTemp(:)); 

    imshow(overlaid / 255);  
    title(['Frame = ', num2str(src)])
    drawnow   
    
    if (scale ~= 1)
        overlaidResized = imresize(overlaid, scale);
        ImwResized = imresize(Imw, scale);
    else
        overlaidResized = overlaid;
        ImwResized = Imw;
    end
    overlaidResized(overlaidResized < 0) = 0;
    overlaidResized(overlaidResized > 255) = 255;
    writeVideo(writerObj, overlaidResized / 255);
end
close(writerObj)   
save(['.\TRGMCoutputFiles','\finalH_',fileName,'.mat'])
