    [nX, nY, normal]=norm2(pointsA.Location, pointsB.Location);

    % Ourlier removal       
    switch conf.method
        case 'VFC'
            VecFld=VFC(nX, nY-nX, conf);
        case 'FastVFC'
            VecFld=FastVFC(nX, nY-nX, conf);
        case 'SparseVFC'
            VecFld=SparseVFC(nX, nY-nX, conf);
    end

    %figure;quiver(nX(:,1),nX(:,2),nY(:,1)-nX(:,1),nY(:,2)-nX(:,2))
    %figure;quiver(nX(:,1),nX(:,2),VecFld.V(:,1),VecFld.V(:,2))
    
    % Denormalization
    VecFld.V=(VecFld.V+nX)*normal.yscale+repmat(normal.ym,size(pointsA,1),1) - pointsA.Location;
    CorrectIndex = VecFld.VFCIndex; 

%         theme = 'ymcrgkbwymcrgkbwymcrgkbw';  
%         figure(11); 
%         subplot(211);cla;showMatchedFeatures(I{src}, I{dst}, pointsA, pointsB, 1,'PlotOptions', {'ro', 'g+', theme(1)});    
%         subplot(212);cla;showMatchedFeatures(I{src}, I{dst}, pointsA(CorrectIndex), pointsB(CorrectIndex), 1,'PlotOptions', {'ro', 'g+', theme(1)});    

    pointsA = pointsA(CorrectIndex, :);
    pointsB = pointsB(CorrectIndex, :);  