clear initH2

for i =  1 : length(keyFrames)-1       
    strF = keyFrames(i);
    endF = keyFrames(i+1);
    disp(['Congleaing links between frames ',num2str(strF),' & ',num2str(endF)]) 
    
    %% Find and match key-points for each smaller patch
       
    
%     pointsB1 = detectSURFFeatures(I{strF},'MetricThreshold',tau_s);
%     [featuresB1, pointsB1] = extractFeatures(I{strF}, pointsB1);
% 
%     pointsB2 = detectSURFFeatures(I{endF},'MetricThreshold',tau_s);
%     [featuresB2, pointsB2] = extractFeatures(I{endF}, pointsB2);    
    for src = strF+1 : endF-1
        
%         pointsAOrg = detectSURFFeatures(I{src},'MetricThreshold',tau_s);
%         [featuresA, pointsAOrg] = extractFeatures(I{src}, pointsAOrg);  
        I = rgb2gray(imresize(read(vidObj, src), resizeFactor));
        pointsAOrg = detectSURFFeatures(I,'MetricThreshold',tau_s);
        
        [featuresA, pointsAOrg] = extractFeatures(I, pointsAOrg);    
        for dst = [strF, endF]
            if (~((src == strF) & (dst == endF)))
                links{src}{dst} = [];
                links{dst}{src} = [];
                
                if (dst == strF)
                    pointsB = pointsACell{i};
                    featuresB = featuresACell{i};
                else
                    pointsB = pointsACell{i+1};
                    featuresB = featuresACell{i+1};
                end

                indexPairs = matchFeatures(featuresA, featuresB,'MatchThreshold',70);

                pointsA = pointsAOrg(indexPairs(:, 1), :);
                pointsB = pointsB(indexPairs(:, 2), :);

                if (size(pointsA,1) > 10)
                    try
                        filterMatches;
                    end
                end                
                
                % Use average of two landmarks
                xTrans = (transXAll(keyFrames(1), strF) + transXAll(keyFrames(1), endF))/2;
                yTrans = (transYAll(keyFrames(1), strF) + transYAll(keyFrames(1), endF))/2;
                HFrozenAvg = eye(3);%(HomoAccu{strF} + HomoAccu{endF})/2;                
                
                [U, V] = transformPointsForward(projective2d(HFrozenAvg), pointsA.Location(:,1) - xTrans, pointsA.Location(:,2) - yTrans);
                links{src}{dst}(:, 1:2) = [U, V];
                if (dst == strF)
                    [U, V] = transformPointsForward(projective2d(HomoAccu{strF}), pointsB.Location(:,1) - transXAll(keyFrames(1), strF), pointsB.Location(:,2) - transYAll(keyFrames(1), strF));
                    links{src}{dst}(:, 3:4)= [U, V]; 
                    xInd = floor(pointsB.Location(:,1)); xInd(xInd<1) = 1;
                    yInd = floor(pointsB.Location(:,2)); yInd(yInd<1) = 1;
                    try
                        reliability{src}{dst} = reliabalityForw{i}(sub2ind(size(reliabalityForw{i}), yInd, xInd));
                    catch
                        reliability{src}{dst} = ones(size(xInd));
                    end
                else %(dst == endF)
                    [U, V] = transformPointsForward(projective2d(HomoAccu{endF}), pointsB.Location(:,1) - transXAll(keyFrames(1), endF), pointsB.Location(:,2) - transYAll(keyFrames(1), endF));
                    links{src}{dst}(:, 3:4)= [U, V];     
                    links{src}{dst}(:, 3:4)= [U, V]; 
                    xInd = floor(pointsB.Location(:,1)); xInd(xInd<1) = 1;
                    yInd = floor(pointsB.Location(:,2)); yInd(yInd<1) = 1;
                    try
                        reliability{src}{dst} = reliabalityForw{i+1}(sub2ind(size(reliabalityForw{i}), yInd, xInd));                    
                    catch
                        reliability{src}{dst} = ones(size(xInd));
                    end                        
                end
                
                % no need for this, uni-directional links
%                 links{dst}{src}(:, 1:2) = links{src}{dst}(:, 3:4);
%                 links{dst}{src}(:, 3:4) = links{src}{dst}(:, 1:2);

                Homo{src} = eye(3);
                HomoAccu{src} = eye(3);
                initH{src} = (initH{strF} + initH{endF})/2;
                initH2{src} = HFrozenAvg;
            end
        end
    end

    for src = strF+1:endF-1
        linksList{src} = [];
        weights{src} = [];
        for dst = [strF, endF]
            linksList{src} = [linksList{src} ; [repmat(dst, size(links{src}{dst}, 1), 1), links{src}{dst}]];          
            %%%% weights{src} = 1 * ones(2 * size(linksList{src}, 1), 1);            
            weights{src} = [weights{src} ; reliability{src}{dst}];
%             size(weights{src}) - size(ones(2 * size(linksList{src}, 1), 1))
        end
        linksListOrg{src} = linksList{src};
    end
    
    %%
    color = 'ykmbcrg';
    for src = strF+1:endF-1
        %%
        ind = src;
        if (display)
            figure(1000);subplot(211);cla;hold on
            d = size(linksList{ind}, 1);
            for ii = 1:size(linksList{ind}, 1)
                c = linksListOrg{ind}(ii, 1);
%                 l = max(.01, (2 - (weights{src}(ii, 1) + weights{src}(d+ii, 1)))) * 5;
                l = 1;
                line(linksList{ind}(ii,[2, 4]), height-linksList{ind}(ii,[3,5]),'Color', color(mod(c,6)+1),'LineWidth',l)
                plot(linksList{ind}(ii,[4]), height-linksList{ind}(ii,[5]),'.','Color', color(mod(c,7)+1))
                title(['Frame ', num2str(src), ', Before'])
            end 
            drawnow  
        end
        for itr = 1:100
            currentF = src;
            congealLinks; 
            dstFArray = []; %no update is needed, links from source to locked landmarks are unidirectional
            updateLinks;    
            errV{src} = sum((linksList{currentF}(:,2) - linksList{currentF}(:,4)).^2 + (linksList{currentF}(:,3) - linksList{currentF}(:,5)).^2);
            if (norm(delta_p) < 10e-4)
                break;
            end
%             figure(1000);subplot(212);cla;hold on
%             for ii = 1:size(linksList{ind}, 1)
%                 c = linksList{ind}(ii, 1);
%                 l = max(.01, (2 - (weights{src}(ii, 1) + weights{src}(d+ii, 1)))) * 0.1;
%                 l = 1;
%                 line(linksList{ind}(ii,[2, 4]), linksList{ind}(ii,[3,5]),'Color', color(mod(c,6)+1),'LineWidth',l)
%                 plot(linksList{ind}(ii,[4]), linksList{ind}(ii,[5]),'.','Color', color(mod(c,7)+1))
%             end   
%             drawnow             
        end    
        if (display)
            figure(1000);subplot(212);cla;hold on
            for ii = 1:size(linksList{ind}, 1)
                c = linksList{ind}(ii, 1);
                l = 1;
                line(linksList{ind}(ii,[2, 4]), height-linksList{ind}(ii,[3,5]),'Color', color(mod(c,6)+1),'LineWidth',l)
                plot(linksList{ind}(ii,[4]), height-linksList{ind}(ii,[5]),'.','Color', color(mod(c,7)+1))
                title(['Frame ', num2str(src), ', After'])
            end   
            drawnow           
        end
    end
    
end

