
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: 

*******************************************************************************/
*/
*Load data with eff_te predictions (created in te_grf.R)

import delimited "$directorio/_aux/des_te_grf.csv", clear
gen mu1_mu0_des = pr_mu1predictions-pr_mu0predictions

keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions mu1_mu0 pr_mu0predictions

rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions pr_mu0predictions) (var_des tau_des pr_mu0predictions_des)
tempfile temp_des
save `temp_des'


import delimited "$directorio/_aux/apr_te_grf.csv", clear

gen mu1_mu0 = pr_mu1predictions-pr_mu0predictions

keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions mu1_mu0 pr_mu0predictions



rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_apr tau_apr)
tempfile temp_apr
save `temp_apr'

*Load data with propensity score (created in choice_prediction.ipynb)
import delimited "$directorio/_aux/prop_choose.csv", clear

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
merge 1:1 prenda using `temp_apr', nogen keep(3)
merge 1:1 prenda using `temp_des', nogen keep(3)


logit choose_commitment $C0 edad  faltas val_pren_std 	genero pres_antes i.plan_gasto masqueprepa pb if t_prod==4

predict pr_logitlinear



gen residual0 = -apr - pr_mu0predictions - pr_logitlinear*(mu1_mu0)
gen residual2 = -apr - pr_mu0predictions - pr_gbc_1*(mu1_mu0)



twoway (lpoly residual0 pr_logitlinear if t_prod==4) ///
(lpoly residual2 pr_gbc_1 if t_prod==4) ///
(scatter residual0 pr_logitlinear, msymbol(Oh) msize(small) color(navy%30)) ///
(scatter residual2 pr_gbc_1, msymbol(Oh) msize(small) color(red%25)) ///
, legend(order(1 "Logit" 2 "GBC") pos(6) rows(1)) xtitle("Propensity") ytitle("Residual")


twoway (lpoly residual0 pr_logitlinear if t_prod==4) ///
(lpoly residual2 pr_gbc_1 if t_prod==4) ///
, legend(order(1 "Logit" 2 "GBC") pos(6) rows(1)) xtitle("Propensity") ytitle("Residual")

lpoly residual0 pr_logitlinear if t_prod==4, ci
lpoly residual2 pr_gbc_1 if t_prod==4, ci


binscatter residual0 pr_logitlinear if t_prod==4
binscatter residual2 pr_gbc_1  if t_prod==4




gen residual0_des = des_c - pr_mu0predictions_des - pr_logitlinear*(mu1_mu0)
gen residual2_des = des_c - pr_mu0predictions_des - pr_gbc_1*(mu1_mu0)


lpoly residual0 pr_logitlinear, noscatter
twoway (lpoly residual0_des pr_logitlinear if t_prod==4) ///
(lpoly residual2_des pr_gbc_1 if t_prod==4) ///
(scatter residual0_des pr_logitlinear, msymbol(Oh) msize(small) color(navy%30)) ///
(scatter residual0_des pr_gbc_1, msymbol(Oh) msize(small) color(red%25)) ///
, legend(order(1 "Logit" 2 "GBC") pos(6) rows(1)) xtitle("Propensity") ytitle("Residual")