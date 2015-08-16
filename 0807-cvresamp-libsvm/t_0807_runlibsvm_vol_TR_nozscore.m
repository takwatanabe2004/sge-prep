clear
% 5 * 3 = 15 loops

setup.clfmodel= 'libsvm';
setup.nresamp= 5;
setup.K = 15;
setup.lamgrid = 2.^[-10:3:20];  % C value in SVM
setup.gamgrid = 2.^[-15:3:35]  % RBF kernel

diffList = {'TR'}; % 1

groupList = {'DX', 'HRpLRm', 'HRpHRm', 'risk', 'gender'} % 5
genderList= {'male','male',  'male',   'male',  ''};


%| setup "session" option list
setup.diff  = false;
sessionList = {'v06', 'v12', 'v24'};

zscoreList = [false]; % 1

for dozscore = zscoreList
    setup.zscore = dozscore;
    for diffusion = diffList
        setup.diffusion = diffusion{:};
        for ii = 1:length(groupList)
            setup.group = groupList{ii};
            setup.gender = genderList{ii};
            for session = sessionList
                setup.session = session{:}
                trun_0807_bal_gridsearch_cvresamp_libsvm_vol(setup)
            end
        end
    end
end