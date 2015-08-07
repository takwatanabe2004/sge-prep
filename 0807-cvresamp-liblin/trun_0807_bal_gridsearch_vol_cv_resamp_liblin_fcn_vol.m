function trun_0807_bal_gridsearch_vol_cv_resamp_liblin_fcn_vol(setup)
    
%==============================================================================%
% Update 08/07/2015
% - function handle when used here gets saved as a huge file 
%   (this didn't happen when using this script as "non"-function...so i have no
%    idea how workspace data are handled with anonymous functions)
% - decided to NOT save the struct "opt", and keep everything into variable 
%   "setup" that doesn't contain any fhandles.
%------------------------------------------------------------------------------%
%------------------------------------------------------------------------------%
% Do gridsearch via K-fold-CV...repeat multiple times with different subsamples
% (code polished version of tw_bal_gridsearch_vol_15cv_15resamp)
%------------------------------------------------------------------------------%
% Identical to tw_0806_bal_gridsearch_vol_cv_resamp_logistic, but for liblin
% with only one tuning parameter
%==============================================================================%
% 08/07/2015
%%

%| show label distribution of the two groups of interest
flag_print_labeldistr = false;

%| load relevant meta_info here
load([fileparts(pwd),'/data/IBIS_FAvol_avgdsamp_0723_2015'],...
       'graph_info','meta_info','session_mask')
p = size(graph_info.adjacencyMatrix,1);

% tak_meta_info_summary(meta_info)
%% ========================== setup options ===================================%
%==============================================================================%
% Number of cv-folds & Number of resampling
%==============================================================================%
opt.K       = 15; % #-folds of CV
opt.nresamp = 15; % # resampling of larger class for data balancing

%%% copy info to "setup", which by design will be "function-handle free" %%%
setup.K       = opt.K;
setup.nresamp = opt.nresamp;
%% feature and classification setup: choose modality and groups to classify
%==============================================================================%
% choose modality, ie the diffusion measure type (FA or TR)
%==============================================================================%
% setup.diffusion = 'FA'; % {'FA', 'TR'}
% setup.diffusion = 'TR'; % {'FA', 'TR'}

%==============================================================================%
% choose the group of interest (optional: also mask by gender)
% - note: if group='gender', than set gender=''
%==============================================================================%
% setup.group = 'DX'; %{'DX', 'HRpLRm', 'HRpHRm', 'risk', 'gender'}
% setup.gender = 'male';  %{'male','female', ''}

%==============================================================================%
% Choose on whether to use:
%   1. FA/TR measures at a single time point as features, or
%   2. 'diff'erence between FA/TR measures as two time points
%==============================================================================%
%--------------------------------------------------------------%
% direct volume feature setup (comment out if not in use)
%   - just select the "session" number (a single time-point)
%--------------------------------------------------------------%
% setup.diff = false;
% setup.session = 'v24';  %{'v06', 'v12', 'v24', ''}

%--------------------------------------------------------------%
% "diff" feature case: (comment out if not in use)
%   - Select the two time-points for taking the "diff" over
%     (time2 > time1 required convention for consistency)
%--------------------------------------------------------------%
% setup.diff  = true;
% setup.time2 = 'v12'; % {'v12', 'v24'}
% setup.time1 = 'v06'; % {'v06', 'v12'}
% setup.session = strcat(setup.time2,setup.time1);

