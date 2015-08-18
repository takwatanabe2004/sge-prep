function b = tak_spdiag(a, varargin)
% Credit: code directly from j.fessler's irt toolbox: % http://web.eecs.umich.edu/~fessler/code/
% 06/24/2013
%%
%function b = spdiag(a, options)
% create a sparse matrix with diagonal given by a
% option:
%	'nowarn'	do not warn about diag_sp
% caution: it may be faster to use my newer diag_sp() object instead.
%%
if nargin < 1, help(mfilename), error(mfilename), end

a = a(:);
a = double(a); % trick: needed because matlab7 doesn't handle single sparse well
n = length(a);
b = sparse(1:n, 1:n, a, n, n, n);
