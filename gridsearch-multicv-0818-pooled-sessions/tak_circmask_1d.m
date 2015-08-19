function B=tak_circmask_1d(n)
% B=tak_circmask_1d(n)
%----------------------------------------------------------------------------------
% Create diagonal binary masking matrix B, which masks the "wrap-around" artifacts 
% from using the circulant difference matrix created from tak_diffmat_1d_ver2(n,1)
%
% IMPORTANT: Here, the wrap around effect is assumed to occur at the first row of 
% the difference matrix (see tak_diffmat_1d_ver2.m)
%----------------------------------------------------------------------------------
% B: (n x n) diagonal binary masking matrix
%----------------------------------------------------------------------------------
% (05/28/2014)
%----------------------------------------------------------------------------------
%%
B=speye(n);
B(1,1)=0;