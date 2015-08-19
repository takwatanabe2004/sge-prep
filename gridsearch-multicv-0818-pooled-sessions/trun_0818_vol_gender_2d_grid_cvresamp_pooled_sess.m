function trun_0818_vol_gender_2d_grid_cvresamp_pooled_sess(setup)
%==============================================================================%
% Classify 
% 
% Code based on t_0816_vol_classify_gender_subgroup_group_lasso_time.m
%------------------------------------------------------------------------------%
% Do gridsearch via K-fold-CV...repeat multiple times with different subsamples
% 
% Note: don't save struct that includes function handles (bulky .mat file)
%   (this didn't happen when using this script as "non"-function...so i have no
%    idea how workspace data are handled with anonymous functions)
% - save relevant info into struct called "setup"
%==============================================================================%
% 08/18/2015
%%
%| group_train = {'HR-', 'LR-'}
%| group_test  = {'LR-', 'HR-'}
group_train = setup.group_train;
group_test  = setup.group_test;

% Number of cv-folds & Number of resampling
opt.K       = setup.K; % #-folds of CV
opt.cv_stratify = setup.cv_stratify;

nvol = setup.nvol;
%% load data
%==============================================================================%
% get data directory
%==============================================================================%
hostname = tak_get_host;

if strcmpi(hostname,'sbia-pc125-cinn') || strcmpi(hostname,'takanori-PC')
    dataPath=[get_rootdir,'/IBIS_',setup.diffusion,'_designMatrix_dsamped_0815_2015'];
else % on cluster computer
    dataPath=[fileparts(pwd),'/data/IBIS_',setup.diffusion,...
        '_designMatrix_dsamped_0815_2015'];
end
invars = {'designMatrix','graph_info','meta_info','session_mask','brain_mask'};
load(dataPath,invars{:})
p = sum(brain_mask(:));
C = graph_info.incidenceMatrix;

%==============================================================================%
% load data and parse relevant info
%==============================================================================%
% find subjects with all 3 scans available
meta_allscans = tak_meta_info_mask(meta_info, session_mask.all_scans);
designAllScans = designMatrix(session_mask.all_scans,:);

n_allscans = length(meta_allscans.id)/3; % divide by 3 since we want # subjects

X = zeros(n_allscans, 3*p);
for isub = 1:n_allscans
    idx_scan1 = 3*(isub-1) + 1;
    idx_scan2 = 3*(isub-1) + 2;
    idx_scan3 = 3*(isub-1) + 3;
    
    scanList{isub,1} = [meta_allscans.lookup{idx_scan1},'-', ...
                        meta_allscans.lookup{idx_scan2},'-', ...
                        meta_allscans.lookup{idx_scan3}];
    assert( isequal( ...
                     meta_allscans.id(idx_scan1),...
                     meta_allscans.id(idx_scan2),...
                     meta_allscans.id(idx_scan3)))
    assert( meta_allscans.session(idx_scan1) == 6  && ...
            meta_allscans.session(idx_scan2) == 12 && ...
            meta_allscans.session(idx_scan3) == 24)
        
    scan1 = designAllScans(idx_scan1,:);
    scan2 = designAllScans(idx_scan2,:);
    scan3 = designAllScans(idx_scan3,:);
    
    idx1 = 1:p;
    idx2 = p+1:2*p;
    idx3 = 2*p+1:3*p;
    
    X(isub,idx1) = scan1;
    X(isub,idx2) = scan2;
    X(isub,idx3) = scan3;
end

%| take the v06 meta-info to remove duplicate 
%| (choice of v06 arbitrary; could  have been v12 or v24)
meta_allscans = tak_meta_info_mask_label(meta_allscans, 'v06');

%==============================================================================%
% break up into gender
%==============================================================================%
[meta_male,mask_male] = tak_meta_info_mask_label(meta_allscans, 'male');
[meta_fema,mask_fema] = tak_meta_info_mask_label(meta_allscans, 'female');

Xp = X(mask_male,:);
Xn = X(mask_fema,:);

