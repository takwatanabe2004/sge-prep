function [C_circ, augmat, bmask, NSIZE] = tak_ibis_Ccirc_bmask(brain_mask)
%% [C_circ, bmask] = tak_ibis_Ccirc_bmask(brain_mask)
%==============================================================================%
% Create circulant incidence matrix "C_circ" and masking vector 'bmask'
% that masks out the circulant artifact when using fft-based ADMM algorithm
%------------------------------------------------------------------------------%
%==============================================================================%
% 08/15/2015
%%
[xx,yy,zz] = ind2sub(size(brain_mask),find(brain_mask));
xmin = min(xx);
xmax = max(xx);
ymin = min(yy);
ymax = max(yy);
zmin = min(zz);
zmax = max(zz);

%| crop/tighten brain mask
brain_mask = brain_mask(xmin:xmax,ymin:ymax,zmin:zmax);

%| size of the "cropped/tightened" mask
NSIZE = size(brain_mask);

%| circulant matrix
C_circ = tak_diffmat( size(brain_mask), 1);

%| augmentation matrix
augmat = speye(numel(brain_mask));
augmat = augmat(:,brain_mask);

Bx=circshift(brain_mask,[+1  0  0])-brain_mask;
By=circshift(brain_mask,[ 0 +1  0])-brain_mask;
Bz=circshift(brain_mask,[ 0  0 +1])-brain_mask;
Bx=tak_spdiag(Bx(:)==0);
By=tak_spdiag(By(:)==0);
Bz=tak_spdiag(Bz(:)==0);

N = numel(brain_mask);
% blkdiag can be slow for large sparse matrices
Bsupp = [         Bx, sparse(N,N), sparse(N,N); ...
         sparse(N,N),          By, sparse(N,N); ...
         sparse(N,N), sparse(N,N),         Bz];

Bcirc=tak_circmask(size(brain_mask));
B=Bsupp*Bcirc;
bmask=logical(full(diag(B)));