function D=tak_diffmat_1d(n,flagcirc)
% (05/28/2014)
%==================================================================================
% - create 1D difference matrix
%   option=0 
%    -> D = (n-1 x n) matrix with no circulant structure
%   option=1 
%    -> D = (n x n) matrix with circulant structure...
%    -> the circulant structure creates a "wrap-around term"
%       (for an N-D vector x, the last entry of the product D*x will be x1-xN...
%        which may not be sensible)
%==================================================================================
if nargin==1 
    flagcirc=0;
end

% (n-1 x n) incidence/difference matrix
D = sparse(1:n-1, 2:n, 1, n-1, n)-sparse(1:n-1, 1:n-1, 1, n-1, n);

if flagcirc % pad a row at the TOP that adds the (x1-xN) effect
    D = [1 zeros(1,n-2) -1; D];
end