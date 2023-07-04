
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	May. 31, 2023
* Last date of modification: 
* Modifications: - 
* Files used:     
		- apr_te_grf.csv
		- des_c_te_grf.csv
		- def_c_te_grf.csv
		- fc_admin_te_grf.csv
		- Master.dta
* Files created:  

* Purpose: densities of the CATE 

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : te_grf.R

********************************************************************************


*Load data with forest predictions 

import delimited "$directorio/_aux/apr_te_grf.csv", clear
tempfile temp_eff
rename tau_hat_oobpredictions tau_hat_eff
rename tau_hat_oobvarianceestimates var_hat_eff
save `temp_eff'

import delimited "$directorio/_aux/def_c_te_grf.csv", clear
tempfile temp_def
rename tau_hat_oobpredictions tau_hat_def
rename tau_hat_oobvarianceestimates var_hat_def
save `temp_def'

import delimited "$directorio/_aux/des_c_te_grf.csv", clear
tempfile temp_des
rename tau_hat_oobpredictions tau_hat_des
rename tau_hat_oobvarianceestimates var_hat_des
save `temp_des'

import delimited "$directorio/_aux/fc_admin_te_grf.csv", clear
rename tau_hat_oobpredictions tau_hat_fc_admin
rename tau_hat_oobvarianceestimates var_hat_fc_admin

merge 1:1 prenda using `temp_eff', nogen
merge 1:1 prenda using `temp_def', nogen
merge 1:1 prenda using `temp_des', nogen


********************************************************************************

			
foreach var in eff def des fc_admin {
	*Confidence intervals  
	cap drop lo_tau_`var' hi_tau_`var'
	gen lo_tau_`var' = tau_hat_`var' - 1.96*sqrt(var_hat_`var')
	gen hi_tau_`var' = tau_hat_`var' + 1.96*sqrt(var_hat_`var')
		
	twoway (kdensity tau_hat_`var', k(gauss) lwidth(thick)) (kdensity lo_tau_`var', k(gauss) lpattern(dash)) (kdensity hi_tau_`var', k(gauss) lpattern(dash)), xline(0) legend(order(1 "CATE" 2 "Lower bound" 3 "Upper bound") pos(6) rows(1))
	graph export "$directorio/Figuras/he_dist_`var'.pdf", replace
}
