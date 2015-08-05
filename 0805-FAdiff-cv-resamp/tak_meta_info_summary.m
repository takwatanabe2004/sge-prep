function tak_meta_info_summary(meta_info, mask)
%% [output_count, rate_count] = tak_meta_info_summary(meta_info, mask)
%==============================================================================%
% Ultra ad-hoc function i created so that i don't have to keep doing below:
%
%         mask = (meta_info.session==24);
%         nsubs = sum(mask)
%         DX = tak_count_unique2(meta_info.DX(mask))
%         session = tak_count_unique2(meta_info.session(mask))
%         gender= tak_count_unique2(meta_info.gender(mask))
%         risk = tak_count_unique2(meta_info.risk(mask))
%         group = tak_count_unique2(meta_info.group(mask))
%
% note i don't return anything, i just do below for display purpose during
% interactive data analysis
%------------------------------------------------------------------------------%
% 07/20/2015
%==============================================================================%
%%
if ~exist('mask','var')||isempty(mask), mask = true(size(meta_info.DX)); end
% disp('====== Data distribution ========')


%% meh, below were not "vertically compact"...so semicolon suppress
% nsubs = sum(mask);
% DX = tak_count_unique2(meta_info.DX(mask));
% session = tak_count_unique2(meta_info.session(mask));
% gender= tak_count_unique2(meta_info.gender(mask));
% risk = tak_count_unique2(meta_info.risk(mask));
% group = tak_count_unique2(meta_info.group(mask));
%%
%% i know the field names, so just print it out via 'fprintf' function
% disp('----------')
% fprintf('(nsubs: %d)  ASD: %d,    TDC: %d, N/A: %d\n', ...
%     nsubs, DX.ASD, DX.Not_ASD, DX.N_A)
% fprintf('(nsubs: %d)  V06: %d,    V12: %d, V24: %d\n', ...
%     nsubs, session.num_6, session.num_12, session.num_24)
% fprintf('(nsubs: %d) Male: %d, Female: %d\n', ...
%     nsubs, gender.Male, gender.Female)
% fprintf('(nsubs: %d)   HR: %d,     LR: %d\n', ...
%     nsubs, risk.HR, risk.LR)
% fprintf('(nsubs: %d)  HR-: %d,    HR+: %d, LR-: %d, LR+: %d\n', ...
%     nsubs, group.HRm, group.HRp, group.LRm, group.LRp)
%%
% keyboard
disp('============================================================')
%%
%| cell-counter
ccnt = @(str,Cell) sum(cell2mat(cellfun(@(x) strcmpi(x,str), ...
       Cell,'UniformOutput',false)));
   
nsubs = sum(mask);
fprintf('                   (#Subjects = %3d)\n', nsubs)

DX = meta_info.DX(mask);
fprintf(' ASD: %3d,    TDC: %3d,                         N/A: %3d\n',...
        ccnt('ASD', DX), ccnt('Not ASD', DX), ccnt('N/A', DX))

gender= meta_info.gender(mask);
fprintf('Male: %3d, Female: %3d,                         N/A: %3d\n',...
        ccnt('Male', gender), ccnt('Female', gender), ccnt('N/A', gender))

    
risk = meta_info.risk(mask);
fprintf('  HR: %3d,     LR: %3d,                         N/A: %3d\n',...
        ccnt('HR', risk), ccnt('LR', risk), ccnt('N/A', risk))

session = meta_info.session(mask);
if isa(session,'cell')
    %| sometimes i convert "session" into cell array.  convert back to double-array
    session = cellfun(@str2double, session);
end
fprintf(' V06: %3d,    V12: %3d,  V24: %3d,              N/A: %3d\n',...
        sum(session==6), sum(session==12), sum(session==24), sum(isnan(session)));

group = meta_info.group(mask);
fprintf(' HR-: %3d,    HR+: %3d,  LR-: %3d,   LR+: %3d,  N/A: %3d\n',...
        ccnt('HR-', group), ccnt('HR+', group), ...
        ccnt('LR-', group), ccnt('LR+', group), ccnt('N/A', group))
%%
disp('============================================================')
%%
% disp('----------')
% fprintf('(nsubs: %3d) Male: %3d,   Fema: %3d\n', ...
%     nsubs, gender.Male, gender.Female)
% fprintf('(nsubs: %3d)  ASD: %3d,    TDC: %3d,   N/A: %3d\n', ...
%     nsubs, DX.ASD, DX.Not_ASD, DX.N_A)
% fprintf('(nsubs: %3d)  V06: %3d,    V12: %3d,   V24: %3d\n', ...
%     nsubs, session.num_6, session.num_12, session.num_24)
% fprintf('(nsubs: %3d)   HR: %3d,     LR: %3d\n', ...
%     nsubs, risk.HR, risk.LR)
% fprintf('(nsubs: %3d)  HR-: %3d,    HR+: %3d,   LR-: %3d,   LR+: %d,   N/A: %d\n', ...
%     nsubs, group.HRm, group.HRp, group.LRm, group.LRp, group.N_A)