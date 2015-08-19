function model = tak_clf_L2loss_TV_group_ADMM_FFT_train(X, y, option)
%% model = tak_clf_L2loss_FL_group_ADMM_FFT_train(X, y, option)
%==============================================================================%
% Train Fused-Lasso penalized squared-loss regression classifier
% - basically a wrapper to tak_TV_group_regr_ADMM_FFT_over_relax.m
%------------------------------------------------------------------------------%
%==============================================================================%
% 08/18/2015
%%
% warning('code still in progress')
if ~exist('option','var'), option = []; end
if ~isfield(option,'over_relax')
    option.over_relax = false;
end

%| L1 penalty parameter
lam = option.lam;

%| GraphNet penalty parameter
gam = option.gam;

if ~isfield(option,'rho')
    option.rho = 1; % ADMM parameter
end

model.w = tak_TV_group_regr_ADMM_FFT_over_relax(X,y,lam,gam,option,option.nvol);