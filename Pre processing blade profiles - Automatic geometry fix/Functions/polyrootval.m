function y=polyrootval(p,x,exp)


%%%%%This function is basically polyval modified to retain the roots to
%%%%%represent the nose in an accurate way
%%%%%aswell as the rest of coefficient(A*sqrt(x)+B*x+C*x^2+......)
k=length(p);
y=polyval(p,x)+p(k)*(nthroot(x,exp)-1);
end
