function [ypr, score] = tak_clf_libsvm_predict(X, model)
%% out = tak_clf_LDA_NB_predict(X, model)
%=========================================================================%
% Just a wrapper function so that i can create a function handle that agrees
% with what my tak_cv_classifier.m routine expects.
%=========================================================================%
% (07/15/2015)
%%

%| libsvm expects the test label to be supplied to compute "accuracy"...just
%|+create random vector for this
crap = ones(size(X,1),1);
crap(1)=-1;

%| libsvm expects feature matrix to be sparse
[ypr,~,score] = svmpredict(crap, sparse(X), model, '-q');
% ypr = -SIGN(score);