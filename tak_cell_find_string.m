function handle=tak_cell_find_string(str,Cell)
%==============================================================================%
% Return binary mask of Cell-indices containing string 'str' (case insensitive)
%
% Useful to use it as a function handle
% >>  fmask = @(str,Cell) tak_cell_find_string(str,Cell);
%------------------------------------------------------------------------------%
% 07/10/2015'ish (not exactly sure when first created...)
%==============================================================================%
%%
handle = cell2mat(  cellfun(@(x) strcmpi(x,str), Cell,'UniformOutput',false)   );