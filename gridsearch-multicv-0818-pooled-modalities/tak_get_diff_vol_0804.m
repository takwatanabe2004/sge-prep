function [Xdiff,meta_info_diff, diff_info] = ...
    tak_get_diff_vol_0804(X,meta_info,session_mask,time1, time2)
%% [session_info, session_count, session_mask] = tak_get_session_info(lookup)
%==============================================================================%
% Create "diff" features using two time points: time2 and time1 (time2 > time1)
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
% 
% session_mask = 
%        lookup: {968x1 cell}
%            id: [968x1 double]
%       session: [968x1 double]
%     all_scans: [968x1 logical]
%           v24: [968x1 logical]
%           v12: [968x1 logical]
%           v06: [968x1 logical]
%       v24_v12: [968x1 logical]
%       v24_v06: [968x1 logical]
%       v12_v06: [968x1 logical]
%------------------------------------------------------------------------------%
% Script based on t_0803_FAdiff_classify.m                                                               
%==============================================================================%
% 08/04/2015   
%%
p = size(X,2);

%| sesssion_count: struct containing "counts" of available scans/sessions
[~, sesssion_count] = tak_get_session_info(meta_info);
%%
assert( str2num(time2(2:3)) > str2num(time1(2:3)), 'Requirement: Time2 > Time1')
time_diff = strjoin({time2,time1},'_');

%| #subjects who has scans at both time1 & time2
nsubj =   sesssion_count.(time_diff);

%| since "lookups" are ordered, time1, time2 should be interleaved after masking
mask.session = session_mask.(time_diff);
Xtmp = X(mask.session,:); 



%| the "diff" features
Xdiff = zeros(nsubj,p);

%%%% aux_info: for sanity checks %%%%
%| diffList = "lookup" (lookup = "SUBID + SESSION")
%| fileList = filenames
lookup   = meta_info.lookup(mask.session);
fileList = meta_info.fileList(mask.session);

diff_info.lookupList = cell(nsubj,1);
diff_info.fileList   = cell(nsubj,1);
for i = 1:nsubj
    ii = 1 + 2*(i-1);
    Xdiff(i,:) = Xtmp(ii+1,:) - Xtmp(ii,:);
    diff_info.lookupList{i,1} = [  lookup{ii+1},' - ',   lookup{ii}];
    diff_info.fileList{i,1}   = [fileList{ii+1},' - ', fileList{ii}];

    %==========================================================================%
    % assertion test to ensure i'm taking the "diff" of the right data
    %==========================================================================%
    %| are we looking at the same subject?  check subject IDs
    test1 = isequal(lookup{ii}(1:6), lookup{ii+1}(1:6));
    
    %| check for time points
    test2 = strcmpi(lookup{ii+1}(9:10), num2str(time2(2:3))  );
    test3 = strcmpi(lookup{ii}(9:10),   num2str(time1(2:3))  );
    
    %| test assertion
    assert( test1 &&  test2 && test3 )
end
%%
%| get "meta_info" for our diff features
meta_info_diff = tak_meta_info_mask(meta_info,mask.session);

%| 2nd mask to get "every other" scans 
%| (these should be time2 scans as i'm taking even indices here)
mask_even = false(2*nsubj,1);
mask_even(2:2:2*nsubj) = true;

meta_info_diff = tak_meta_info_mask(meta_info_diff, mask_even);