function [y] = eu(x, mu, sigma)
%Expected utility of log-normal distribution with degree of RRA x
y = exp((1-x).*mu+0.5*((1-x).*sigma).^2)./(1-x);

end

