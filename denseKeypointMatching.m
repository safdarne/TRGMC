
%% Match keypoints
clear links
clear linksList
clear transNormd
clear mutualWeights
total = 0;

for src = 1:length(keyFrames)-1
    for dst = (src + 1):length(keyFrames)
        %%
        if ((abs(transXAll(keyFrames(src), keyFrames(dst))) < width * distanceThr) & ...
            (abs(transYAll(keyFrames(src), keyFrames(dst))) < height * distanceThr))    

            total = total + 1;

            if (transXAll(keyFrames(src), keyFrames(dst)) > 0)            
                dstRangeX(1) = transXAll(keyFrames(src), keyFrames(dst));
                dstRangeX(2) = width;
                srcRangeX(1) = 1;
                srcRangeX(2) = width - transXAll(keyFrames(src), keyFrames(dst));
            else
                dstRangeX(1) = 1;
                dstRangeX(2) = width - -transXAll(keyFrames(src), keyFrames(dst));
                srcRangeX(1) = -transXAll(keyFrames(src), keyFrames(dst));
                srcRangeX(2) = width;
            end
            
            if (transYAll(keyFrames(src), keyFrames(dst)) > 0)            
                dstRangeY(1) = transYAll(keyFrames(src), keyFrames(dst));
                dstRangeY(2) = height;
                srcRangeY(1) = 1;
                srcRangeY(2) = height - transYAll(keyFrames(src), keyFrames(dst));
            else
                dstRangeY(1) = 1;
                dstRangeY(2) = height - -transYAll(keyFrames(src), keyFrames(dst));
                srcRangeY(1) = -transYAll(keyFrames(src), keyFrames(dst));
                srcRangeY(2) = height;
            end            
                
            pointsA = pointsACell{src};
            pointsB = pointsACell{dst};
            
            indAX = srcRangeX(1) < pointsA.Location(:,1)  & pointsA.Location(:,1) < srcRangeX(2); 
            indAY = srcRangeY(1) < pointsA.Location(:,2)  & pointsA.Location(:,2) < srcRangeY(2); 
            pointsA = pointsA(indAX & indAY, :);
            
            indBX = dstRangeX(1) < pointsB.Location(:,1)  & pointsB.Location(:,1) < dstRangeX(2); 
            indBY = dstRangeY(1) < pointsB.Location(:,2)  & pointsB.Location(:,2) < dstRangeY(2);             
            pointsB = pointsB(indBX & indBY, :);
            
            featuresA = featuresACell{src}(indAX & indAY, :);
            featuresB = featuresACell{dst}(indBX & indBY, :);
            indexPairs = matchFeatures(featuresA, featuresB,'MatchThreshold',30);

            pointsA = pointsA(indexPairs(:, 1), :);
            pointsB = pointsB(indexPairs(:, 2), :);
            
            if (size(pointsA,1) > 10)
                try
                    filterMatches;
                end
            end
            
            
            theme = 'ymcrgkbwymcrgkbwymcrgkbw';    
            indices = pointsA.Metric > 0;%(mean(pointsA.Metric) + 0 * std(pointsA.Metric));
            % indices = [1,8,25,40, 50, 70, 55, 43];
            pointsA2 = pointsA(indices,:);
            pointsB2 = pointsB(indices,:);
            dist = (abs(pointsA2.Location(:,1) - pointsB2.Location(:,1) + transXAll(keyFrames(src), keyFrames(dst))).^2 + abs(pointsA2.Location(:,2) - pointsB2.Location(:,2) + transYAll(keyFrames(src), keyFrames(dst))).^2).^.5;
            thr = mean(dist) + 0 * std(dist);
            indices(dist > thr) = 0;
            pointsA2 = pointsA(indices,:);
            pointsB2 = pointsB(indices,:);

            if (displayIntermediateFigures)
                figure(11); cla;showMatchedFeatures(rgb2gray(imresize(read(vidObj, keyFrames(src)), resizeFactor)), rgb2gray(imresize(read(vidObj, keyFrames(dst)), resizeFactor)), pointsA2, pointsB2, 'PlotOptions', {'ro', 'g+', theme(1)});    
                hold on;
                plot([srcRangeX(1),srcRangeX(2),srcRangeX(2),srcRangeX(1),srcRangeX(1)], ...
                    [srcRangeY(1),srcRangeY(1),srcRangeY(2),srcRangeY(2),srcRangeY(1)], 'r', 'linewidth',2)

                plot([dstRangeX(1),dstRangeX(2),dstRangeX(2),dstRangeX(1),dstRangeX(1)], ...
                    [dstRangeY(1),dstRangeY(1),dstRangeY(2),dstRangeY(2),dstRangeY(1)], 'b', 'linewidth',2)
                
                title(['Matching frames ', num2str(keyFrames(src)), ' & ', num2str(keyFrames(dst))])
            end
            
            if (~justBackward)
                links{keyFrames(src)}{keyFrames(dst)}(:, 1:2) = pointsA2.Location;
                links{keyFrames(src)}{keyFrames(dst)}(:, 3:4) = pointsB2.Location;
            end
            links{keyFrames(dst)}{keyFrames(src)}(:, 1:2) = pointsB2.Location;
            links{keyFrames(dst)}{keyFrames(src)}(:, 3:4) = pointsA2.Location;
            mutualWeights{keyFrames(src)}{keyFrames(dst)} = min(pointsA2.Scale, pointsB2.Scale)/max(max(pointsA2.Scale, pointsB2.Scale));
            mutualWeights{keyFrames(dst)}{keyFrames(src)} = mutualWeights{keyFrames(src)}{keyFrames(dst)};
        end
    end    
end
links{keyFrames(end)}{keyFrames(end)} = {};

%%
clear weights   
clear initH
linksTransd = links;
% Move the links according to the translations found
for src = 1:length(keyFrames)   
    for dst = 1:length(keyFrames)
        if (src ~= dst)
            if ((justBackward & dst < src) | (~justBackward))
                % do this only if frames have enough overlap, otherwise it is
                % most probably unreliable frame matching
                if ((abs(transXAll(keyFrames(src), keyFrames(dst))) < width * distanceThr) & ...
                    (abs(transYAll(keyFrames(src), keyFrames(dst))) < height * distanceThr))  
                    if (size(links{keyFrames(src)}{keyFrames(dst)}, 1) > 0)
                        linksTransd{keyFrames(src)}{keyFrames(dst)}(:, 1) = links{keyFrames(src)}{keyFrames(dst)}(:, 1) - transXAll(keyFrames(1), keyFrames(src));
                        linksTransd{keyFrames(src)}{keyFrames(dst)}(:, 2) = links{keyFrames(src)}{keyFrames(dst)}(:, 2) - transYAll(keyFrames(1), keyFrames(src));
                        linksTransd{keyFrames(src)}{keyFrames(dst)}(:, 3) = links{keyFrames(src)}{keyFrames(dst)}(:, 3) - transXAll(keyFrames(1), keyFrames(dst));
                        linksTransd{keyFrames(src)}{keyFrames(dst)}(:, 4) = links{keyFrames(src)}{keyFrames(dst)}(:, 4) - transYAll(keyFrames(1), keyFrames(dst));
                    end
                else
                    linksTransd{keyFrames(src)}{keyFrames(dst)} = [];
                    mutualWeights{keyFrames(src)}{keyFrames(dst)} = [];
                    disp([num2str(keyFrames(src)), ',', num2str(keyFrames(dst)), ' not enough overlap'])
                end
            end
        end
    end    
end
