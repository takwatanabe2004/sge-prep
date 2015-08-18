function [X, fvol] = ibis_get_all_vol_design_0818
%% [X, fvol, meta_info, session_mask,brain_mask] = ibis_get_all_vol_design_0818
%==============================================================================%
% Create design matrix containing 
%------------------------------------------------------------------------------%
%==============================================================================%
% 08/18/2015
%%
hostname = tak_get_host;

if strcmpi(hostname,'sbia-pc125-cinn') || strcmpi(hostname,'takanori-PC')
    dataPath=get_rootdir;
else % on cluster computer
    dataPath=[fileparts(pwd),'/data'];
end

invars = {'designMatrix','graph_info'};

filePath.FA=[dataPath,'/IBIS_FA_designMatrix_dsamped_0815_2015'];
filePath.TR=[dataPath,'/IBIS_TR_designMatrix_dsamped_0815_2015'];
filePath.AX=[dataPath,'/IBIS_AX_designMatrix_dsamped_0815_2015'];
filePath.RD=[dataPath,'/IBIS_RD_designMatrix_dsamped_0815_2015'];

% load('IBIS_FA_designMatrix_dsamped_0815_2015.mat',invars{:})
load(filePath.FA,invars{:})
design_FA = designMatrix;
clear designMatrix

[n,p] = size(design_FA);
X = zeros(n, 4*p);
X(:,1:p) = design_FA;

% TR (note: iused to think struct2array takes long time, but not so bad here
design_TR = struct2array(load(filePath.TR,'designMatrix'));
X(:,p+1:2*p) = design_TR;

% AX
design_AX = struct2array(load(filePath.AX,'designMatrix'));
X(:,2*p+1:3*p) = design_AX;

% RD
design_RD = struct2array(load(filePath.RD,'designMatrix'));
X(:,3*p+1:4*p) = design_RD;


%| function handle that'll reshape each data points (rows) into volume
fvol.FA = @(x) reshape(graph_info.augmentMatrix*vec(x(1:p)), graph_info.size);
fvol.TR = @(x) reshape(graph_info.augmentMatrix*vec(x(p+1:2*p)), graph_info.size);
fvol.AX = @(x) reshape(graph_info.augmentMatrix*vec(x(2*p+1:3*p)),graph_info.size);
fvol.RD = @(x) reshape(graph_info.augmentMatrix*vec(x(3*p+1:4*p)),graph_info.size);
%%
% keyboard
% %%
% X2 = vertcat(