clear all
cwd=pwd
datapath = strcat(fileparts(cwd),'/data/timeNow.mat')
load(datapath)
outpath = strcat(cwd,'/yes.mat')
save(outpath, 'time')