%% Parameter structure
%
clear all
clc
parms.sigma = 0.4;
parms.delta=0.8;
parms.mu = 7;
parms.r = .2;
parms.beta_belief=0.9;
parms.beta=0.8;
parms.rep = 1000;
parms.gridsize = 1200;
parms.simul = 500;
parms.mu_d = 7.1;
parms.sigma_d = 0.3;




%% Simulation
beta_belief = parms.beta_belief; delta = parms.delta; 
r =parms.r; mu = parms.mu; sigma = parms.sigma;
mu_d = parms.mu_d; sigma_d = parms.sigma_d;

tic
m = zeros(parms.simul,4);
p = zeros(parms.simul,3);
d = zeros(parms.simul,3);

% Path of payments
for i = 1:parms.simul
    i
    
    % Draw a lognormal sample
    y = exp(mu + sigma.*randn(1,3)); 
    y(2) = y(2) - (rand<0.4)*y(2)*(0.5+0.4*rand);
    y(3) = y(3) - (rand<0.5)*y(3)*(0.5+0.4*rand);
    % Draw a debt sample
    m(i,1) = exp(mu_d + sigma_d.*randn(1));
    parms.v = m(i,1)/(0.7 + .02*randn(1));
    c = toc;
    [~,p(i,1),d(i,1)] = V1(y(1),m(i,1),parms); m(i,2) = (1+r)*(m(i,1)-p(i,1));
    c = toc-c
    c = toc;
    [~,p(i,2),d(i,2)] = V2(y(2),m(i,2),parms); m(i,3) = (1+r)*(m(i,2)-p(i,2));
    c = toc-c
    [~,p(i,3),d(i,3)] = V3(y(3),m(i,3),parms); m(i,4) = m(i,3)-p(i,3);
   
end
t= toc
%% Simulation

% beta_belief = parms.beta_belief; delta = parms.delta; 
% val = parms.v; r =parms.r; mu = parms.mu; sigma = parms.sigma;
% mu_d = parms.mu_d; sigma_d = parms.sigma_d;
% 
% m = zeros(2,4);
% p = zeros(2,3);
% d = zeros(2,3);
% 
% % Draw a lognormal sample
% y = exp(mu + sigma.*randn(2,3));
% 
% % Draw a debt sample
% m(:,1) = exp(mu_d + sigma_d.*randn(1));
% parms.v = m(1)/(0.7 + .02*randn(1));
% 
% % Path of payments
% [~,p(:,1),d(:,1)] = V1(y(:,1),m(1),parms); m(:,2) = (1+r)*(m(:,1)-p(:,1));
% [~,p(:,2),d(:,2)] = V2(y(:,2),m(2),parms); m(3) = (1+r)*(m(2)-p(2));
% [~,p(:,3),d(:,3)] = V3(y(:,3),m(3),parms); m(4) = m(3)-p(3);
