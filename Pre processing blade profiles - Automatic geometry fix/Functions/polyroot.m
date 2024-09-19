function p=polyroot(x,y,exp,n)


%%%%%This function is basically polyfit modified to retain the roots to
%%%%%represent the nose in an accurate way
%%%%%aswell as the rest of coefficient(A*sqrt(x)+B*x+C*x^2+......)
%%%%%To do this The vandermonde matrix will be modified adding an extra
%%%%%column
% Construct the Vandermonde matrix V = [x.^n ... x.^2 x ones(size(x))]


V(:,n+1) = ones(length(x),1,class(x));

for j = n:-1:1
    V(:,j) = x.*V(:,j+1);
      
end
 aux=nthroot(x,exp);
V_mod=[V(:,1:n) aux];

% Solve least squares problem p = V\y to get polynomial coefficients p.
% [Q,R] = qr(V_mod,0);
% p = R\(Q'*y);
%constrained approach
% i=find(x==1);
% p = lsqlin(V_mod,y,[],[],ones(1,n+1),y(i),[],[]);
%unconstrained approach
p = lsqlin(V_mod,y,[],[],[],[],[],[]);
p=p';
end
