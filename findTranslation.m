for src = 1:length(keyFrames) - 1
    for dst = (src + 1)
%         [src, dst]
                      
        pointsA = pointsACellInit{src};%detectSURFFeatures(I{keyFrames(src)},'MetricThreshold',tau_s);
        pointsB = pointsACellInit{dst};%detectSURFFeatures(I{keyFrames(dst)},'MetricThreshold',tau_s);

        featuresA = featuresACellInit{src};
        featuresB = featuresACellInit{dst};

        indexPairs = matchFeatures(featuresA, featuresB,'MatchThreshold',50);

        pointsA = pointsA(indexPairs(:, 1), :);
        pointsB = pointsB(indexPairs(:, 2), :);         
        
        %% Robust matching
        if (size(pointsA,1) > 10)
            try
                filterMatches;
            catch
                'error in filtering'
%                 filterMatches;
            end
        end
        %%        
               
        transX(src) = mean([pointsB.Location(:,1) - pointsA.Location(:,1)]);% + (rand(1,1)-0.5)*width/8;  %%%%%%%%
        transY(src) = mean([pointsB.Location(:,2) - pointsA.Location(:,2)]);          
    end   
end