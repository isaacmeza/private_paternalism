clear all 
close all
clc
FC = readmatrix('../_aux/fc_admin_disc.csv');
log_FC = log(FC); 

%% MLE
[pHat,pCI] = lognfit(FC,0.05);
params.mu = pHat(1); params.sigma = pHat(2);
[~,pCov] = lognlike(pHat,FC);

%% Empirical/Theoretical CDF
x_values = linspace(min(FC),max(FC));
[p,pLo,pUp] = logncdf(x_values,params.mu,params.sigma,pCov);

figure;
hold on
ecdf = cdfplot(FC);
plot(x_values,p,'r-')
plot(x_values,pLo,'r--')
plot(x_values,pUp,'r--')
legend('Empirical CDF','Log-normal CDF','Hi','Lo','Location','best')
hold off

%% Kolmogorov-Smirnov / Anderson-Darling
log_FC_std = (log_FC-params.mu)/params.sigma;
[h1,p1] = kstest(log_FC_std);
[h2,p2] = adtest(log_FC);

%% Expected Utlity
eta = linspace(0,1,1000);
U = eu(eta,params.mu,params.sigma);
U1 = eu(eta,pCI(1,1),pCI(1,2)); U2 = eu(eta,pCI(1,1),pCI(2,2));
U3 = eu(eta,pCI(2,1),pCI(1,2)); U4 = eu(eta,pCI(2,1),pCI(2,2));


figure;
hold on
p = plot(eta,U,'b-');
p1 = plot(eta,U1,'b--');
p2 = plot(eta,U2,'b--');
p3 = plot(eta,U3,'b--');
p4 = plot(eta,U4,'b--');
xlabel('RRA degree');
ylabel('FC');
hold off


