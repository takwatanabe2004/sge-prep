clear
diffList = {'FA','TR'}; % 2 
setup.diff  = true; 
groupList = {'DX', 'HRpLRm', 'HRpHRm', 'risk', 'gender'} % 
genderList= {'male','male',  'male',   'male',  ''};
clfList =  {'liblinL1', 'liblinL2'};
time2List = {'v12', 'v24', 'v24'};
time1List = {'v06', 'v06', 'v12'};



zscoreList = [true, false];
for dozscore = zscoreList
    setup.zscore = dozscore;
    for classifier = clfList
        setup.clfmodel = classifier{:};
        for diffusion = diffList
            setup.diffusion = diffusion{:};
            for ii = 1:length(groupList)
                setup.group = groupList{ii};
                setup.gender = genderList{ii};
                for it = 1:length(time2List)
                    setup.time2 = time2List{it};
                    setup.time1 = time1List{it}
                    trun_0807_bal_gridsearch_vol_cv_resamp_liblin_fcn_diff(setup)
                end
            end
        end
    end
end