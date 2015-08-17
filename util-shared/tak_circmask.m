function B = tak_circmask(ARRAYSIZE)
% B = tak_circmask(ARRAYSIZE,flagcirc)
%--------------------------------------------------------------------------
% A wrapper for making diagonal binary masking matrix for n-d tensor signal
% - the circulant matrix has the "wrap-around-effect" occuring on the 
%   first row (the previous version had this on the last row).
%--------------------------------------------------------------------------
% (05/28/2014)
%%
switch length(ARRAYSIZE)
    case 1
        B=tak_circmask_1d(ARRAYSIZE);
    case 2
        B=tak_circmask_2d(ARRAYSIZE);
    case 3
        B=tak_circmask_3d(ARRAYSIZE);
    case 4
        B=tak_circmask_4d(ARRAYSIZE);
    case 6
        B=tak_circmask_6d(ARRAYSIZE);
    otherwise
        error('Unsupported dimension!!!')
end