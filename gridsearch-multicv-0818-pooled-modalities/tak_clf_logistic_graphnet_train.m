function model = tak_clf_logistic_graphnet_train(X, y, option)
%% model = tak_clf_logistic_graphnet_train(X, y, option)
%==============================================================================%
% Train GraphNet penalized logistic regression classifier
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

%| incidence matrix describing neighborhood structure
C = option.C;

model.w = tak_GN_logistic_FISTA_linesearch(X,y,lam,gam,option,C);