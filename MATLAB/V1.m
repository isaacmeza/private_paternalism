function [V, pp, d] = V1(y,m,parms)
% Value function at time period t=1
beta_belief = parms.beta_belief; delta = parms.delta; 
val = parms.v; r =parms.r; mu = parms.mu; sigma = parms.sigma;

% Sample to compute V2:
y_prime = exp(mu + sigma.*randn(parms.rep,1));

% Value function:
VV = @(p) log(y-p) + mean(V2(y_prime,(1+r)*(m-p),parms));

mn = min(m,y); mx = max(mn); grid = linspace(0,mx,parms.gridsize); 
F = zeros(length(y),parms.gridsize);
for i = 1:parms.gridsize
    % Computationally expensive
    F(:,i) = VV(grid(i));
end

% Optimal Interior Point Value
[V,ind] = max(F,[],2);
% Optimal int point policy
pp = grid(ind)';

% Optimum for paying debt at this time period if possible
opt = -Inf*ones(length(y),1);
opt(m<=y) = log(1+val) + log(y-m) + ...
    (beta_belief*delta + beta_belief*delta^2)*(log(1+val) + mu);

%% Optimum values
ind_change = V<opt;
V(ind_change) = opt(ind_change); pp(ind_change) = m;
% Paid loan
d = (pp==m);
end
