function [session_info, session_count, session_mask] = tak_get_session_info(meta_info)
%% [session_info, session_count, session_mask] = tak_get_session_info(lookup)
%==============================================================================%
% Update 07/21/2015
% - decided not to save "session_info" as "dataset"...
% - Why?  Going from struct to dataset is simple, but not easily reversible
%  (hard to go from 'dataset' format to 'struct' format)
% - More importantly, in 'dataset', i've found you cannot access field names
%   via variable such as VAR.(varname)
%------------------------------------------------------------------------------%
% lookup: (nscans x 1) cell-array containing string of "subjectID+session#"   
%                                                       (ex: '103430_V06')    
%                                                                             
% session_info:  (nsubs  x 9) "dataset" containing subject id and session mask
%                (first column = id)                                          
% session_mask:  (nscans x 10) "dataset" containing "session masks"           
%                (first three columns = "lookup", "id", "session")            
% session_count: struct containing "counts" of available scans                
%------------------------------------------------------------------------------%
% 07/20/2015                                                                  
%==============================================================================%
% id_list = cell2mat(cellfun(@(x) str2double(x(1:6)), lookup,'UniformOutput',false)); 
% session = cell2mat(cellfun(@(x) str2double(x(9:10)),lookup,'UniformOutput',false));
id_list = meta_info.id;
session = meta_info.session;

%| note: above id has some repetition; 
[session_info.id, count]=tak_count_unique(id_list);
nsubs = length(session_info.id);

session_info.DX     = cell(nsubs,1);
session_info.risk   = cell(nsubs,1);
session_info.group  = cell(nsubs,1);
session_info.gender = cell(nsubs,1);

session_info.count = count;

%| mask of subjets with all 3 scans
session_info.all_scans = (session_info.count==3);

session_info.v24 = false(nsubs,1);
session_info.v12 = false(nsubs,1);
session_info.v06 = false(nsubs,1);
% keyboard
% tic
for idx_sub = 1:length(session_info.id)
    subject = session_info.id(idx_sub);
    
    %| find rows/scans correspondings to subject isub
    mask_isub = (id_list == subject);
    
    %| list of sessions corresponding to subject isub
    sessions = session(mask_isub);
    
%     keyboard
    %| if 'unique' below spits out more than 1 type, something is wrong
    session_info.DX(idx_sub)     = unique(meta_info.DX(mask_isub));
    session_info.risk(idx_sub)   = unique(meta_info.risk(mask_isub));
    session_info.group(idx_sub)  = unique(meta_info.group(mask_isub));
    session_info.gender(idx_sub) = unique(meta_info.gender(mask_isub));
    
    %| fill in session mask info (fugly code, but does its job)
    for j = 1:length(sessions)
        switch sessions(j)
            case 6
                session_info.v06(idx_sub) = true;
            case 12
                session_info.v12(idx_sub) = true;
            case 24
                session_info.v24(idx_sub) = true;
        end
    end
end
% keyboard
%% 07/21/2015 decided not convert to matlab built-in 'dataset' form
% session_info = dataset(session_info);
%%
%| check the "counts" returned agrees with my "uniq" function
tmp1 = session_info.count;
tmp2 = (session_info.v06 + session_info.v12 + session_info.v24);
% keyboard
assert( isequal(tmp1, tmp2) )
%% get subjects with all 3 scans
%| 2-scan cases
session_info.v24_v12 = (session_info.v24 & session_info.v12);
session_info.v24_v06 = (session_info.v24 & session_info.v06);
session_info.v12_v06 = (session_info.v12 & session_info.v06);

session_count.all_scans     = sum(session_info.all_scans);
session_count.v24     = sum(session_info.v24);
session_count.v12     = sum(session_info.v12);
session_count.v06     = sum(session_info.v06);
session_count.v24_v12 = sum(session_info.v24_v12);
session_count.v24_v06 = sum(session_info.v24_v06);
session_count.v12_v06 = sum(session_info.v12_v06);
%% create (nscans x 1) masks (computationally slow...make it an optional output)
%==============================================================================%
% (code below looks unholy, but i need to get some data analysis done, so 
% getting this over is higher priority for me at this point)
%==============================================================================%
if nargout == 3
    nscans = length(meta_info.lookup);
