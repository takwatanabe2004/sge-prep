%% tw_bal_gridsearch_vol_15cv_15resamp.m
%==============================================================================%
% Do gridsearch via 15-fold-CV...repeat 15times with different subsampling.
%------------------------------------------------------------------------------%
% - Use the "diff" features of FA/TR volumes to classify
%==============================================================================%
% 08/05/2015
%%
clear all; 
purge;

%| show label distribution of the two groups of interest
flag_print_labeldistr = false;
%% setup
% diffusionType = 'FA'; % {'FA', 'TR'}
diffusionType = 'TR'; % {'FA', 'TR'}

%==============================================================================%
% Select the two time-points for taking the "diff" over
% (time2 > time1 required convention for consistency)
%------------------------------------------------------------------------------%
% time1, time2 = 'v06', 'v12', or 'v24'
%==============================================================================%
time2 = 'v24';
time1 = 'v12';

%==============================================================================%
% choose the group of interest (optional: also mask by gender)
%==============================================================================%
group = 'Gender'; %{'DX', 'HRpLRm', 'HRpHRm', 'Risk', 'Gender'}
gender = '';  %{'male','female', ''}

%==============================================================================%
% skip zscore trasnformation? (may drop this option in the future)
% (my default has been to apply zscore, hence the awkward flag-name here)
%==============================================================================%
flag_skip_zscore = false;

%==============================================================================%
% graphnet or elastic net?
%==============================================================================%
opt.pen = 'gnet'; % {'gnet', 'enet'}

%==============================================================================%
% Number of cv-folds & Number of resampling
%==============================================================================%
opt.K = 15;       % <- 20-fold CV
opt.nresamp = 15; % <- 10 resampling

%==============================================================================%
% gridsearch range
%==============================================================================%
opt.lamgrid = 2.^[-14:-2];   % sparsity penalty
opt.gamgrid = 2.^[-22:2:8];  % spatial  penalty
% opt.lamgrid = 2.^[-14:5:-2];   % sparsity penalty
% opt.gamgrid = 2.^[-22:9:8];  % spatial  penalty
disp('*** lamgrid ***')
fprintf('%14.10f\n', opt.lamgrid)
disp('*** gamgrid ***')
fprintf('%14.10f\n', opt.gamgrid)
len_lam = length(opt.lamgrid)
len_gam = length(opt.gamgrid)
% return
%% variables and path to save
mFileName = mfilename;
timeStamp = tak_timestamp;
flag_done = false; %| indicates completion status of the script

%| 'iresamp' saved since i save intermediate result every iteration
outVars = {'iresamp','flag_done','grid_results', ...
           'aux_info','opt', 'timeStamp', 'mFileName'}; 

cwd = pwd; 
outname=['VOL_',diffusionType,'diff_BAL_gridcv_',opt.pen,'_',...
         gender,group,'_',time2,time1]

%| if nozscore flag is on, indicate on the output filename
if flag_skip_zscore
    outname = strcat('nozscore_',outname);
end

%%% regexp cleanup to ensure output-name is a valid filename %%%%
outpath = fullfile(cwd,outname)
%% setup classifier
% opt.training.lam = 2^-8;
% opt.training.gam = 2^-2;
opt.training.maxiter = 400;
opt.training.tol = 1e-3;
opt.training.progress = inf;
opt.training.silence = true;
opt.training.funcval = false;
opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_train(X,y,option);
opt.ftest  = @(X,model) tak_clf_linear_model_predict(X,model);  
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

% if flag_print_labeldistr
%     tak_meta_info_summary(meta_info)
% end

switch lower(opt.pen)
    case 'enet'
        opt.training.C   = speye(p); % <- elastic-net
    case 'gnet'
        opt.training.C   = C;
    otherwise
        error('opt.pen can only be ''enet'' or ''gnet''')
end

%% create "diff" features
%==============================================================================%
% construct "diff" features
%==============================================================================%
[Xdiff, meta_info_diff, diff_info] = ...
               tak_get_diff_vol_0804(Xfull, meta_info,session_mask,time1,time2);
clear Xfull
aux_info.meta_info_diff = meta_info_diff;
aux_info.diff = diff_info;

if flag_print_labeldistr
    tak_print_ibis_labels_vol(time1,time2)
end

%==============================================================================%
% breakup features into two groups for classification
%==============================================================================%
[Xp, Xn, meta_info_group] = ...
                  tak_get_two_groups_ibis(Xdiff, meta_info_diff, group, gender);
np = size(Xp,1);
nn = size(Xn,1);
yp =  ones(np,1);
yn = -ones(nn,1);
meta_info_group.group = vertcat(  dataset(meta_info_group.group1),  ...
                                  dataset(meta_info_group.group2));

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
%% setup grid search
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
%% run gridsearch
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
    if ~flag_skip_zscore
        %| standardize....stabilizes numerical optimization algorithm
        X = zscore(X);
    end
    
    %==========================================================================%
    % now "balanced" data ready!  
    % run grid search for this particular subsampled dataset
    %==========================================================================%
%     keyboard
    for igam = 1:len_gam
        igam
        opt.training.gam = opt.gamgrid(igam);
        for ilam = 1:len_lam
%             ilam
            opt.training.lam = opt.lamgrid(ilam);
            %==================================================================%
            % apply cross-validation
            %==================================================================%
            rng(0) % <- for consistent cv-subsamples for all (igam,ilam) combo

            [clf_summary,cvoutput]= tak_cv_classifier(X,y,opt);
            grid_results.acc(igam,ilam,iresamp) = clf_summary.accuracy;
            grid_results.TPR(igam,ilam,iresamp) = clf_summary.TPR;
            grid_results.TNR(igam,ilam,iresamp) = clf_summary.TNR;
            grid_results.F1( igam,ilam,iresamp) = clf_summary.F1;
            grid_results.auc(igam,ilam,iresamp) = clf_summary.auc;
            grid_results.PPV(igam,ilam,iresamp) = clf_summary.precision;
            grid_results.NPV(igam,ilam,iresamp) = clf_summary.NPV;
            aux_info.cvoutput{igam,ilam,iresamp} = cvoutput;
%             keyboard
        end % <- lamgrid
    end % <- gamgrid
    save(outpath, outVars{:})
end % <- iresamp grid


flag_done = true;
save(outpath,outVars{:}) 





