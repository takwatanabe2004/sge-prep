%% t_0818_vol_dsamp_gender_2d_gridsearch_cvresamp_pooled_modalities
clear
close all
drawnow

setup.clfmodel = 'gn'; % {'en','gn','tv'}
setup.diffusion = 'FA'; % {'FA', 'TR','AX', 'RD'}
setup.L21 = false; % {true,false}
setup.nvol=3;

train_groupList = {'HR-','LR-'};
test_groupList  = {'LR-','HR-'};

setup.K = 10; % <- #-cv folds
setup.nresamp = 5; % <- number of time to repeat CV
setup.zscore = true;
setup.cv_stratify = true;

% e-net/g-net range (august16)
if strcmpi(setup.clfmodel, 'elnet') || strcmpi(setup.clfmodel','grnet')
    setup.lamgrid = 2.^[-16:0.5:-1]; % L1
    setup.gamgrid = 2.^[-20:2:8]; % L2 or spatial penalty
else
    % flas/isotv range (august16)
    setup.lamgrid = 2.^[-16:0.5:-1]; % L1
    setup.gamgrid = 2.^[-16:0.5:0]; % L2 or spatial penalty
end
% setup.lamgrid = 2.^[-15:1:-14]; % L1
% setup.gamgrid = 2.^[-15:1:-13]; % L2 or spatial penalt

% zscoreList = [true, false];

for ii = 1:length(train_groupList)
    setup.group_train = train_groupList{ii};
    setup.group_test = test_groupList{ii};
    trun_0818_vol_gender_2d_grid_cvresamp_pooled_sess(setup);
end