function [w,output]=tak_GN_logistic_FISTA_linesearch(X,y,lam,gam,options,C,wtrue)
% [w,output]=tak_GN_logistic_FISTA(X,y,lam,gam,options,C,wtrue)
% (07/24/2015)
%==============================================================================%
% - FISTA GraphNet logistic: line search version
%  (function value always computed since it's needed for Armjio check anyways)
%------------------------------------------------------------------------------%
%    sum(log(1+exp(-YWx))  + lam * ||w||_1 + gam/2 * ||C*w||^2
%==============================================================================%
% options.K <- optionally precompute
% wtrue <- optional...measure norm(west-wtrue) over iterations if inputted
%% sort out 'options'
p=size(X,2);

%=========================================================================%
% ISTA paramter and termination criteria
%=========================================================================%
if(~exist('options','var')||isempty(options))
    maxiter = 500;
    tol = 5e-4;
    progress = inf;
    silence = false;
    funcval = false;
else
    %=====================================================================%
    % termination criterion
    %=====================================================================%
    if isfield(options,'maxiter')
        maxiter = options.maxiter;
    else
        maxiter = 500; % <- maximum number of iterations
    end
    if isfield(options,'tol')
        tol = options.tol;
    else
        tol = 5e-4;     % <- relative change in the primal variable
    end
    if isfield(options,'progress')
        progress = options.progress;
    else
        progress = inf;  % <- display "progress" (every k iterations)
    end
    if isfield(options,'silence')
        silence = options.silence;
    else
        silence = false;  % <- display termination condition
    end
    if isfield(options,'funcval')
        funcval = options.funcval;
    else
        funcval = false;  % <- track function values (may slow alg.)
    end
end
%% initialize variables, function handles, and terms used through admm steps
%==========================================================================
% initialize variables
%==========================================================================
w  = zeros(p,1); 
v  = zeros(p,1); 

%==========================================================================
% function handles
%==========================================================================
soft=@(t,tau) sign(t).*max(0,abs(t)-tau); % soft-thresholder

%==========================================================================
% precompute terms used throughout admm
%==========================================================================
% Xty=(X'*y);
YX = bsxfun(@times,X,y); % same effect as diag(y)*X;
YXt = YX';
% Xt=X';
CtC=C'*C;

%=========================================================================%
% Function handle for the gradient; be sure to use without redundancy
%=========================================================================%
GRAD = @(w) tak_logistic_grad(w,X,y) + gam * (CtC*w);

%=========================================================================%
% keep track of function value (optional, as it could slow down algorithm)
%| t = margin term
% logis = @(t) log(1 + exp(-t));
% 
% Xw = X*w;
% yXw = y.*Xw;
% loss = sum(logis(yXw));
%=========================================================================%
logis = @(t) log(1 + exp(-t));
fval = @(w) sum(logis(YX*w)) + lam*norm(w,1) + gam/2*norm(C*w)^2;
gval = @(w) sum(logis(YX*w)) + gam/2*norm(C*w)^2; % <- only the cost of the smooth part
%% begin admm iteration
time.total=tic;
time.inner=tic;

tau = 1; % <- initial step size
rel_changevec=zeros(maxiter,1);
step_sizes = zeros(maxiter,1);
w_old=w;
t=1;
% disp('go')

% keep track of function value
if funcval, fvalues=zeros(maxiter,1); end;
if exist('wtrue','var'), wdist=zeros(maxiter,1); end;
for k=1:maxiter
%     k
    if funcval,  fvalues(k)=fval(w); end;   
    if exist('wtrue','var'), wdist(k)=norm(w-wtrue); end;
    
    if mod(k,progress)==0 && k~=1
        str='--- %3d out of %d ... Tol=%2.2e (tinner=%4.3fsec, ttotal=%4.3fsec) ---\n';
        fprintf(str,k,maxiter,rel_change,toc(time.inner),toc(time.total))
        time.inner = tic;
    end
    
    %======================================================================
    % FISTA step via line search 
    % - http://www.seas.ucla.edu/~vandenbe/236C/lectures/fgrad.pdf
    %======================================================================  
    tau = 0.1;

    %| try prox-gradient step
    gradv = GRAD(v);
    w_test = soft(v - tau*gradv, lam*tau);
    
    %| Use UCLA line search method1
    cnt = 1;
    gvalv = gval(v);
%     while gval(w_test) > gval(v) + GRAD(v)'*(w_test - v) + norm(w_test-v)^2/(2*tau);
    while gval(w_test) > gvalv + gradv'*(w_test - v) + norm(w_test-v)^2/(2*tau);
        tau = tau * 0.5; % <- halve the step size
        w_test = soft(v - tau*gradv, lam*tau);
        cnt = cnt+1;
        if cnt > 500
            disp('break!')
            break
        end
    end
    step_sizes(k)=tau;
%     tau
%     [cnt, tau]
    w = w_test;
    t_old = t;
    t = (1+sqrt(1+4*t^2))/2;
    v = w + ((t_old-1)/t) * (w - w_old);    
%     keyboard

    %======================================================================
    % Check termination criteria
    %======================================================================
    %%% relative change in primal variable norm %%%
    rel_change=norm(w-w_old)/norm(w_old);
    rel_changevec(k)=rel_change;
    time.rel_change=tic;
    
    flag1=rel_change<tol;
    if flag1 && (k>30) % allow 30 iterations of burn-in period
        if ~silence
            fprintf('*** Primal var. tolerance reached!!! tol=%6.3e (%d iter, %4.3f sec)\n',rel_change,k,toc(time.total))
        end
        break
    elseif k==maxiter
        if ~silence
            fprintf('*** Max number of iterations reached!!! tol=%6.3e (%d iter, %4.3f sec)\n',rel_change,k,toc(time.total))
        end
    end     
    
    % needed to compute relative change in primal variable
    w_old=w;
end

time.total=toc(time.total);
%% organize output
% primal variables
% output.w=v2;
% output.v=v;

% dual variables
% output.u=u;

% time it took for the algorithm to converge
% output.time=time.total;

% number of iteration it took to converge
% output.k=k;

% final relative change in the primal variable
% output.rel_change=rel_change;

% the "track-record" of the relative change in primal variable
output.rel_changevec=rel_changevec(1:k);

% step sizes found via line search
output.step_sizes = step_sizes(1:k);

% (optional) final function value
if funcval,  
    fvalues(k+1)=fval(w); 
    fvalues=fvalues(1:k+1);
    output.fval=fvalues;
end;

% (optional) distance to wtrue
if exist('wtrue','var')
    wdist(k+1)=norm(w-wtrue); % <- final function value
    wdist=wdist(1:k+1);
    output.wdist=wdist;
end;
