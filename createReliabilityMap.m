errorThr = 1;
sigmaCoef = min(width, height)/15;
[xq,yq] = meshgrid(1:1:width, 1:1:height);

eps = .005;

for src = (1 + justBackward) : length(keyFrames)
    %%
    
    currentF = keyFrames(src);
%     indices = (linksListOrg{currentF}(:,1) == keyFrames(src+1));
    indices = 1:length(linksListOrg{currentF}(:,1));
    U = linksListOrg{currentF}(indices,2) + transXAll(keyFrames(1), keyFrames(src));
    V = linksListOrg{currentF}(indices,3) + transYAll(keyFrames(1), keyFrames(src));
    Ws = weightsOrg{currentF}(indices);
    deltaX = abs(linksList{currentF}(indices,2)-linksList{currentF}(indices,4));
    deltaY = abs(linksList{currentF}(indices,3)-linksList{currentF}(indices,5));
%     relibale_indices2 = (deltaX+deltaY) < errorThr;
%     U = U(indices2);
%     V = V(indices2);
%     Ws = Ws(indices2);    
    
    relibale_indices2 = [];
    extraweight = [];
    [C,ia,ic] = unique(round(U));
    for i=1:length(ia)
        tempind = find(ic == i);
        if(sum(deltaX(tempind))+sum(deltaY(tempind)) < errorThr)
            relibale_indices2 = [relibale_indices2,i];
            extraweight = [extraweight,length(tempind)];
        end
    end
    U = U(ia);
    V = V(ia);
    newWeight = double(zeros(size(xq(:))));
    
%     for jj = 1:length(U)
%         if (newWeight(sub2ind(size(xq),round(V(jj)),round(U(jj)))) < 1)
%             newWeight = newWeight + gaussC(double(xq(:)), double(yq(:)), sigmaCoef * Ws(jj), [U(jj),V(jj)]);
%         end
%     end
    
    for kk = 1:length(relibale_indices2)
        jj = relibale_indices2(kk);
        if (newWeight(sub2ind(size(xq),round(V(jj)),round(U(jj)))) < 5)
            %newWeight = newWeight + 10*(extraweight(kk)/length(keyFrames))*gaussC(double(xq(:)), double(yq(:)), sigmaCoef * Ws(jj), [U(jj),V(jj)]);
            newWeight = newWeight + gaussC(double(xq(:)), double(yq(:)), sigmaCoef * Ws(jj), [U(jj),V(jj)]);
        end
    end

    z = (newWeight);
    z(z > 1) = 1;
    z(z < eps) = eps;
    reliabalityForw{src} = reshape(z, [size(xq,1),size(xq,2)]);
    
    if (display)
        figure(222);
        % imshow(double(rgb2gray(imresize(read(vidObj, currentF), resizeFactor))).*reliabalityForw{src}/255)
        sc(cat(3,reliabalityForw{src}, double(rgb2gray(imresize(read(vidObj, currentF), resizeFactor)))),'prob_jet',[0,1]);
        drawnow
    end
% % %     currentF = keyFrames(src+1);
% % % %     indices = (linksListOrg{currentF}(:,1) == keyFrames(src));
% % %     indices = 1:length(linksListOrg{currentF}(:,1));
% % %     U = linksListOrg{currentF}(indices,2);
% % %     V = linksListOrg{currentF}(indices,3);
% % %     Ws = weightsOrg{currentF}(indices);
% % %     deltaX = abs(linksList{currentF}(indices,2)-linksList{currentF}(indices,4));
% % %     deltaY = abs(linksList{currentF}(indices,3)-linksList{currentF}(indices,5));
% % %     indices2 = (deltaX+deltaY) < errorThr;
% % %     U = U(indices2);
% % %     V = V(indices2);
% % %     Ws = Ws(indices2);    
% % % 
% % %     newWeight = zeros(size(xq(:)));
% % %     for jj = 1:length(U)
% % %         newWeight = newWeight + gaussC(double(xq(:)), double(yq(:)), sigmaCoef * Ws(jj), [U(jj),V(jj)]);
% % %     end
% % % 
% % %     z = double(newWeight);
% % %     z(z>1) = 1;  
% % %     reliabalityBack{src+1} = reshape(z, [size(xq,1),size(xq,2)]);
    
    
%     figure
%     imagesc(reliabality{src});    
end


% vq = griddata(double(U),double(V), z,xq,yq);
% 
% 
% 
% 
% figure
% mesh(xq,yq,vq);
% hold on
% plot3(U,V,z,'o');



