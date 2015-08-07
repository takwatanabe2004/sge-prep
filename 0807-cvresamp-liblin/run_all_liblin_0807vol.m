clear
% 2*5*2*3*2 = 10 * 12 = 120
diffList = {'FA','TR'}; % 2
setup.diff = false;
groupList = {'DX', 'HRpLRm', 'HRpHRm', 'risk', 'gender'}
genderList= {'male','male',  'male',   'male',  ''}; % 5
clfList =  {'liblinL1', 'liblinL2'}; % 2
sessionList = {'v06', 'v12', 'v24'}; % 3
zscoreList = [true, false]; % 2

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
                    trun_0807_bal_gridsearch_vol_cv_resamp_liblin_fcn_vol(setup)
                end
            end
        end
    end
end