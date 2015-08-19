function K=tak_admm_inv_lemma(X,c)
% compute matrix K...an expression frequently encountered during admm
% when using the inversion lemma
%   K = X'*inv( I + c*X*X') 
% X: (n x p) design matrix
%%
n=size(X,1);
TMP= eye(n) + c*(X*X');
K = (TMP\X)';