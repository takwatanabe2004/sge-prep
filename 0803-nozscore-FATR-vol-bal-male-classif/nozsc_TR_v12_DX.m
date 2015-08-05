%% tw_0731_balanced_maleOnly_LOO_VOL_nozscore_template.m
%==============================================================================%
% - Use the features of FA/TR volumes to classify
%------------------------------------------------------------------------------%
%
%==============================================================================%
% 07/31/2015
%%
clear all; 
purge;

%% setup
% diffusionType = 'FA'; % {'FA', 'TR'}
diffusionType = 'TR'; % {'FA', 'TR'}

session='v12'; % {'v06','v12','v24'}

%| assign two groups ("male"-mask to be applied later)
group  = 'DX';   group1 = 'ASD';     group2 = 'Not ASD';
% group  = 'group';   group1 = 'HR+';     group2 = 'LR-';
% group  = 'group';   group1 = 'HR+';     group2 = 'HR-';
% group = 'risk';     group1 = 'HR';      group2 = 'LR';
%% load data
switch upper(diffusionType)
    case 'FA'
        load([fileparts(pwd),'/data/IBIS_FAvol_avgdsamp_0723_2015.mat'])
        Xfull = design_FA;
        clear design_FA;
    case 'TR'
        load([fileparts(pwd),'/data/IBIS_TRvol_avgdsamp_0723_2015.mat'])
        Xfull = design_TR;
        clear design_TR
end
p = size(Xfull,2);
C = graph_info.incidenceMatrix;
%% setup classifier
%%%%%% logistic graphnet %%%%%%%%%%
opt.training.lam = 2^-8;
opt.training.gam = 2^-2;
% opt.training.C   = speye(p); % <- elastic-net
opt.training.C   = C;
opt.training.maxiter = 400;
opt.training.tol = 1e-3;
opt.training.progress = inf;
opt.training.silence = true;
opt.training.funcval = false;
opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_train(X,y,option);
opt.ftest  = @(X,model) tak_clf_linear_model_predict(X,model);  
%% variables and path to save
mFileName = mfilename;
timeStamp = tak_timestamp;
flag_done = false; %| indicates completion status of the script

%| 'iresamp' saved since i save intermediate result every iteration
outVars = {'iresamp','flag_done','clf_resamp_results',...
           'aux_info','opt', 'timeStamp', 'mFileName'}; 

cwd = pwd; %fileparts(mfilename('fullpath'));
outname=['nozscore_VOL_',diffusionType,'_BAL_male_LOO_',group1,'_vs_',group2,'_',session];

%%% regexp cleanup to ensure output-name is a valid filename %%%%
outname = regexprep(outname,'Not ASD','TDI');
outname = regexprep(outname,'+','p');
outname = regexprep(outname,'-','m');
outname
outpath = fullfile(cwd,outname);
% return
%% setup design matrix and labels
%==============================================================================%
% break data into "groups" for binary classification
%==============================================================================%
fmask = @(Cell,Str) tak_cell_find_string(Str,Cell);

% remove "female" class
mask_male = fmask(meta_info.gender, 'male');
switch session
    case 'v06'
        mask_session = meta_info.session == 6;
    case 'v12'
        mask_session = meta_info.session == 12;
    case 'v24'
        mask_session = meta_info.session == 24;
end


% get masks for the two groups of interest
mask.group1 = fmask(meta_info.(group),group1) & mask_male & mask_session;
mask.group2 = fmask(meta_info.(group),group2) & mask_male & mask_session;

aux_info.meta_info = tak_meta_info_mask(meta_info, mask.group1 | mask.group2);
aux_info.meta_info_group1 = tak_meta_info_mask(meta_info, mask.group1);
aux_info.meta_info_group2 = tak_meta_info_mask(meta_info, mask.group2);
tak_meta_info_summary(aux_info.meta_info)

%| first group: set as "positive" class
Xp = Xfull(mask.group1,:);
yp = ones( sum(mask.group1), 1);

%| second group: set as "negative" class
Xn = Xfull(mask.group2,:);
yn = -ones(sum(mask.group2), 1);

aux_info.mask = mask;
% return
%% setup LOO-cross validation with dataset forced to balance with resampling
%| # resampling of larger class for data balancing
aux_info.nresamp = 30;

%| number of "positive" and "negative" class
np = length(yp);
nn = length(yn);
n = 2 * min([np,nn]); 

opt.K = n;% <- LOO, so #folds = # samples

aux_info.rng_seed = 0; % <- info for replicability

%%%% set seed point for replicability + consistency %%%%%
rng(aux_info.rng_seed)

tic
for iresamp = 1:aux_info.nresamp
    if mod(iresamp,5)==0
        fprintf('%3d out of %3d (%7.2f sec)\n',iresamp,aux_info.nresamp,toc);
    end
%     iresamp
    %==========================================================================%
    % force data balance
    %==========================================================================%
    %| random subsampling index
    idxresamp = randperm(max([np,nn]), min([np,nn]));
    
    %| save resampled indices as row vector for later reference
    aux_info.idxresamp(iresamp,:) = idxresamp;
    
    %| subsample
    if np > nn
        % subsample the positive class for data balance
        Xp_bal = Xp(idxresamp,:);
        yp_bal = yp(idxresamp);
        
        % create "balanced" design matrix
        X = vertcat(Xp_bal, Xn);
        y = vertcat(yp_bal, yn);
    else
        % subsample the negative class for data balance
        Xn_bal = Xn(idxresamp,:);
        yn_bal = yn(idxresamp);
        
        % create "balanced" design matrix
        X = vertcat(Xp, Xn_bal);
        y = vertcat(yp, yn_bal);
    end
    %| standardize....stabilizes numerical optimization algorithm
%     X = zscore(X);
    
    %==========================================================================%
    % apply cross-validation on the balanced data
    %==========================================================================%
    [clf_summary, clf_output]= tak_cv_classifier(X,y,opt);
    clf_resamp_results.acc(iresamp) = clf_summary.accuracy;
    clf_resamp_results.TPR(iresamp) = clf_summary.TPR;
    clf_resamp_results.TNR(iresamp) = clf_summary.TNR;
    clf_resamp_results.F1(iresamp)  = clf_summary.F1;
    clf_resamp_results.auc(iresamp) = clf_summary.auc;
    clf_resamp_results.PPV(iresamp) = clf_summary.precision;
    clf_resamp_results.NPV(iresamp) = clf_summary.NPV;
%     clf_resamp_results
%     timagesc(X)
%     keyboard
    %%
    aux_info.ytrue(iresamp,:) = clf_output.ytrue;
    aux_info.ypred(iresamp,:) = clf_output.ypred;
    aux_info.score(iresamp,:) = clf_output.score;
    aux_info.fpr(iresamp,  :) = clf_output.fpr;
    aux_info.tpr(iresamp,  :) = clf_output.tpr;
    aux_info.cv_info(iresamp) = clf_output.cv_info;
%     aux_info
    %%
    save(outpath,outVars{:}) 
    %==========================================================================%
end

flag_done = true;
save(outpath,outVars{:}) 