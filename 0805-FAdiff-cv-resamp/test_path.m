%% tw_bal_gridsearch_vol_15cv_15resamp.m
%==============================================================================%
% Do gridsearch via 15-fold-CV...repeat 15times with different subsampling.
%------------------------------------------------------------------------------%
% - Use the "diff" features of FA/TR volumes to classify
%==============================================================================%
% 08/05/2015
%%
clear all; 
purge;

%| show label distribution of the two groups of interest
flag_print_labeldistr = false;
%% setup
% diffusionType = 'FA'; % {'FA', 'TR'}
diffusionType = 'TR'; % {'FA', 'TR'}tw_

%==============================================================================%
% Select the two time-points for taking the "diff" over
% (time2 > time1 required convention for consistency)
%------------------------------------------------------------------------------%
% time1, time2 = 'v06', 'v12', or 'v24'
%==============================================================================%
time2 = 'v12';
time1 = 'v06';

%==============================================================================%
% choose the group of interest (optional: also mask by gender)
%==============================================================================%
group = 'Risk'; %{'DX', 'HRpLRm', 'HRpHRm', 'Risk', 'Gender'}
gender = 'male';  %{'male','female', ''}

%==============================================================================%
% skip zscore trasnformation? (may drop this option in the future)
% (my default has been to apply zscore, hence the awkward flag-name here)
%==============================================================================%
flag_skip_zscore = false;

%==============================================================================%
% graphnet or elastic net?
%==============================================================================%
opt.pen = 'enet'; % {'gnet', 'enet'}

%==============================================================================%
% Number of cv-folds & Number of resampling
%==============================================================================%
opt.K = 15;       % <- 20-fold CV
opt.nresamp = 15; % <- 10 resampling

%==============================================================================%
% gridsearch range
%==============================================================================%
opt.lamgrid = 2.^[-14:-2];   % sparsity penalty
opt.gamgrid = 2.^[-22:2:8];  % spatial  penalty
% opt.lamgrid = 2.^[-14:5:-2];   % sparsity penalty
% opt.gamgrid = 2.^[-22:9:8];  % spatial  penalty
disp('*** lamgrid ***')
fprintf('%14.10f\n', opt.lamgrid)
disp('*** gamgrid ***')
fprintf('%14.10f\n', opt.gamgrid)
len_lam = length(opt.lamgrid)
len_gam = length(opt.gamgrid)
% return
%% variables and path to save
mFileName = mfilename;
timeStamp = tak_timestamp;
flag_done = false; %| indicates completion status of the script

%| 'iresamp' saved since i save intermediate result every iteration
outVars = {'iresamp','flag_done','grid_results', ...
           'aux_info','opt', 'timeStamp', 'mFileName'}; 

cwd = pwd; 
outname=['test']

%| if nozscore flag is on, indicate on the output filename
if flag_skip_zscore
    outname = strcat('nozscore_',outname);
end

%%% regexp cleanup to ensure output-name is a valid filename %%%%
outpath = fullfile(cwd,outname)

save(outpath,'flag_done')