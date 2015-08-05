function meta_info_masked = tak_meta_info_mask(meta_info, mask)
%% meta_info_masked = tak_meta_info_mask(meta_info, mask)
%==============================================================================%
% Apply masking on the 'meta_info' struct variable i rely on oh so frequently
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
% 07/21/2015
%==============================================================================%
%%
meta_info_masked.id      = meta_info.id(mask);
meta_info_masked.lookup  = meta_info.lookup(mask);
meta_info_masked.age     = meta_info.age(mask);
meta_info_masked.session = meta_info.session(mask);
meta_info_masked.gender  = meta_info.gender(mask);
meta_info_masked.DX      = meta_info.DX(mask);
meta_info_masked.risk    = meta_info.risk(mask);
meta_info_masked.group   = meta_info.group(mask);