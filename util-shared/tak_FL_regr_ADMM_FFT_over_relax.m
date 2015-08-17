function [w,output]=tak_FL_regr_ADMM_FFT_over_relax(X,y,lam,gam,options,graphInfo,wtrue)
% [w,output]=tak_FL_regr_ADMM_FFT_over_relax(X,y,lam,gam,options,graphInfo,wtrue)
% (08/16/2015)
%=========================================================================%
% - ADMM fused lasso net regression:
%    1/2||y-Xw||^2 + lam * ||w||_1 + gamma2 * ||C*w||_1
%-------------------------------------------------------------------------%
% Here I replaced the \bar{y} and u update with the over-relaxation step
% (see Boyd pg 21 sec 3.4.3)
%=========================================================================%
% options.K <- optionally precompute
% wtrue <- optional...measure norm(west-wtrue) over iterations if inputted
%% sort out 'options'
[n,p]=size(X);

C = graphInfo.C;
A = graphInfo.A;
b = graphInfo.b; 
NSIZE = graphInfo.NSIZE; 

pp=size(A,1);
e=size(C,1);

%=========================================================================%
% AL paramter and termination criteria
%=========================================================================%
if(~exist('options','var')||isempty(options)),     
    rho = 1;
    
    maxiter = 500;
    tol = 5e-4;
    progress = inf;
    silence = false;
    funcval = false;

    if p > n
        K=tak_admm_inv_lemma(X,1/(2*rho));
    end
else
    % augmented lagrangian parameters
    rho=options.rho;

    %=====================================================================%
    % termination criterion
    %=====================================================================%
    maxiter   = options.maxiter;     % <- maximum number of iterations
    tol       = options.tol;         % <- relative change in the primal variable
    progress  = options.progress;    % <- display "progress" (every k iterations)
    silence   = options.silence;     % <- display termination condition
    funcval   = options.funcval;     % <- track function values (may slow alg.)

    %=====================================================================%
    % Matrix K for inversion lemma 
    % (optionally precomputed...saves time during gridsearch)
    % (only use inversion lemma when p > n...else solve matrix inverse directly)
    %=====================================================================%
    if p > n
        if isfield(options,'K')
            K=options.K;
        else
            K=tak_admm_inv_lemma(X,1/(2*rho));
        end
    end
end
%% initialize variables, function handles, and terms used through admm steps
%==========================================================================
% initialize variables
%==========================================================================
% primal variable
w  = zeros(p,1); 
v1 = zeros(p,1);
v2 = zeros(e,1);
v3 = zeros(pp,1);

% dual variables
u1 = zeros(p,1);
u2 = zeros(e,1);
u3 = zeros(pp,1);

%==========================================================================
% function handles
%==========================================================================
soft=@(t,tau) sign(t).*max(0,abs(t)-tau); % soft-thresholder
bsoft=@(t,tau) soft(t,tau).*b + (~b).*t; % for v3 update

%==========================================================================
% precompute terms used throughout admm
%==========================================================================
Xty=(X'*y);
if n >= p
    XtX = X'*X;
end
Ct=C';
At=A';
% CtC=Ct*C;
% Ip=speye(p);
% Cv2=zeros(e,1); % initialization needed

%-------------------------------------------------------------------------%
% stuffs for fft-based inversion
%-------------------------------------------------------------------------%
% Circulant matrix to invert via fft
H=(Ct*C)+speye(pp); 
% keyboard
% spectrum of matrix H...ie, the fft of its 1st column
h=fftn(reshape(full(H(:,1)),NSIZE),NSIZE); 

%=========================================================================%
% keep track of function value (optional, as it could slow down algorithm)
%=========================================================================%
if funcval
    fval = @(w) 1/2 * norm(y-X*w)^2 + lam*norm(w,1) + gam*norm(b.*(C*A*w),1);
end
%% begin admm iteration
time.total=tic;
time.inner=tic;

alpha = 1.8; % <- relaxation parameter (see boyd 3.4.3)

rel_changevec=zeros(maxiter,1);
w_old=w;
% disp('go')

% keep track of function value
if funcval, fvalues=zeros(maxiter,1); end;
if exist('wtrue','var'), wdist=zeros(maxiter,1); end;
for k=1:maxiter
    if funcval,  fvalues(k)=fval(w); end;   
    if exist('wtrue','var'), wdist(k)=norm(w-wtrue); end;
    
    if mod(k,progress)==0 && k~=1
        str='--- %3d out of %d ... Tol=%2.2e (tinner=%4.3fsec, ttotal=%4.3fsec) ---\n';
        fprintf(str,k,maxiter,rel_change,toc(time.inner),toc(time.total))
        time.inner = tic;
    end    
    
    %======================================================================
    % update first variable block: (w,v2)
    %======================================================================
    % update w (if p > n, apply inversion lemma)
%     keyboard
    q = Xty + rho*(v1-u1) + rho*(At*(v3-u3));
    if p > n
        w=q/(2*rho) - 1/(2*rho)^2*(K*(X*q));
    else
        w = (XtX + rho*Ip)\q;
    end
    
    % update v2
%     keyboard
%     v2=C*v3-u2;
%     v2(b)=soft(v2(b),gam/rho);  
    v2 = bsoft(C*v3 - u2, gam/rho);

    %======================================================================
    % update second variable block: (v1,v3)
    %----------------------------------------------------------------------
    % Use relaxation with alpha
    %======================================================================
    % update v1 
    v1 = soft(w+u1/alpha,lam/(rho*alpha));
    
    % update v3 (use fft)
    tmp=(Ct*(v2+u2/alpha))+(A*w+u3/alpha);
    tmp= reshape(tmp, NSIZE);
    v3=ifftn( fftn(tmp,NSIZE)./h, NSIZE);
    v3=v3(:);
    
    %======================================================================
    % dual updates
    %======================================================================
    u1=u1+alpha*(w-v1);
    u2=u2+alpha*(v2-C*v3);
    u3=u3+alpha*(A*w-v3);

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
w=v1;
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

% (optional) final function value
if funcval,  
    fvalues(k+1)=fval(w); 
    fvalues=fvalues(1:k+1);
    output.fval=fvalues;
    tplott(log10(fvalues))
end;

% (optional) distance to wtrue
if exist('wtrue','var')
    wdist(k+1)=norm(w-wtrue); % <- final function value
    wdist=wdist(1:k+1);
    output.wdist=wdist;
end;

% keyboard