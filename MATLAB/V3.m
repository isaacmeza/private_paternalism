function [V, pp, d] = V3(y,m,parms)
% Value function at time period t=3
beta_belief = parms.beta_belief; delta = parms.delta; val = parms.v;


pp = m.*((y >= m.*(1+val)./val));

V = beta_belief*delta^2*(log(1+val).*(y >= m.*(1+val)./val)+...
    log(y-pp));

% Paid loan
d = (pp==m);

end
