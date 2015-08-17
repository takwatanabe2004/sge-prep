function [B,BX,BY]=tak_circmask_3d(ARRAYSIZE)
% [B,BX,BY]=tak_circmask_3d(ARRAYSIZE)
%----------------------------------------------------------------------------------
% Create diagonal binary masking matrix B, which masks the "wrap-around" artifacts 
% from using the circulant difference matrix created from tak_diffmat_3d_ver2(ARRAYSIZE,1)
%----------------------------------------------------------------------------------
% B: (3N x 3N) diagonal binary masking matrix, where N=prod(ARRAYSIZE)
%----------------------------------------------------------------------------------
% (05/28/2014)
%----------------------------------------------------------------------------------
%%
X=ARRAYSIZE(1);
Y=ARRAYSIZE(2);
Z=ARRAYSIZE(3);
N=prod(ARRAYSIZE);

%==================================================================================
% Create 1-D masking matrix for each dimension
%==================================================================================
maskX=tak_circmask_1d(X);
maskY=tak_circmask_1d(Y);
maskZ=tak_circmask_1d(Z);

Ix=speye(X);
Iy=speye(Y);
Iz=speye(Z);

Iyx=kron(Iy,Ix);
Izy=kron(Iz,Iy);

BX=kron(Izy,maskX);
BY=kron(Iz,kron(maskY,Ix));
BZ=kron(maskZ,Iyx);

%==================================================================================
% Create final masking matrix 
% - NOTE: blkdiag slow in my experience when dealing with large sparse matrix
%==================================================================================
B=[         BX, sparse(N,N), sparse(N,N); ...
   sparse(N,N),          BY, sparse(N,N); ...
   sparse(N,N), sparse(N,N),         BZ];
% B2=blkdiag(BX,BY,BZ);
% if isequal(B,B2), disp('Good!'),end;