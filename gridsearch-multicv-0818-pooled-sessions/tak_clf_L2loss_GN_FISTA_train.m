function model = tak_clf_L2loss_GN_FISTA_train(X, y, option)
%% model = tak_clf_L2loss_GN_ADMM_train(X, y, option)
%==============================================================================%
% Train Elastic-net penalized squared-loss regression classifier
% - basically a wrapper to tak_GN_logistic_FISTA_linesearch.m
%------------------------------------------------------------------------------%
%==============================================================================%
% 07/24/2015
%%
% warning('code still in progress')
if ~exist('option','var'), option = []; end

%| L1 penalty parameter
lam = option.lam;

%| GraphNet penalty parameter
gam = option.gam;

%| incidence matrix (contains neighborhood structure)
C = option.C;

model.w = tak_GN_regr_FISTA(X,y,lam,gam,option, C);