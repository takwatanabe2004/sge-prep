function trun_0818_vol_gender_2d_grid_cvresamp_pooled_modes(setup)
%==============================================================================%
% Classify 
% 
% Code based on t_0818_vol_classify_gender_subgroup_group_lasso_modalities.m
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
    dataPath=[get_rootdir,'/IBIS_FA_designMatrix_dsamped_0815_2015'];
else % on cluster computer
    dataPath=[fileparts(pwd),'/data/IBIS_FA_designMatrix_dsamped_0815_2015'];
end
invars = {'graph_info','meta_info','session_mask','brain_mask'};
load(dataPath,invars{:})
C = graph_info.incidenceMatrix;
%==============================================================================%
% load data and parse relevant info
%==============================================================================%
nvol = 4;
[X] = ibis_get_all_vol_design_0818;
p = size(X,2)/nvol;

%==============================================================================%
% break up into gender
%==============================================================================%
[meta_male,mask_male] = tak_meta_info_mask_label(meta_info, 'male', setup.session);
[meta_fema,mask_fema] = tak_meta_info_mask_label(meta_info, 'female',setup.session);

Xmale = X(mask_male,:);
Xfema = X(mask_fema,:);

%==============================================================================%
% create subgroups
%==============================================================================%
[~,mask1]=tak_meta_info_mask_label(meta_male, group_train);
[~,mask2]=tak_meta_info_mask_label(meta_fema, group_train);
[~,mask_test1] = tak_meta_info_mask_label(meta_male, group_test);
[~,mask_test2] = tak_meta_info_mask_label(meta_fema, group_test);

Xp = Xmale(mask1,:);
Xn = Xfema(mask2,:);

Xp_ts = Xmale(mask_test1,:);
Xn_ts = Xfema(mask_test2,:);

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
          setup.session,'_',setup.clfmodel];
      
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



