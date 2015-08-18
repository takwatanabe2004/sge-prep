function grad = tak_logistic_grad(w,X,y)
% return gradient for the logistic loss (without 1/n scaling for now)
% 07/24/2015
%%
Xw = X*w;
yXw = y.*Xw;

if nargout > 2
    sig = 1./(1+exp(-yXw));
    grad = -X.'*(y.*(1-sig));
else
    %grad = -X.'*(y./(1+exp(yXw)));
    grad = -(X.'*(y./(1+exp(yXw))));
end

%% brute force sanity check
%| t = margin term
% logis_grad = @(t) 1/(1 + exp(-t));
% [n,p] = size(X);
% grad2 = zeros(p,1);
% grad3 = zeros(p,1);
% 
% for i = 1:n
%     yi = y(i);
%     xi = vec( X(i,:) );
%     mi = yi*(xi'*w);
%     grad2 = grad2 + (logis_grad(mi) - 1)*yi*xi;
%     grad3 = grad3 -yi*xi/(1 + exp(mi));
% end
% assert(norm(grad-grad2)<1e-10)
% assert(norm(grad3-grad2)<1e-10)
%%
% sig = 1./(1+exp(-yXw));
% g = -X.'*(y.*(1-sig));
% H = X.'*diag(sparse(sig.*(1-sig)))*X;