% tak_meta_info_summary(meta_male)
% tak_meta_info_summary(meta_fema)
% return

%==============================================================================%
% create subgroups
%==============================================================================%
Xp_start = Xp;
Xn_start = Xn;

[~,mask1]=tak_meta_info_mask_label(meta_male, group_train);
[~,mask2]=tak_meta_info_mask_label(meta_fema, group_train);
[~,mask_test1] = tak_meta_info_mask_label(meta_male, group_test);
[~,mask_test2] = tak_meta_info_mask_label(meta_fema, group_test);

Xp = Xp_start(mask1,:);
Xn = Xn_start(mask2,:);

Xp_ts = Xp_start(mask_test1,:);
Xn_ts = Xn_start(mask_test2,:);

% disp('*** Training groups ***')
% tak_meta_info_summary(meta_male,mask1)
% tak_meta_info_summary(meta_fema,mask2)
yp =  ones(size(Xp,1),1);
yn = -ones(size(Xn,1),1);
X = vertcat(Xp,Xn);
y = vertcat(yp,yn);

% disp('*** Testing groups ***')
% tak_meta_info_summary(meta_male,mask_test1)
% tak_meta_info_summary(meta_fema,mask_test2)
yp_ts =  ones(size(Xp_ts,1),1);
yn_ts = -ones(size(Xn_ts,1),1);
Xts = vertcat(Xp_ts, Xn_ts);
yts = vertcat(yp_ts, yn_ts);
% S_0815_vol_classify_gender_subgroup
%% setup classifier
switch setup.clfmodel
    case 'en'
        %%%%%%% logistic elasticnet %%%%%%%%%%
        opt.training.C   = speye(nvol*p); %C;  %<- elastic-net
        opt.training.maxiter = 400;
        opt.training.tol = 1e-3;
        opt.training.progress = inf;
        opt.training.silence = true;
        opt.training.funcval = false;
        opt.training.num_group = nvol;

        if setup.L21
            opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_group_train(X,y,option);
        else
            opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_train(X,y,option);
        end
        opt.ftest   = @(X,model) tak_clf_linear_model_predict(X,model);  
    case 'gn'
        %%%%%%% logistic graphnet %%%%%%%%%%
        opt.training.C   = kron(eye(nvol),C);

        opt.training.maxiter = 400;
        opt.training.tol = 1e-3;
        opt.training.progress = inf;
        opt.training.silence = true;
        opt.training.funcval = false;
        opt.training.num_group = nvol;

        if setup.L21
            opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_group_train(X,y,option);
        else
            opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_train(X,y,option);
        end
        opt.ftest   = @(X,model) tak_clf_linear_model_predict(X,model);  
    case 'tv'
        %%%%% L2-loss regression with (isotropic) total-variation penalty %%%%%%
        opt.training.maxiter = 400;
        opt.training.tol = 5e-3;
        opt.training.progress = inf;
        opt.training.silence = true;
        opt.training.funcval = false;
        opt.training.over_relax = true;
        opt.training.brain_mask = brain_mask; % <- needed for TV-ADMM-FFT
        opt.training.rho = 100; % <- empirically yields good/ok result

        opt.training.nvol = nvol;
        opt.training.L21 = setup.L21; %<- group-lasso or not

        opt.ftrain  = @(X,y,option) tak_clf_L2loss_TV_group_ADMM_FFT_train(X,y,option);
        opt.ftest   = @(X,model) tak_clf_linear_model_predict(X,model);  
end

disp('*** lamgrid ***')
fprintf('%14.10f\n', setup.lamgrid)
disp('*** gamgrid ***')
fprintf('%14.10f\n', setup.gamgrid)
len_lam = length(setup.lamgrid)
len_gam = length(setup.gamgrid)
%% parse output save info
mFileName = mfilename;
timeStamp = tak_timestamp;
flag_done = false; %| indicates completion status of the script

