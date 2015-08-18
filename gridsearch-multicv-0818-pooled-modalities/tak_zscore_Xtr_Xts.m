function [Xtr_z, Xts_z] = tak_zscore_Xtr_Xts(Xtr, Xts)
%% [Xtr_z, Xts_z] = tak_zscore_Xtr_Xts(Xtr, Xts)
%==============================================================================%
% Xtr = (ntr x p) training design matrix (row = data points)
% Xts = (nts x p) testing  design matrix (row = data points)
% 
% Apply zscore normalization to Xtr and Xts.
% For the testing design matrix Xts, the mean and std-dev from Xtr is applied.
%------------------------------------------------------------------------------%
%==============================================================================%
% 08/15/2015
%%
xmean = mean(Xtr);
xstd  = std(Xtr);

%| normalize training data matrix
Xtr_z   = bsxfun(@minus,   Xtr  , xmean);
Xtr_z   = bsxfun(@rdivide, Xtr_z, xstd);

%| normalize testing data matrix
Xts_z   = bsxfun(@minus,   Xts  , xmean);
Xts_z   = bsxfun(@rdivide, Xts_z, xstd);
%%
% [Xtr_z2, Xts_z2] = tak_zscore_Xtr_Xts(X, Xts);
% % isequal(Xts_z,Xts_z2)
% isequal(X_z,Xtr_z2)