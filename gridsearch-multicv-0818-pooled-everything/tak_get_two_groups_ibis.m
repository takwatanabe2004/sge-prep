function [Xgroup1,Xgroup2,meta_info_group, mask] = ...
    tak_get_two_groups_ibis(X, meta_info, group, gender,session)
% [Xgroup1,Xgroup2,meta_info_group, mask] = ...
%                   tak_get_two_groups_ibis(X, meta_info, group, gender,session)
%==============================================================================%
% Update: 08/05/2015
% - the "upper" function does always not seem to work on the SGE submission...
%   (learned this the hard way)
% - thus changed the case statement with brute force option selections
%==============================================================================%
% Create "diff" features using two time points: time2 and time1 (time2 > time1)
%
% group = one of the following: {'DX', 'HR+LR-', 'HR+HR-', 'risk', 'gender'}
%           DX:  ASD vs  TDI
%       HR+LR-:  HR+ vs  LR-
%       HR+HR-:  HR+ vs  HR-
%         risk:  HR  vs  LR
%       gender: male vs female
%
% gender (optional): 'male', 'female', or [] (blank)
%   - some analysis, we want to only look at male (ASD mostly male)
%   - if group = 'gender', than this argument wouldn't make any sense
%
% session (optional): 'v06', 'v12', 'v24', or [] (blank)
%   - mask for taking a cross-section of time point
%   - not needed if using "diff" features
%------------------------------------------------------------------------------%
% meta_info = 
%     fileList: {968x1 cell}
%           id: [968x1 double]
%      session: [968x1 double]
%       lookup: {968x1 cell}
%          age: [968x1 double]
%       gender: {968x1 cell}
%           DX: {968x1 cell}
%         risk: {968x1 cell}
%        group: {968x1 cell}
%------------------------------------------------------------------------------%                                           
%==============================================================================%
% 08/04/2015   
%%
%| function handle for finding string in a cell array
fmask = @(str,Cell) tak_cell_find_string(str,Cell);

%==============================================================================%
% parse optional 'gender' argument
% - if empty, than "mask_gender" will be a mask of all "true"
%   (so the mask being applied subsequently has no impact)
%==============================================================================%
if exist('gender','var') && ~isempty(gender)
    switch lower(gender)
        case {'male','female'}
            mask_gender = fmask(gender, meta_info.gender);
        otherwise
            error('''Gender'' argument error')
    end
else
    % 3rd argument not given, so create mask-vector of all "true"
    mask_gender = true( length(meta_info.lookup), 1);
end

%==============================================================================%
% parse optional 'session' argument
% - if empty, than "mask_session" will be a mask of all "true"
%   (so the mask being applied subsequently has no impact)
%==============================================================================%
if exist('session','var') && ~isempty(session)
    switch lower(session)
        case {'v06','06', 6}
            mask_session = meta_info.session == 6;
        case {'v12','12', 12}
            mask_session = meta_info.session == 12;
        case {'v24','24', 24}
            mask_session = meta_info.session == 24;
        otherwise
            error('''Session'' argument error')
    end
else
    % 3rd argument not given, so create mask-vector of all "true"
    mask_session = true( length(meta_info.lookup), 1);
end
premask  = mask_gender & mask_session;

switch group
    case {'DX', 'Dx', 'dx'}
        mask.group1 = fmask('ASD',meta_info.DX) & premask;
        mask.group2 = fmask('Not ASD',meta_info.DX) & premask;
    case {'RISK', 'risk', 'Risk'}
        mask.group1 = fmask('HR',meta_info.risk) & premask;
        mask.group2 = fmask('LR',meta_info.risk) & premask;
    case {'HR+LR-', 'HRPLRP', 'HRpLRm'}
        mask.group1 = fmask('HR+',meta_info.group) & premask;
        mask.group2 = fmask('LR-',meta_info.group) & premask;
    case {'HR+HR-', 'HRPHRM', 'HRpHRm'}
        mask.group1 = fmask('HR+',meta_info.group) & premask;
        mask.group2 = fmask('HR-',meta_info.group) & premask;
    case {'GENDER','gender','Gender'}
        mask.group1 = fmask(  'male', meta_info.gender) & premask;
        mask.group2 = fmask('female', meta_info.gender) & premask;
    otherwise
        error('''%s'' an unrecognized group',group)
end
% keyboard
mask.group = mask.group1 | mask.group2;

meta_info_group.group1 = tak_meta_info_mask(meta_info, mask.group1);
meta_info_group.group2 = tak_meta_info_mask(meta_info, mask.group2);
%%
%| first group: set as "positive" class
Xgroup1 = X(mask.group1,:);
Xgroup2 = X(mask.group2,:);