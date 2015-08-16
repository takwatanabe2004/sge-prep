%% 08/09/2015
% - i forgot to remove 'opt' from the list of variables to save...
% - remove 'opt' for each output files
%%
clear
fileList = dir(  fullfile(pwd,'**.mat') );
fileList = {fileList.name}';

for ifile = 1:length(fileList)
    fname = fileList{ifile}
    try 
        load(fname)
    catch
        warning('Couldn''t load %s',fname)
        continue
    end
        
    clear opt
    save(fname)
%     return
end