%==============================================================================%
% standardize features? 
%==============================================================================%
% setup.zscore = true;
%% setup libsvm classifier
%==============================================================================%
% graphnet or elastic net?
%==============================================================================%
opt.clfmodel= setup.clfmodel; % 'liblinL1'; % {'liblinL1', 'liblinL2'}
opt.ftrain = @(X,y,option) train(y,sparse(X),option);
opt.ftest  = @(X,model) tak_clf_liblinear_predict(sparse(X),model);
% keyboard
%| function handle for setting the penalty for liblinear during grid search
%| (usage: opt.training = opt.setup(C)
if strcmpi(opt.clfmodel(end-1:end), 'L2')
    %| L2 regularized logistic (dual - faster than primal as n < p)
    opt.liblin_setup = @(lam) ['-s 7 -c ', num2str(lam),' -q'];
elseif strcmpi(opt.clfmodel(end-1:end), 'L1')
    %| L1 regularized logistic
    opt.liblin_setup = @(lam) ['-s 6 -c ', num2str(lam),' -q'];
end

%==============================================================================%
% gridsearch range
%==============================================================================%
opt.lamgrid = 2.^[-10:20]; % C value in SVM
setup.lamgrid = opt.lamgrid;
disp('*** lamgrid ***')
fprintf('%14.10f\n', opt.lamgrid)
len_lam = length(opt.lamgrid)
% return
%% variables and path to save
mFileName = mfilename;
timeStamp = tak_timestamp;
flag_done = false; %| indicates completion status of the script

%| 'iresamp' saved since i save intermediate result every iteration
%%% removed 'opt' which contains anonymous function...which gets ultra-bulky
%%% when saved
outVars = {'iresamp','flag_done','setup','grid_results', ... 
           'aux_info', 'timeStamp', 'mFileName'};  

if setup.diff
    outname = 'VOLdiff_';
else
    outname = 'VOL_';
end
outname = [outname, setup.diffusion, '_BAL_gridcv_', opt.clfmodel,'_', ...
            setup.gender, setup.group,'_',setup.session]

%| if zscore is not used, indicate on the output filename
if ~setup.zscore
    outname = strcat('nozscore_',outname);
end

outpath = fullfile(pwd,outname)
% return
%% \======================= setup completed ====================================
%% construct feature matrix with the setup specified above
if strcmpi(setup.diffusion,'FA')
    load([fileparts(pwd),'/data/IBIS_FAvol_avgdsamp_0723_2015'],'design_FA')
    Xfull = design_FA;
    clear design_FA
elseif strcmpi(setup.diffusion, 'TR')
    load([fileparts(pwd),'/data/IBIS_TRvol_avgdsamp_0723_2015'], 'design_TR')
    Xfull = design_TR;
    clear design_TR
end

if setup.diff
    %==========================================================================%
    % construct "diff" features
    %==========================================================================%
    [Xdiff, meta_info_diff, diff_info] = tak_get_diff_vol_0804(Xfull, ...
                             meta_info, session_mask, setup.time1, setup.time2);
    clear Xfull

    % breakup features into two groups for classification
    [Xp, Xn, meta_info_group] = tak_get_two_groups_ibis(Xdiff, ...
                                     meta_info_diff, setup.group, setup.gender);
    
    if flag_print_labeldistr
        tak_print_ibis_labels_vol(setup.time1,setup.time2)
    end
else
    %==========================================================================%
    % else, use the volume features "as is"
    %==========================================================================%
    % breakup features into two groups for classification
    [Xp, Xn, meta_info_group] = tak_get_two_groups_ibis(Xfull, ...
                           meta_info, setup.group, setup.gender, setup.session);
end

np = size(Xp,1);
nn = size(Xn,1);
yp =  ones(np,1);
yn = -ones(nn,1);
%------------------------------------------------------------------------------%
% Overall "meta_info" for the group 
%  - note; here the index ordering is partitioned by group, so the 1st np rows
%    should be from group1, and the last nn from group2)
%  - here use 'datset' as it's more amenable to array-type operation 
%    (eg vertcat) than struct, and it's easy to visualize in the variable editor
%------------------------------------------------------------------------------%
meta_info_group.group = vertcat(  dataset(meta_info_group.group1),  ...
                                  dataset(meta_info_group.group2));
if flag_print_labeldistr
    tak_meta_info_summary(meta_info_group.group)
    tak_meta_info_summary(meta_info_group.group1)
    tak_meta_info_summary(meta_info_group.group2)
end
aux_info.group = meta_info_group;
% return
%% grid search prep
%------------------------------------------------------------------------------%
% - after much thought, i decided to precompute the "resampling indices" for
%   data balance here.  
% - this was since I wanted to ensure consistent K-fold samples are obtained
%   during cross validation using rng(0) in the in the cv-loop below
%   (note: this issue would not arise with LOO)
%------------------------------------------------------------------------------%

%==============================================================================%
% precompute the "resampling indices" needed for data balance
%==============================================================================%
%| set seed point for replicability + consistency
aux_info.rng_seed = 0; % <- info for replicability
rng(aux_info.rng_seed)
for iresamp = 1:opt.nresamp
    %| random subsampling index
    idxresamp = randperm(max([np,nn]), min([np,nn]));
    
    %| save resampled indices as row vector for later reference
    aux_info.idxresamp(iresamp,:) = idxresamp;
end
%% gridsearch run
%==============================================================================%
% Three loops
% (1) iresamp (subsampling for data balancing)
%    (2) gamma grid (graph/elastic-net penalty)
%        (3) lambda grid (sparsity penalty)
%==============================================================================%
tic
for iresamp = 1:opt.nresamp
%     iresamp
    if mod(iresamp,1)==0
        fprintf('%3d out of %3d (%7.2f sec)\n',iresamp,opt.nresamp,toc);
    end
    %==========================================================================%
    % force data balance
    %==========================================================================%
    %| random subsampling index (precomputed above)
    idxresamp = aux_info.idxresamp(iresamp,:);
    
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
    if setup.zscore
        %| standardize....stabilizes numerical optimization algorithm
        X = zscore(X);
    end
    
    %==========================================================================%
    % now "balanced" data ready!  
    % run grid search for this particular subsampled dataset
    %==========================================================================%
%     keyboard
    for ilam = 1:len_lam
%             ilam
        lam = opt.lamgrid(ilam);
        opt.training = opt.liblin_setup(lam);
        %==================================================================%
        % apply cross-validation
        %==================================================================%
        rng(0) % <- for consistent cv-subsamples for all (igam,ilam) combo

        [clf_summary,cvoutput]= tak_cv_classifier(X,y,opt);
        grid_results.acc(ilam,iresamp) = clf_summary.accuracy;
        grid_results.TPR(ilam,iresamp) = clf_summary.TPR;
        grid_results.TNR(ilam,iresamp) = clf_summary.TNR;
        grid_results.F1( ilam,iresamp) = clf_summary.F1;
        grid_results.auc(ilam,iresamp) = clf_summary.auc;
        grid_results.PPV(ilam,iresamp) = clf_summary.precision;
        grid_results.NPV(ilam,iresamp) = clf_summary.NPV;
        aux_info.cvoutput{ilam,iresamp} = cvoutput;
%             keyboard
    end % <- lamgrid
    save(outpath, outVars{:})
end % <- iresamp grid


flag_done = true;
save(outpath,outVars{:}) 

