clear

time = tak_timestamp;
[~,cwd] = system('pwd')
outpath = strcat(cwd,'/timeNow')
% outpath = ['/cbica/home/watanabt/vol_clf_ibis/timeNow']
save(outpath,'time')