function [C,CX,CY,CZ]=tak_diffmat_3d(ARRAYSIZE,flagcirc)
% [C,CX,CY,CZ]=tak_diffmat_3d(ARRAYSIZE,flagcirc)
% comment incomplete...
%----------------------------------------------------------------------------------
% Create 3-d first order difference matrix
%----------------------------------------------------------------------------------
% INPUT
%   ARRAYSIZE = [X Y Z] -> dimension size of the array
%   flagcirc: '0' -> make non-circulant difference matrix [default]
%             '1' -> make circulant difference matrix 
%                    (creates wrap-around terms, so use with caution)
%----------------------------------------------------------------------------------
% OUTPUT
%  C: C = [CX; CY; CZ]
%   where CX,CY,CZ: difference operator on each of the 3 dimensions   
%----------------------------------------------------------------------------------
% Note: if flagcirc==1: 
%   C: (3N x N) matrix, where N = (X*Y*Z) 
%   CX,CY,CZ: (N x N) matrix
%----------------------------------------------------------------------------------
% (05/28/2014)
%----------------------------------------------------------------------------------
%%
% default: non-circulant difference matrix
if nargin==1 
    flagcirc=0;
end

X=ARRAYSIZE(1);
Y=ARRAYSIZE(2);
Z=ARRAYSIZE(3);

%==================================================================================
% Create 1-D difference matrix for each dimension
%==================================================================================
DX=tak_diffmat_1d(X,flagcirc);
DY=tak_diffmat_1d(Y,flagcirc);
DZ=tak_diffmat_1d(Z,flagcirc);

%==================================================================================
% create kronecker structure needed to create the difference operator for 
% each dimension (see my research notes)
%==================================================================================
Ix=speye(X);
Iy=speye(Y);
Iz=speye(Z);

Iyx=kron(Iy,Ix);
Izy=kron(Iz,Iy);

%==================================================================================
% create first order difference operator for each array dimension
%==================================================================================
CX=kron(Izy,DX);
CY=kron(Iz,kron(DY,Ix));
CZ=kron(DZ,Iyx);

%==================================================================================
% create final difference matrix
%==================================================================================
C=[CX;CY;CZ];