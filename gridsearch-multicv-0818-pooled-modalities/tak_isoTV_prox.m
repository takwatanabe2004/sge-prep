function prox=tak_isoTV_prox(w,b,tau,idxCell)
% prox=tak_isoTV_prox(x,b,tau)
% (02/13/2014)
%=========================================================================%
% tau <- prox scaling term
%-------------------------------------------------------------------------%
% (05/10/2014) - added 3d case
%=========================================================================%
%%
d = size(idxCell,1);

%=========================================================================%
% signal norm with the appropriate masking applied: (p x 1)
%=========================================================================%
wmasked=b.*w;
% vector of euclidean norm of the gradients, with the mask applied

if d==3
    dx=wmasked(idxCell{1});
    dy=wmasked(idxCell{2});
    dz=wmasked(idxCell{3});
    xnorm_mask = sqrt(dx.^2 + dy.^2 + dz.^2);
elseif d==4
    dx1=wmasked(idxCell{1});
    dy1=wmasked(idxCell{2});
    dx2=wmasked(idxCell{3});
    dy2=wmasked(idxCell{4});
    xnorm_mask = sqrt(dx1.^2 + dy1.^2 + dx2.^2 + dy2.^2);
elseif d==6
    dx1=wmasked(idxCell{1});
    dy1=wmasked(idxCell{2});
    dz1=wmasked(idxCell{3});
    dx2=wmasked(idxCell{4});
    dy2=wmasked(idxCell{5});
    dz2=wmasked(idxCell{6});
    xnorm_mask = sqrt(dx1.^2 + dy1.^2 + dz1.^2 + dx2.^2 + dy2.^2 + dz2.^2);
end

%=========================================================================%
% Compute shrinkage factor
%-------------------------------------------------------------------------%
% tmp = tau/||w|| for the shrinkage, with the convention (0/0) = 0
%=========================================================================%
tmp=tau./xnorm_mask;
tmp(isnan(tmp))=0;
shrink_f=max(1-tmp,0); % shrinkage factor

%-------------------------------------------------------------------------%
% the brute force method is slightly faster than repmat
% (and is faster than looping)
%-------------------------------------------------------------------------%
if d==3
    shrink=[shrink_f;shrink_f;shrink_f];
elseif d==4
    shrink=[shrink_f;shrink_f;shrink_f;shrink_f];
elseif d==6
    shrink=[shrink_f;shrink_f;shrink_f;shrink_f;shrink_f;shrink_f];
end
% shrink=[];
% for i=1:d
%     shrink=[shrink;shrink_factor];
% end
% shrink = repmat(shrink_factor,[d,1]); 
% keyboard

%=========================================================================%
% apply shrinkage
%=========================================================================%
shrinked_w=shrink.*w;

%=========================================================================%
% final Prox output
%-------------------------------------------------------------------------%
% - the prox output has two parts: masked part and non-masked parts, where
%  the masked part of the prox simply returns the input signal
%-------------------------------------------------------------------------%
prox=w;

% the non-masked part of the prox output; here return the shrinked signal
prox(b)=shrinked_w(b);