%| 'iresamp' saved since i save intermediate result every iteration
%%% removed 'opt' which contains anonymous function...which gets ultra-bulky
%%% when saved
outVars = {'flag_done','setup','grid_results','test_results','igam','ilam', ... 
           'aux_info', 'timeStamp', 'mFileName'};  

       
outname = ['VOLdsamp_gender_gridcv_', ...
          group_train,'train_', group_test,'test_',...
          setup.diffusion,'_',setup.clfmodel];
      
if setup.L21
    outname = [outname,'_L21']
else
    outname = [outname,'_L11']
end


%| if zscore is not used, indicate on the output filename
if ~setup.zscore
    outname = strcat('nozscore_',outname);
end

outpath = fullfile(pwd,outname)
% return
%% \======================= setup completed ====================================
% return
%% grid search prep

%% gridsearch run
%==============================================================================%
% Three loops
% (1) iresamp (number of cross-validation repeats)
%    (2) gamma grid (graph/elastic-net penalty)
%        (3) lambda grid (sparsity penalty)
%==============================================================================%
aux_info.rng = 0;
rng(aux_info.rng) % <- for consistent cv sampling for all clfmodel

if setup.zscore
    %| apply zscore on test data (using mean and std-dev of training data)
    [~, Xts] = tak_zscore_Xtr_Xts(X,Xts); 
end

tic
for igam = 1:length(setup.gamgrid)
    if mod(igam,1)==0
        fprintf('%3d out of %3d (%7.2f sec)\n',igam,length(setup.gamgrid),toc);
    end
    opt.training.gam = setup.gamgrid(igam);
    for ilam = 1:length(setup.lamgrid)
        ilam
        opt.training.lam = setup.lamgrid(ilam);
        %======================================================================%
        % train model on entire training set, apply classifier on test set
        %----------------------------------------------------------------------%
        % Ran here since this doesn't require CV
        %======================================================================%
        if setup.zscore
            model = opt.ftrain(zscore(X),y,opt.training);
        else
            model = opt.ftrain(X,y,opt.training);
        end
        score = Xts*model.w;
        ypr   = SIGN(score);
        clf_test_summary = tak_binary_classification_summary(ypr, yts);
        test_results.acc(igam,ilam) = clf_test_summary.accuracy;
        test_results.TPR(igam,ilam) = clf_test_summary.TPR;
        test_results.TNR(igam,ilam) = clf_test_summary.TNR;
        test_results.F1( igam,ilam) = clf_test_summary.F1;
        test_results.PPV(igam,ilam) = clf_test_summary.precision;
        test_results.NPV(igam,ilam) = clf_test_summary.NPV;
        
        [fpr,tpr,~,auc] = perfcurve(yts, score, +1);
        test_results.auc(igam,ilam) = auc;
        test_results.fpr{igam,ilam} = fpr;
        test_results.tpr{igam,ilam} = tpr;
        test_results.sparsity(igam,ilam) = nnz(model.w)/numel(model.w);
        for iresamp = 1:setup.nresamp
            %==================================================================%
            % apply cross-validation on training group
            %==================================================================%
            if setup.zscore
                [clf_summary,cvoutput]= tak_cv_classifier_zscore_internal(X,y,opt);
            else
                [clf_summary,cvoutput]= tak_cv_classifier(X,y,opt);
            end
            grid_results.acc(igam,ilam,iresamp) = clf_summary.accuracy;
            grid_results.TPR(igam,ilam,iresamp) = clf_summary.TPR;
            grid_results.TNR(igam,ilam,iresamp) = clf_summary.TNR;
            grid_results.F1( igam,ilam,iresamp) = clf_summary.F1;
            grid_results.auc(igam,ilam,iresamp) = clf_summary.auc;
            grid_results.PPV(igam,ilam,iresamp) = clf_summary.precision;
            grid_results.NPV(igam,ilam,iresamp) = clf_summary.NPV;
            aux_info.cvoutput{igam,ilam,iresamp} = cvoutput;
        end % <- iresamp
        save(outpath, outVars{:})
    end % <- lamgrid
end % <- gamgrid

flag_done = true;
save(outpath,outVars{:}) 



