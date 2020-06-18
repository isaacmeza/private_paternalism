function [z] = value_func(p, y, v, shocks, parms)
% Value function

if (p >= m)
    val = parms.V;
else
    val = 0;
end

% Interpolation
v_interp = chebfun(v,[0,1],'equi');
z = val + log(y-p) + parms.delta*mean(v_interp(parms.mu + parms.rho*y + shocks));

end