%     session_mask = dataset;

    %| below may sound redundant, but makes coding so much easier
    session_mask.lookup  = meta_info.lookup;
    session_mask.id      = id_list;
    session_mask.session = session;

    session_mask.all_scans = false(nscans,1);
    session_mask.v24 = false(nscans,1);
    session_mask.v12 = false(nscans,1);
    session_mask.v06 = false(nscans,1);
    session_mask.v24_v12 = false(nscans,1);
    session_mask.v24_v06 = false(nscans,1);
    session_mask.v12_v06 = false(nscans,1);
    % keyboard
    %%
    for idx_scan = 1:nscans
        subj_id = id_list(idx_scan);
        idx_sub = find(subj_id == session_info.id);

        session_mask.all_scans(idx_scan) = session_info.all_scans(idx_sub);
        session_mask.v24(idx_scan) = session_info.v24(idx_sub);
        session_mask.v12(idx_scan) = session_info.v12(idx_sub);
        session_mask.v06(idx_scan) = session_info.v06(idx_sub);
        
        %======================================================================%
        % WARNING: the masks for the two-time-point case requires care when all
        %          3-scans are present.
        % - For instance, when using v24_v06 mask, I don't want to the mask
        %   to include the v12 scan.
        %----------------------------------------------------------------------%
        % Below is the wrong version I originally had
        % (eg, mask.v24_v12 would include v06 scans if all 3scans were present)
        %
        % >> session_mask.v24_v12(idx_scan) = session_info.v24_v12(idx_sub);
        % >> session_mask.v24_v06(idx_scan) = session_info.v24_v06(idx_sub);
        % >> session_mask.v12_v06(idx_scan) = session_info.v12_v06(idx_sub);
        %======================================================================%
%         keyboard
        if session_mask.all_scans(idx_scan)
%             keyboard
            switch session_mask.session(idx_scan)
                case 6
%                     session_mask.v24_v12(idx_scan) = session_info.v24_v12(idx_sub);
                    session_mask.v24_v06(idx_scan) = session_info.v24_v06(idx_sub);
                    session_mask.v12_v06(idx_scan) = session_info.v12_v06(idx_sub);
                case 12
                    session_mask.v24_v12(idx_scan) = session_info.v24_v12(idx_sub);
%                     session_mask.v24_v06(idx_scan) = session_info.v24_v06(idx_sub);
                    session_mask.v12_v06(idx_scan) = session_info.v12_v06(idx_sub);
                case 24
                    session_mask.v24_v12(idx_scan) = session_info.v24_v12(idx_sub);
                    session_mask.v24_v06(idx_scan) = session_info.v24_v06(idx_sub);
%                     session_mask.v12_v06(idx_scan) = session_info.v12_v06(idx_sub);
            end
        else
            session_mask.v24_v12(idx_scan) = session_info.v24_v12(idx_sub);
            session_mask.v24_v06(idx_scan) = session_info.v24_v06(idx_sub);
            session_mask.v12_v06(idx_scan) = session_info.v12_v06(idx_sub);
        end

    %     disp('----------')
    %     tmp1=double(session_info(idx_sub,3:9));
    %     tmp2=[session_mask.all(idx_scan) ...
    %           session_mask.v24(idx_scan) ...
    %           session_mask.v12(idx_scan) ...
    %           session_mask.v06(idx_scan) ...
    %           session_mask.v24_v12(idx_scan) ...
    %           session_mask.v24_v06(idx_scan) ...
    %           session_mask.v12_v06(idx_scan) ];
    %     assert( isequal(tmp1,tmp2) )
    %     keyboard
    end
    % keyboard
end