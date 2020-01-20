function [V, pp, d] = V2(y,m,parms)
% Value function at time period t=2
beta_belief = parms.beta_belief; delta = parms.delta; 
val = parms.v; r =parms.r; mu = parms.mu; sigma = parms.sigma;

% Sample to compute V3:
y_prime = exp(mu + sigma.*randn(parms.rep,1));

% Function to optimize
% VV1 = @(p) beta*delta*log(y-p) + ...
%     mean(V3(y_prime,(1+r).*(m-p),parms));
%%

if (m <= 0)
   % Value function
    V = beta_belief*delta*(log(1+val)+log(y)) + ...
        beta_belief*delta^2*log(1+val) + ...
        beta_belief*delta^2*mu;
    pp = zeros(length(y),1);
    
else
    % Discretize grid for policies
    mn = min(m,y);
    mx = max(mn);
    p = linspace(0,mx,parms.gridsize);

    Omega = (1+val)/val;
    % Value function
    VV = beta_belief*delta*log(y-p) + ...
        beta_belief*delta^2*log(1+val).*(1-logncdf((1+r)*(m-p)*Omega,mu,sigma)) + ...
        beta_belief*delta^2*mean(log(y_prime-(1+r).*max((m-p),0).*(y_prime >= (1+r)*(m-p)*Omega)));

    V = zeros(length(y),1); ind = zeros(length(y),1);
    for i=1:length(y)
        % Optimal int point value
        [V(i),ind(i)] = max(VV(i,imag(VV(i,:))==0));
    end

    % Optimal int point policy
    pp = p(ind)';

    %% 

    % Optimum for paying debt at this time period if possible
    opt = -Inf*ones(length(y),1);
    opt(m<=y) = beta_belief*delta.*(log(1+val) + log(y(m<=y)-m)) + ...
            beta_belief*delta^2*(log(1+val) + mu);


    %% Optimum values
    ind_change = V<opt;
    V(ind_change) = opt(ind_change); pp(ind_change) = m;
end

    % Paid loan
    d = (pp==m);
end

