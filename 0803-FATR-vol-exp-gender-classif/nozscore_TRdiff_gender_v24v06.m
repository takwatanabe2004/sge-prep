%% tw_0802_balanced_gender_LOO_VOLdiff_template.m
%==============================================================================%
% - Use the "diff" features of FA/TR volumes to classify gender
%------------------------------------------------------------------------------%
% Code based on graphnet_FAdiff_v24_v06m_DX.m, but lot of things trimmed
%==============================================================================%
% 07/31/2015
%%
clear all; 
purge;

%% setup
% diffusionType = 'FA'; % {'FA', 'TR'}
diffusionType = 'TR'; % {'FA', 'TR'}

time2='v24';
time1='v06';
%% load data
switch upper(diffusionType)
    case 'FA'
        load('IBIS_FAvol_avgdsamp_0723_2015.mat')
        Xfull = design_FA;
        clear design_FA;
    case 'TR'
        load('IBIS_TRvol_avgdsamp_0723_2015.mat')
        Xfull = design_TR;
        clear design_TR
end
p = size(Xfull,2);
C = graph_info.incidenceMatrix;
%% setup classifier
% opt.zscore = true; % <- normalize?

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
outVars = {'iresamp','flag_done','clf_resamp_results', 'meta_info_diff',...
           'aux_info','opt', 'timeStamp', 'mFileName'}; 

cwd = fileparts(mfilename('fullpath'));
outname=['nozscore_VOL_',diffusionType,'diff_BAL_gender_LOO_',time2,time1];
% outname
% outpath = fullfile(cwd,outname);
outname
[~,cwd] = system('pwd')
outpath = strcat(cwd,'/',outname)
% return
%% cookup "diff" features using two time points: time2 and time1 (time2 > time1)
%| unique subjects
[scan_info, scan_count] = tak_get_session_info(meta_info);

time_diff = [time2,'_',time1];
mask.session = session_mask.(time_diff);

%| #subjects who has scans at both time1 & time2
nsubj =   scan_count.(time_diff);

%| since "lookups" are ordered, time1, time2 should be interleaved after masking
Xtmp = Xfull(mask.session,:); 
lookup = meta_info.lookup(mask.session);

%| the "diff" features
Xdiff = zeros(nsubj,p);

for i = 1:nsubj
    ii = 1 + 2*(i-1);
    Xdiff(i,:) = Xtmp(ii+1,:) - Xtmp(ii,:);
    diffList{i,1} = [lookup{ii+1},' - ', lookup{ii}];

    %==========================================================================%
    % sanity check: ensure i'm taking the "diff" of the right data
    %==========================================================================%
    %| are we looking at the same subject?  check subject IDs
    test1 = isequal(lookup{ii}(1:6), lookup{ii+1}(1:6));
    
    %| check for time points
    test2 = strcmpi(lookup{ii+1}(9:10), num2str(time2(2:3))  );
    test3 = strcmpi(lookup{ii}(9:10),   num2str(time1(2:3))  );
    
    %| test assertion
    assert( test1 &&  test2 && test3 )
end
aux_info.diffList = diffList;

%| get "meta_info" for our diff features
meta_info_diff = tak_meta_info_mask(meta_info,mask.session);

%| 2nd mask to get "every other" scans 
%| (these should be time2 scans as i'm taking even indices here)
mask_even = false(2*nsubj,1);
mask_even(2:2:2*nsubj) = true;

meta_info_diff = tak_meta_info_mask(meta_info_diff, mask_even);
% return
%%
%==============================================================================%
% break data into "groups" for binary classification
%==============================================================================%
fmask = @(Cell,Str) tak_cell_find_string(Str,Cell);

mask.group1 = fmask(meta_info_diff.gender, 'male');
mask.group2 = fmask(meta_info_diff.gender, 'female');
% return
% fprintf('%s = %d\n', group1, sum(mask.group1))
% fprintf('%s = %d\n-----------------\n', group2, sum(mask.group2))

%| first group: set as "positive" class
Xp = Xdiff(mask.group1,:);
yp = ones( sum(mask.group1), 1);

%| second group: set as "negative" class
Xn = Xdiff(mask.group2,:);
yn = -ones(sum(mask.group2), 1);

aux_info.mask = mask;

meta_info_masked = tak_meta_info_mask(meta_info_diff, mask.group1 | mask.group2);
meta_info_group1 = tak_meta_info_mask(meta_info_diff, mask.group1);
meta_info_group2 = tak_meta_info_mask(meta_info_diff, mask.group2);
tak_meta_info_summary(meta_info_masked)

aux_info.meta_info = meta_info_masked;
aux_info.meta_info_group1 = meta_info_group1;
aux_info.meta_info_group2 = meta_info_group2;
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
%     iresamp
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
    % X = zscore(X);
    
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
%     keyboard
    %%
    save(outpath,outVars{:}) 
    %==========================================================================%
end

flag_done = true;
save(outpath,outVars{:}) 