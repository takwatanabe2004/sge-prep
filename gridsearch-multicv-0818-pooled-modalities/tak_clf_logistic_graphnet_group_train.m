function model = tak_clf_logistic_graphnet_group_train(X, y, option)
%% model = tak_clf_logistic_graphnet_group_train(X, y, option)
%==============================================================================%
% Train GraphNet penalized logistic regression classifier with GroupLasso penalty
% - basically a wrapper to tak_GN_group_logistic_FISTA_linesearch.m
%------------------------------------------------------------------------------%
%==============================================================================%
% 08/18/2015
%%
% warning('code still in progress')
if ~exist('option','var'), option = []; end

%| L1 penalty parameter
lam = option.lam;

%| GraphNet penalty parameter
gam = option.gam;

%| incidence matrix describing neighborhood structure
C = option.C;

%| number of "groups" to consider via the L21 group lasso penalty
num_group = option.num_group;

model.w = tak_GN_group_logistic_FISTA_linesearch(X,y,lam,gam,option,C,num_group);