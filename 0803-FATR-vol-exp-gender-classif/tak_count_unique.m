function [uniques, counts, rate] = tak_count_unique(A)
%% out = tak_ismember(A,B)
%==============================================================================%
% In addition to returning "unique" elements in an array, also return its
% 'count' and 'rate'
%------------------------------------------------------------------------------%
% 07/20/2015
%==============================================================================%
%%
uniques = unique(A);

n_uniq = length(uniques);
counts = zeros(n_uniq,1);
rate   = zeros(n_uniq,1);

%%%% cell array case %%%
if isa(A, 'cell')
    for i = 1:n_uniq
%         keyboard
        if isa(uniques{i}, 'char')
            counts(i) = sum(cell2mat(  cellfun(@(x) strcmpi(x,uniques{i}), A,'UniformOutput',false)   ));
        elseif isa(uniques{i}, 'double')
            error('figure this out later; right now i dont deal with mixed cell with chars and doubles')    
        end

    %     if isa(uniques(i),'cell')
    %         counts(i) = sum(cell2mat(  cellfun(@(x) strcmpi(x,str), Cell,'UniformOutput',false)   ));
    %     else
    % %         counts(i) = ;
    %     end
    end
end

%%%% double array case %%%%
if isa(A,'double')
    for i = 1:n_uniq
        counts(i) = sum(A==uniques(i));
    end
end

%%%% return "rate" %%%%
rate = counts/length(A);

