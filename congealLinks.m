xArr1 = linksList{currentF}(:,2);
yArr1 = linksList{currentF}(:,3);
xArr2 = linksList{currentF}(:,4);                
yArr2 = linksList{currentF}(:,5);    
errx = abs(xArr1 - xArr2);
erry = abs(yArr1 - yArr2);

thrX = max(1, mean(errx) + 3 * (1/itr)^0.1 * std(errx));
thrY = max(1, mean(erry) + 3 * (1/itr)^0.1 * std(erry));

% dist = (errx.^2 + erry.^2).^.5;
% clusters = kmeans(dist, 2);
% if (mean(dist(clusters == 1)) < mean(dist(clusters == 2)))
%     indices = clusters == 1;
% else
%     indices = clusters == 2;
% end

indices = (errx < thrX  & erry < thrY);
% indices = ones(size(indices));

d  = sum(indices);
xArr1 = xArr1(indices);
xArr2 = xArr2(indices);
yArr1 = yArr1(indices);
yArr2 = yArr2(indices);

H = zeros(N_p, N_p);

SD = zeros(N_p, 1);
Jac_proj = zeros(4 * d, 8);
robust = [weights{currentF}(indices);weights{currentF}(indices)].^1;%%%ones(2 * d, 1);
% robust = ones(2 * d, 1);

err = zeros(2 * d, 1);
nabla_Tx = zeros(2 * d, 1);
nabla_Ty = zeros(2 * d, 1);

errNegClip = -500;
errPosClip = 500;

% matrix version for speed up
Jac_proj(1:d, 1:8) = [xArr1 yArr1 ones(d,1) zeros(d,1) zeros(d,1) zeros(d,1) -xArr1.*xArr2 -yArr1.*xArr2];
Jac_proj(d+1:2*d, 1:8) = [xArr1 yArr1 ones(d,1) zeros(d,1) zeros(d,1) zeros(d,1) -xArr1.*xArr2 -yArr1.*xArr2];
Jac_proj(2*d + 1:3*d, 1:8) = [zeros(d,1) zeros(d,1) zeros(d,1) xArr1 yArr1 ones(d,1) -xArr1.*yArr2 -yArr1.*yArr2];  
Jac_proj(3*d + 1:4*d, 1:8) = [zeros(d,1) zeros(d,1) zeros(d,1) xArr1 yArr1 ones(d,1) -xArr1.*yArr2 -yArr1.*yArr2]; 
err(1:d, 1) = min(max(xArr2 - xArr1, errNegClip), errPosClip);
err(d+1:2*d, 1) = min(max(yArr2 - yArr1, errNegClip), errPosClip);

% robust(1:2*d, 1) = phi^0*exp(-phi * err.^2);
nabla_Tx(1:d, 1) = 1;
nabla_Tx(d+1:2*d, 1) = 0;
nabla_Ty(1:d, 1) = 0;
nabla_Ty(d+1:2*d, 1) = 1;        
%%
lamb = mean(abs(err)) + std(abs(err)); 
lambda = max(10, lamb^2);

w = 1; h = 2 * d;
p_0 = zeros(size(3,3));  p_0(3,3) = 1;

% 5) Compute steepest descent images, VT_dW_dp
VI_dW_dp = LS_sd_images(Jac_proj, nabla_Tx, nabla_Ty, N_p, h, w);            

H = zeros(N_p, N_p);

for ii=1:N_p
    h1 = VI_dW_dp(:,((ii-1)*w)+1:((ii-1)*w)+w);
    for m=1:N_p
        h2 = VI_dW_dp(:,((m-1)*w)+1:((m-1)*w)+w);
        H(m, ii) = sum(sum((h1 .* robust .* h2)));
    end
end


%%
H = H;
limitDelta = [1 1 0 1 1 0 1 1]';
% H_inv = pinv(H + 2 * gamma * limitDelta * limitDelta');

H_inv = pinv(H + gamma * diag(limitDelta));


sd_delta_p = zeros(N_p, 1);
for k = 1   
    for p=1:N_p
        h1 = VI_dW_dp(:,((p-1)*w)+1:((p-1)*w)+w);
        sd_delta_p(p) = sd_delta_p(p) + sum(sum(h1 .* robust .* err));
    end
end

delta_p = H_inv * sd_delta_p;                             
%         avgDelta = avgDelta + delta_p{j}'; 
%% weights -> f
% temp = err * err';
% eeDiag = temp(sub2ind(size(temp),1:size(temp,1),1:size(temp,2)));

weights{currentF}([indices]) = weights{currentF}([indices]).^.7;

% eeDiag = err.^2;
% 
% weights{currentF}([indices,indices],1) = 1 - eeDiag/(2*lambda);
% weights{currentF}([~indices,~indices],1) = 0;
% weights{currentF}(weights{currentF} < 0) = 0;
% weights{currentF}(weights{currentF} > 1) = 1;


% % 
% %%
% kk = 1; % 1 -> -5, 5 cut off
% % kk = 1000;x = -10:.1:10;figure(6);plot(x, .5 + .5 * 1./(1+ exp(-kk *x)))
% 
% weights{currentF} = zeros(size(weights{currentF}));
% 
% gamma = 10e5;
% temp2 = exp(-kk * weights{currentF});
% weights2 = 0.5 ./ (1  + temp2) + 0.5;
% F = diag(weights2);
% FInv = diag(weights2.^-1);
% temp = err * err';
% 
% Z = (temp - gamma * eye(size(F))) * diag(0.5 * kk * temp2 ./ ((1 + temp2) .^2));
% delta_f = -inv(Z) * (err' * F * err + gamma * sum(1 - weights{currentF}));
% delta_f = delta_f(sub2ind(size(delta_f),1:size(delta_f,1),1:size(delta_f,2)));
% 
% 
% % newW = 0.5 / (1  + exp(-kk * (weights{currentF} + delta_f))) + 0.5;
% figure(6);plot(delta_f)
% % weights{currentF} = weights{currentF} + delta_F(sub2ind(size(delta_F),1:size(delta_F,1),1:size(delta_F,2)));
% 
% % temp2 = exp(-kk * (weights{currentF} + delta_f'));
% % weights2 = 0.5 / (1  + temp2) + 0.5;
% % figure(6);plot(weights2,'.')
