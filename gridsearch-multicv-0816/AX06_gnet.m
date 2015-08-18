%% t_0816_ibis_vol_dsamp_gender_2d_gridsearch_cvresamp
clear
close all
drawnow

diffusionList = {'AX'}; % {'FA','TR','AX','RD'};
sessionList = {'v06'}; %{'v06', 'v12', 'v24'};
setup.clfmodel = 'grnet'; % {'elnet','grnet','flass','isotv'}

train_groupList = {'HR-','LR-'};
test_groupList  = {'LR-','HR-'};

setup.K = 5; % <- #-cv folds
setup.nresamp = 5; % <- number of time to repeat CV
setup.zscore = true;
setup.cv_stratify = true;

% e-net/g-net range (august16)
if strcmpi(setup.clfmodel, 'elnet') || strcmpi(setup.clfmodel','grnet')
    setup.lamgrid = 2.^[-16:1:-1]; % L1
    setup.gamgrid = 2.^[-16:1:4]; % L2 or spatial penalty
else
    % flas/isotv range (august16)
    setup.lamgrid = 2.^[-16:1:-1]; % L1
    setup.gamgrid = 2.^[-16:0.5:-4]; % L2 or spatial penalty
end

% zscoreList = [true, false];
for diffusion = diffusionList
    setup.diffusion = diffusion{:};
    for session = sessionList
        setup.session = session{:};
        for ii = 1:length(train_groupList)
            setup.group_train = train_groupList{ii};
            setup.group_test = test_groupList{ii};
            trun_0816_ibis_vol_dsamp_gender_2d_gridsearch_cvresamp(setup);
        end
    end
end