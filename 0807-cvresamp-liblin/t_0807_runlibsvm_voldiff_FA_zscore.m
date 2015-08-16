clear
% 5 * 3 = 15 loops

setup.clfmodel= 'libsvm';
setup.nresamp= 5;
setup.K = 15;
setup.lamgrid = 2.^[-10:3:20];  % C value in SVM
setup.gamgrid = 2.^[-15:3:35]  % RBF kernel

diffList = {'FA'}; % 1

groupList = {'DX', 'HRpLRm', 'HRpHRm', 'risk', 'gender'} % 5
genderList= {'male','male',  'male',   'male',  ''};


%| setup "diff" option list
setup.diff  = true;
time2List = {'v12', 'v24', 'v24'}; % 3
time1List = {'v06', 'v06', 'v12'};


zscoreList = [true]; 

for dozscore = zscoreList
    setup.zscore = dozscore;
    for diffusion = diffList
        setup.diffusion = diffusion{:};
        for ii = 1:length(groupList)
            setup.group = groupList{ii};
            setup.gender = genderList{ii};
            for it = 1:length(time2List)
                setup.time2 = time2List{it};
                setup.time1 = time1List{it}
                trun_0807_bal_gridsearch_cvresamp_libsvm_vol(setup)
            end
        end
    end
end