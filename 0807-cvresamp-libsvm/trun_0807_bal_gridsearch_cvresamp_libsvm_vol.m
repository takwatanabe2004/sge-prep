function trun_0807_bal_gridsearch_cvresamp_libsvm_vol(setup)
%% trun_0807_bal_gridsearch_cvresamp_libsvm_vol.m
%==============================================================================%
% Cleanedup version of tw_0806_bal_gridsearch_vol_cv_resamp_libsvm.m
% (avoids saving "opt" containing function handles)
%------------------------------------------------------------------------------%
% setup - struct containing the following fields
%   K:
%   nresamp: 
%   lamgrid: C value in SVM
%   gamgrid: gamma in the rbf kernel
%   diffusion: 'FA' or 'TR'
% 
%   group = 'HRpHRm'; %{'DX', 'HRpLRm', 'HRpHRm', 'risk', 'gender'}
%   gender = 'male';  %{'male','female', ''}
% 
%   zscore = true/false (apply zscore or not)
% 
%   diff = true/false (diff feature or volume feature)
%       If diff = false:
%           session = 'v06', 'v12', or 'v24' 
%       If diff = true; (3 possible combo: v12v06, v24v06, v24v12)
%           time2 = 'v12' or 'v24'
%           time1 = 'v06' or 'v12'
%   
%------------------------------------------------------------------------------%
% Identical to tw_0806_bal_gridsearch_vol_cv_resamp_logistic, but for libsvm
%==============================================================================%
% 08/07/2015
%%

%| show label distribution of the two groups of interest
flag_print_labeldistr = true;

%| load relevant meta_info here
[~,host]=system('hostname');
host=host(1:end-1);
invars = {'graph_info','meta_info','session_mask'};
if strcmpi(host,'sbia-pc125-cinn') || strcmpi(host,'takanori-pc')
    load('IBIS_FAvol_avgdsamp_0723_2015',invars{:})
else
    %| for running on cluster
    load([fileparts(pwd), '/data/IBIS_FAvol_avgdsamp_0723_2015'],invars{:})
end
%% ========================== setup options ===================================%

%==============================================================================%
% Number of cv-folds & Number of resampling
%==============================================================================%
opt.K       = setup.K; % #-folds of CV
opt.nresamp = setup.nresamp; % # resampling of larger class for data balancing

if setup.diff % when using the "diff" feature (outputname becomes like v24v12)
    setup.session = strcat(setup.time2,setup.time1);
end
%% setup libsvm classifier
opt.ftrain = @(X,y,option) svmtrain(y,sparse(X),option);
opt.ftest  = @(X,model) tak_clf_libsvm_predict(X,model);

%| function handle for setting the 2 penalties for libsvm during grid search
%| (usage: opt.training = opt.setup(lambda, gamma)
opt.libsvm_setup = @(lam,gam) ...
                    ['-s 0 -t 2 -g ', num2str(gam),' -c ', num2str(lam),' -q'];

%==============================================================================%
% gridsearch range
%==============================================================================%
disp('*** lamgrid ***')
fprintf('%14.10f\n', setup.lamgrid)
disp('*** gamgrid ***')
fprintf('%14.10f\n', setup.gamgrid)
len_lam = length(setup.lamgrid)
len_gam = length(setup.gamgrid)
% return
%% variables and path to save
mFileName = mfilename;
timeStamp = tak_timestamp;
flag_done = false; %| indicates completion status of the script

%| 'iresamp' saved since i save intermediate result every iteration
outVars = {'iresamp','flag_done','setup','grid_results', ...
           'aux_info','timeStamp', 'mFileName'}; 

if setup.diff
    outname = 'VOLdiff_';
else
    outname = 'VOL_';
end
outname = [outname, setup.diffusion, '_BAL_gridcv_', setup.clfmodel,'_', ...
            setup.gender, setup.group,'_',setup.session]

%| if zscore is not used, indicate on the output filename
if ~setup.zscore
    outname = strcat('nozscore_',outname);
end

outpath = fullfile(pwd,outname)
%% \======================= setup completed ====================================
%% construct feature matrix with the setup specified above
if strcmpi(host,'sbia-pc125-cinn') || strcmpi(host,'takanori-pc')
    load('IBIS_FAvol_avgdsamp_0723_2015',invars{:})
else
    %| for running on cluster
    load([fileparts(pwd), '/data/IBIS_FAvol_avgdsamp_0723_2015'],invars{:})
end


%==============================================================================%
% load data
%==============================================================================%
if strcmpi(setup.diffusion,'FA')
    fname = 'IBIS_FAvol_avgdsamp_0723_2015.mat';
    if strcmpi(host,'sbia-pc125-cinn') || strcmpi(host,'takanori-pc')
        load(fname, 'design_FA')
    else
        %| load on cluster
        load([fileparts(pwd),'/data/',fname], 'design_FA')
    end
    Xfull = design_FA;
    clear design_FA
elseif strcmpi(setup.diffusion, 'TR')
    fname = 'IBIS_TRvol_avgdsamp_0723_2015.mat';
    if strcmpi(host,'sbia-pc125-cinn') || strcmpi(host,'takanori-pc')
        load(fname, 'design_TR')
    else
        %| load on cluster
        load([fileparts(pwd),'/data/',fname], 'design_TR')
    end
    Xfull = design_TR;
    clear design_TR
end

if setup.diff
    %==========================================================================%
    % construct "diff" features
    %==========================================================================%
    [Xdiff, meta_info_diff] = tak_get_diff_vol_0804(Xfull, ...
                             meta_info, session_mask, setup.time1, setup.time2);
    clear Xfull

    % breakup features into two groups for classification
    [Xp, Xn, meta_info_group] = tak_get_two_groups_ibis(Xdiff, ...
                                     meta_info_diff, setup.group, setup.gender);
    
    if strcmpi(host,'sbia-pc125-cinn') || strcmpi(host,'takanori-pc')
        if flag_print_labeldistr
            tak_print_ibis_labels_vol(setup.time1,setup.time2)
        end
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
    for igam = 1:len_gam
        igam
        gam = setup.gamgrid(igam);
        for ilam = 1:len_lam
%             ilam
            lam = setup.lamgrid(ilam);
            opt.training = opt.libsvm_setup(lam,gam);
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

