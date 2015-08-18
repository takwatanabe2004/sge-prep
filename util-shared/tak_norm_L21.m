function L21norm = tak_norm_L21(W)
%% L21norm = tak_norm_L21(W)
%==============================================================================%
% Compute L21norm of matrix W
% (compute L2-norm of each rows in W, and add them up)
% (so 2-norm over the rows, and 1-norm of the resultance column vector)
%------------------------------------------------------------------------------%
%==============================================================================%
% 08/18/2015
%%
% L21norm_brute = 0;
% for i=1:nrow
% %     W(i,:)
%     norm(W(i,:))
%     L21norm_brute = L21norm_brute + norm(W(i,:));
% end
% L21norm_brute

%%% loopless
L21norm = sum(sqrt(sum(W.^2,2)));