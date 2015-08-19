function [meta_info_masked,mask] = tak_meta_info_mask_label(meta_info, varargin)
%% meta_info_masked = tak_meta_info_mask_label(meta_info, mask)
%==============================================================================%
% Update 08/12/2015 - also return the mask as optional output
%------------------------------------------------------------------------------%
% Same as tak_meta_info_mask, but instead of providing "mask", inputs
% are given by "labels", which gets converted into a mask internally
% 
%     meta_info = 
%              id: [962x1 double]
%          lookup: {962x1 cell}
%             age: [962x1 double]
%         session: [962x1 double]
%          gender: {962x1 cell}
%              DX: {962x1 cell}
%            risk: {962x1 cell}
%           group: {962x1 cell}
%------------------------------------------------------------------------------%
% Example usage:
%    meta_info_maksed = tak_meta_info_mask_label(meta_info,'male',24)
%------------------------------------------------------------------------------%
% 07/31/2015
%==============================================================================%
%%
if nargin < 2
    error('Include label-list in order to create mask')
end

mask = true( length(meta_info.lookup), 1);
fmask = @(str,Cell) tak_cell_find_string(str,Cell);

for i = 1:length(varargin)
    label = varargin{i};
    
    if isa(label,'char')
        % for case insensitivity, convert to lower-case
        label = lower(label);
    end
    switch label
        case {6,12,24}
            mask = mask & (meta_info.session == label);
        case {'v06', 'V06'}
            mask = mask & (meta_info.session == 6);
        case {'v12', 'V12'}
            mask = mask & (meta_info.session == 12);
        case {'v24', 'V24'}
            mask = mask & (meta_info.session == 24);
        case {'male', 'female'}
            mask = mask & fmask(label, meta_info.gender);
        case {'asd', 'not asd'}
            mask = mask & fmask(label, meta_info.DX);
        case {'hr', 'lr'}
            mask = mask & fmask(label, meta_info.risk);
        case {'hr+', 'hr-','lr+','lr-'}
            mask = mask & fmask(label, meta_info.group);
        otherwise
            error('submitted label-mask [''%s''] unrecognized',label)
    end
end

meta_info_masked.id      = meta_info.id(mask);
meta_info_masked.lookup  = meta_info.lookup(mask);
meta_info_masked.age     = meta_info.age(mask);
meta_info_masked.session = meta_info.session(mask);
meta_info_masked.gender  = meta_info.gender(mask);
meta_info_masked.DX      = meta_info.DX(mask);
meta_info_masked.risk    = meta_info.risk(mask);
meta_info_masked.group   = meta_info.group(mask);