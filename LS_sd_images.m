function VI_dW_dp = LS_sd_images(dW_dp, nabla_Ix, nabla_Iy, N_p, h, w)

    if nargin<6 error('Not enough input arguments'); end
    for p=1:N_p		
        Tx = nabla_Ix .* dW_dp(1:h,((p-1)*w)+1:((p-1)*w)+w);
        Ty = nabla_Iy .* dW_dp(h+1:end,((p-1)*w)+1:((p-1)*w)+w);
        VI_dW_dp(:,((p-1)*w)+1:((p-1)*w)+w) = Tx + Ty;
    end
