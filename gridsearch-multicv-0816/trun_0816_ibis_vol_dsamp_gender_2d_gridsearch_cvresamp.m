function trun_0816_ibis_vol_dsamp_gender_2d_gridsearch_cvresamp(setup)
%==============================================================================%
% Classify 
% 
% Code based on t_0815_vol_classify_gender_subgroup.m
%------------------------------------------------------------------------------%
% Do gridsearch via K-fold-CV...repeat multiple times with different subsamples
% 
% Note: don't save struct that includes function handles (bulky .mat file)
%   (this didn't happen when using this script as "non"-function...so i have no
%    idea how workspace data are handled with anonymous functions)
% - save relevant info into struct called "setup"
%==============================================================================%
% 08/16/2015
%%
%| group_train = {'HR-', 'LR-'}
%| group_test  = {'LR-', 'HR-'}
group_train = setup.group_train;
group_test  = setup.group_test;

% Number of cv-folds & Number of resampling
opt.K       = setup.K; % #-folds of CV
opt.cv_stratify = setup.cv_stratify;
%% load data
%==============================================================================%
% get data directory
%==============================================================================%
hostname = tak_get_host;

if strcmpi(hostname,'sbia-pc125-cinn') || strcmpi(hostname(1:8),'takanori')
    dataPath=[get_rootdir,'/IBIS_',setup.diffusion,...
              '_designMatrix_dsamped_0815_2015'];
else % on cluster computer
    dataPath=[fileparts(pwd),'/data/IBIS_',setup.diffusion,...
              '_designMatrix_dsamped_0815_2015'];
end

%==============================================================================%
% load data and parse relevant info
%==============================================================================%
invars = {'designMatrix','graph_info','meta_info','session_mask','brain_mask'};
load(dataPath,invars{:})
C = graph_info.incidenceMatrix;
p = size(C,2);

%==============================================================================%
% construct feature matrix with the setup specified above
%==============================================================================%
%| break up data into gender
%| Xp = (np x p) design matrix of male
%| Xn = (nn x p) design matrix of female
[Xp, Xn, meta_info_group] = tak_get_two_groups_ibis(designMatrix, ...
                                         meta_info, 'gender','', setup.session);

meta_info_male = dataset(meta_info_group.group1);
meta_info_fema = dataset(meta_info_group.group2);
% tak_meta_info_summary(meta_info_group1)
% tak_meta_info_summary(meta_info_group2)
%% create subgroups based on risk status (LR- or HR-)
Xp_start = Xp;
Xn_start = Xn;

[~,mask_male_tr]=tak_meta_info_mask_label(meta_info_male, group_train);
[~,mask_fema_tr]=tak_meta_info_mask_label(meta_info_fema, group_train);
[~,mask_male_ts] = tak_meta_info_mask_label(meta_info_male, group_test);
[~,mask_fema_ts] = tak_meta_info_mask_label(meta_info_fema, group_test);

Xp = Xp_start(mask_male_tr,:);
Xn = Xn_start(mask_fema_tr,:);

Xp_ts = Xp_start(mask_male_ts,:);
Xn_ts = Xn_start(mask_fema_ts,:);

disp('*** Training groups ***')
aux_info.meta_male_train = tak_meta_info_mask(meta_info_male,mask_male_tr);
aux_info.meta_fema_train = tak_meta_info_mask(meta_info_fema,mask_fema_tr);
tak_meta_info_summary(aux_info.meta_male_train)
tak_meta_info_summary(aux_info.meta_fema_train)
yp =  ones(size(Xp,1),1);
yn = -ones(size(Xn,1),1);
X = vertcat(Xp,Xn);
y = vertcat(yp,yn);

disp('*** Testing groups ***')
aux_info.meta_male_test = tak_meta_info_mask(meta_info_male,mask_male_ts);
aux_info.meta_fema_test = tak_meta_info_mask(meta_info_fema,mask_fema_ts);
tak_meta_info_summary(aux_info.meta_male_test)
tak_meta_info_summary(aux_info.meta_fema_test)
yp_ts =  ones(size(Xp_ts,1),1);
yn_ts = -ones(size(Xn_ts,1),1);
Xts = vertcat(Xp_ts, Xn_ts);
yts = vertcat(yp_ts, yn_ts);
%% setup classifier
switch setup.clfmodel
    case 'elnet'
        %%%%%%% logistic elasticnet %%%%%%%%%%
        opt.training.C   = speye(p); %C;  %<- elastic-net
        opt.training.maxiter = 400;
        opt.training.tol = 1e-3;
        opt.training.progress = inf;
        opt.training.silence = true;
        opt.training.funcval = false;

        opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_train(X,y,option);
        opt.ftest   = @(X,model) tak_clf_linear_model_predict(X,model);  
    case 'grnet'
        %%%%%%% logistic graphnet %%%%%%%%%%
        opt.training.C   = C;

        opt.training.maxiter = 400;
        opt.training.tol = 1e-3;
        opt.training.progress = inf;
        opt.training.silence = true;
        opt.training.funcval = false;

        opt.ftrain = @(X,y,option) tak_clf_logistic_graphnet_train(X,y,option);
        opt.ftest   = @(X,model) tak_clf_linear_model_predict(X,model);  
    case 'flass'
        %%%%% L2-loss regression with fused lasso penalty %%%%%%
        opt.training.maxiter = 400;
        opt.training.tol = 5e-3;
        opt.training.progress = inf;
        opt.training.silence = true;
        opt.training.funcval = false;
        opt.training.over_relax = true;
        opt.training.brain_mask = brain_mask; % <- needed for FL-ADMM-FFT
        opt.training.rho = 100; % <- empirically yields good/ok result

        opt.ftrain  = @(X,y,option) tak_clf_L2loss_FL_ADMM_FFT_train(X,y,option);
        opt.ftest   = @(X,model) tak_clf_linear_model_predict(X,model);  
    case 'isotv'
        %%%%% L2-loss regression with (isotropic) total-variation penalty %%%%%%
        opt.training.maxiter = 400;
        opt.training.tol = 5e-3;
        opt.training.progress = inf;
        opt.training.silence = true;
        opt.training.funcval = false;
        opt.training.over_relax = true;
        opt.training.brain_mask = brain_mask; % <- needed for TV-ADMM-FFT
        opt.training.rho = 100; % <- empirically yields good/ok result

        opt.ftrain  = @(X,y,option) tak_clf_L2loss_TV_ADMM_FFT_train(X,y,option);
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

outname = ['VOLdsamp_gender_gridcv_', setup.diffusion,setup.session,'_',...
            setup.clfmodel,'_', group_train,'train_', group_test,'test']

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



