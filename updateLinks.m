

Homo{currentF} = (eye(3) + reshape([delta_p',0], 3, 3)); %* Homo{src};
HomoAccu{currentF} = Homo{currentF} * HomoAccu{currentF};

% HomoAccu{currentF} = HomoAccu{currentF} * Homo{currentF}; %%%%????????????
%%
U = linksListOrg{currentF}(:,2);
V = linksListOrg{currentF}(:,3);
[X, Y] = transformPointsForward(projective2d(HomoAccu{currentF}), U, V);
linksList{currentF}(:,2) = X;
linksList{currentF}(:,3) = Y;

%%
for dst = dstFArray 
    if(size(linksListOrg{dst}, 1))
        connectedTo = linksListOrg{dst}(:,1);
        indices = (connectedTo == currentF);
        U = linksListOrg{dst}(indices,4);
        V = linksListOrg{dst}(indices,5);
        [X, Y] = transformPointsForward(projective2d(HomoAccu{currentF}), U, V);
        linksList{dst}(indices,4) = X;
        linksList{dst}(indices,5) = Y;    
    end
end

errV{currentF} = sum(((linksList{currentF}(:,2) - linksList{currentF}(:,4)).^2 + (linksList{currentF}(:,3) - linksList{currentF}(:,5)).^2).^.5);

