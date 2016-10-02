%% Iterative Updates
for src = 1:length(keyFrames)
    linksList{keyFrames(src)} = [];
    weights{keyFrames(src)} = [];
    for dst = 1:length(keyFrames)
        if (backwardForward)
            if (keyFrames(src) ~= keyFrames(dst))
                linksList{keyFrames(src)} = [linksList{keyFrames(src)} ; [repmat(keyFrames(dst), size(linksTransd{keyFrames(src)}{keyFrames(dst)}, 1), 1), linksTransd{keyFrames(src)}{keyFrames(dst)}]];
                if (src < dst)
                    % Forward
                    weights{keyFrames(src)} = [weights{keyFrames(src)}; W_F * mutualWeights{keyFrames(src)}{keyFrames(dst)}];
                else
                    % Backward
                    weights{keyFrames(src)} = [weights{keyFrames(src)}; W_B * mutualWeights{keyFrames(src)}{keyFrames(dst)}];
                end
            end
        else
            if ((justBackward & dst < src) | (~justBackward))
                if (keyFrames(src) ~= keyFrames(dst))
                    linksList{keyFrames(src)} = [linksList{keyFrames(src)} ; [repmat(keyFrames(dst), size(linksTransd{keyFrames(src)}{keyFrames(dst)}, 1), 1), linksTransd{keyFrames(src)}{keyFrames(dst)}]];
                    weights{keyFrames(src)} = [weights{keyFrames(src)}; 1 * mutualWeights{keyFrames(src)}{keyFrames(dst)}];
                end
            end
        end
    end
    Homo{keyFrames(src)} = eye(3);
    HomoAccu{keyFrames(src)} = eye(3);  
    initH{keyFrames(src)} = eye(3);
    initH{keyFrames(src)}(3,1) = -transXAll(keyFrames(1), keyFrames(src));
    initH{keyFrames(src)}(3,2) = -transYAll(keyFrames(1), keyFrames(src));    
    initH2{keyFrames(src)} = eye(3);
end

linksListOrg = linksList;
weightsOrg = weights;
%% Reset

N_p = 8;
gamma = 5 * width * height;%10e4;
linksList = linksListOrg;
for src =  1 : length(keyFrames)
    Homo{keyFrames(src)} = eye(3);
    HomoAccu{keyFrames(src)} = eye(3);  
end

weights = weightsOrg;

%
imgB = rgb2gray(imresize(read(vidObj, keyFrames(1)), resizeFactor));%I{keyFrames(1)};
posSpanX = 2.2; % Sum of absolute of posSpanX and negSpanX should not exceed 4
negSpanX = -1.2;
posSpanY = 2.2; % Sum of absolute of posSpanY and negSpanY should not exceed 2.26
negSpanY = -1.2; %0:1 gives the original canvas
tempref = imref2d(([round((posSpanY-negSpanY) * size(imgB,1)),round((posSpanX-negSpanX) * size(imgB,2))]));
tempref.XWorldLimits = [negSpanX * size(imgB,2) posSpanX * size(imgB,2)];
tempref.YWorldLimits = [negSpanY * size(imgB,1) posSpanY * size(imgB,1)]; 

totalErr = 0;
for src = (1 + justBackward) : length(keyFrames)
    totalErr = totalErr + sum((linksList{keyFrames(src)}(:,2) - linksList{keyFrames(src)}(:,4)).^2 + (linksList{keyFrames(src)}(:,3) - linksList{keyFrames(src)}(:,5)).^2);
end


itr = 0;
currentsrc = 2;

tic
%%
for itr = 1:T_M
    %%
    avgH = zeros(3,3);
    avgHAccu = zeros(3,3);
    
    totalErr(itr + 1) = 0;
    totalNorm = 0;
    for src = (1 + justBackward) : length(keyFrames)
        currentsrc = src;
        currentF = keyFrames(src);
        errV{currentF} = 0;
        if (justBackward)
            dstFArray = keyFrames([src+1:length(keyFrames)]);
        else
            dstFArray = keyFrames([1:src-1, src+1:length(keyFrames)]); 
        end
        
        congealLinks;
        totalNorm = totalNorm + norm(delta_p.*[1 1 0 1 1 0 1 1]');
        updateLinks; 
        totalErr(itr + 1) = totalErr(itr + 1) + errV{currentF};        
    end    
    
    if (itr > 1)
        if (totalErr(itr + 1) < min(totalErr(1:itr)))
            HomoAccuBest = HomoAccu;
            bestItr = itr;
        else
            disp('Diverging...')
        end
    else
        HomoAccuBest = HomoAccu;
    end
    
    if (itr > 5 & totalNorm < (10e-4*length(keyFrames)))
        disp(['Break at iteratoin ', num2str(itr), ', Norm = ', num2str(totalNorm)])
        break;
    else
        disp(['%%%%%%%%%%%%%%%%%%%%%%% itr = ', num2str(itr), ', Norm = ', num2str(totalNorm)])
    end
    figure(1127);subplot(211);semilogy(totalErr(1:itr+1))
    title(['Itr',num2str(itr), ', Error = ', num2str(totalErr(itr+1))])
end
toc
HomoAccu = HomoAccuBest;
