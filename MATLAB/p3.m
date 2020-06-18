function [p] = p3(y,m,parms)
%Optimal policy at time period t = 3

p = m.*((y >= m.*(1+parms.v)./parms.v));
end

