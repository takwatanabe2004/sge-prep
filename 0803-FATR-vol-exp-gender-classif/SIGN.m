function y=SIGN(t)
% sign function, but with the convention SIGN(0)==1, rather than sign(0)=0
y=(t~=0).*sign(t) + (t==0)*1;