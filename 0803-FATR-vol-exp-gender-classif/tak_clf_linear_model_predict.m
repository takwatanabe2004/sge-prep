function [ypr, score] = tak_clf_linear_model_predict(X, model)
%% [ypr, score] = tak_clf_linear_model_predict(X, model)
%==============================================================================%
% Update 07/24/2015
% - Made the "model.b" bias/offset term an optional field
%------------------------------------------------------------------------------%
% Classification for any linear model of the form: sign(w'*x + b),
%  where x = test data point
%
% model: struct containing fields w and b
% 
% Input
%   X = (n x p) data matrix, n = # data points, p = feature dimension
%------------------------------------------------------------------------------%
%==============================================================================%
% 07/22/2015
%%
if isfield(model,'b')
    score = X*model.w + model.b;
else
    score = X*model.w;
end

ypr = SIGN(score);