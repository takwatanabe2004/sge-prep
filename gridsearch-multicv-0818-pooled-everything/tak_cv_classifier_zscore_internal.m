function [cv_accuracy,output] = tak_cv_classifier_zscore_internal(X, y, option)
%% [cv_accuracy,output] = tak_cv_classifier_zscore_internal(X, y, option)
%==============================================================================%
% This will 
%------------------------------------------------------------------------------%
% Update 08/10/2015
% - added "stratified" option
%------------------------------------------------------------------------------%
% - need to figure out what the right data structure for the "training" and
%   "testing" phase for different classifiers...
%------------------------------------------------------------------------------%
% X: (n x p) data matrix, rows = data samples, cols = feature index
% y: (n x 1) label vector (assumed to be +1/-1)
%
% option: struct that must contain 3 fields: {'ftrain', 'ftest',' 'training'}
%
% option.ftrain - function handle to training classifier
% >> model = ftrain(Xtr,ytr, option.training)
%
% option.ftest - function handle to test/predict test points using trained model
% >> [ypr, scr] = ftest(Xts,model);
%
% option.training 
% - struct whose fields element depends on the classification model you are
%   training.
%==============================================================================%
% 07/10/2017
%%
%==============================================================================%
% parse out "option" details
%==============================================================================%
K = option.K; % K-fold CV
ftrain = option.ftrain;
ftest  = option.ftest;

%| added 08/10 - stratified sampling: default off
if ~isfield(option,'cv_stratify') || isempty(option.cv_stratify)
    disp('--- Stratify field not given....no stratification used (default) ----')
    option.cv_stratify = false; 
end

%| Some classifiers has no option/tuning....set field to empty if so
if ~isfield(option,'training')
    option.training = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if option.cv_stratify
    %| stratified k-fold (each subsample has roughly the same class proportion)
%     disp('stratified CV')
    cvinfo = cvpartition(y,'kfold',K);
else
    n = length(y);
    cvinfo = cvpartition(n,'Kfold',K);
end

ytrue = [];
ypred = [];
score = [];

% % # features to submit
% T = 25;

% figure,imexp
for k=1:K
    if mod(k,25)==0, fprintf('%d out of %d\n',k,K),end;
    idx_tr = cvinfo.training(k);
    idx_ts = cvinfo.test(k);
    
    Xtr = X(idx_tr,:);
    ytr = y(idx_tr);
    
    Xts = X(idx_ts,:);
    yts = y(idx_ts);
    
%     figure,imexp
%     subplot(121),timagesc(Xtr)
%     subplot(122),timagesc(Xts)
%     pause

    assert( sum(idx_ts & idx_tr)==0, 'overlap in training/testing index! code messed up!')
    %%
    xmean = mean(Xtr);
    xstd  = std(Xtr);
    Xtr_z = bsxfun(@minus, Xtr, xmean);
    Xtr_z = bsxfun(@rdivide, Xtr_z, xstd);
    assert( isequal(zscore(Xtr), Xtr_z) )
    %%
    Xts_z = bsxfun(@minus,     Xts, xmean);
    Xts_z = bsxfun(@rdivide, Xts_z, xstd);
%     keyboard
    %%
%     subplot(321),tplot(std(Xtr_z))
%     subplot(323),tplot(std(Xtr))
%     subplot(325),tplot(std(X))
%     subplot(322),tplot(mean(Xtr_z))
%     subplot(324),tplot(mean(Xtr))
%     subplot(326),tplot(mean(X))
%     subplot(413),tplot(std(Xts_z))
%     subplot(414),tplot(std(Xts))
    %%
    Xtr = Xtr_z;
    Xts = Xts_z;
    %%
    %%%%%%%%%%% feature pruning %%%%%%%%%
    if isfield(option,'ttest')
%         'ttest'
        [idx_best] = tak_ttest_prune(Xtr, ytr);

        Xtr = Xtr(:,idx_best(1:option.ttest));
        Xts = Xts(:,idx_best(1:option.ttest));
    end   
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %==========================================================================%
    % Training
    %==========================================================================%
    model = ftrain(Xtr,ytr,option.training);
%     keyboard
    %==========================================================================%
    % Testing 
    %==========================================================================%
    [ypr, scr] = ftest(Xts,model);
%     [ypr, acc, prob] = predict(Xts, model, '-b -q')
    
    %%%%%% collect everything %%%%%
    ytrue = [ytrue; yts];
    ypred = [ypred; ypr];
    score = [score; scr];
end

output.ytrue = ytrue;
output.ypred = ypred;
output.score = score;
output.cv_info = cvinfo;
% keyboard
cv_accuracy = tak_binary_classification_summary(ypred,ytrue);

%% update  07/24/2015 - pad on auc info
[fpr,tpr,~,auc]=perfcurve(ytrue, score, +1);
cv_accuracy.auc = auc;
output.fpr = fpr;
output.tpr = tpr;