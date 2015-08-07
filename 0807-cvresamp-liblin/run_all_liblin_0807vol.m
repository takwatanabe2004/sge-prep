clear
diffList = {'FA','TR'};
setup.diff = false;
groupList = {'DX', 'HRpLRm', 'HRpHRm', 'risk', 'gender'}
genderList= {'male','male',  'male',   'male',  ''};
clfList =  {'liblinL1', 'liblinL2'};
sessionList = {'v06', 'v12', 'v24'};




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
                for session = sessionList
                    setup.session = session{:}
                    tw_0807_bal_gridsearch_vol_cv_resamp_liblin_fcn_vol(setup)
                end
            end
        end
    end
end