
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

** RUN R CODE : te_grf.R, tot_tut_instr_forest.R

********************************************************************************


*Load data with forest predictions 

import delimited "$directorio/_aux/apr_te_grf.csv", clear
tempfile temp_eff
rename tau_hat_oobpredictions tau_hat_eff
rename tau_hat_oobvarianceestimates var_hat_eff
save `temp_eff'

import delimited "$directorio/_aux/tot_apr_instr_forest.csv", clear
tempfile temp_tot
rename inst_hat_oobpredictions tau_hat_tot
rename inst_hat_oobvarianceestimates var_hat_tot
save `temp_tot'

import delimited "$directorio/_aux/tut_apr_instr_forest.csv", clear
tempfile temp_tut
rename inst_hat_oobpredictions tau_hat_tut
rename inst_hat_oobvarianceestimates var_hat_tut
save `temp_tut'

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
keep if inlist(t_prod,4)

merge 1:1 prenda using `temp_eff', nogen
merge 1:1 prenda using `temp_tot', nogen
merge 1:1 prenda using `temp_tut', nogen



********************************************************************************
*Draw random effect Y_1-Y_0 from normal distribution with standard error according to Athey
replace tau_hat_eff = rnormal(tau_hat_eff, sqrt(var_hat_eff)) if t_prod==2
twoway (kdensity tau_hat_eff, k(gauss) lwidth(thick) color(navy)), xline(0) legend(off) ytitle(" ") xtitle("APR")
graph export "$directorio/Figuras/he_dist_tau_hat_eff.pdf", replace
	
replace tau_hat_tot = rnormal(tau_hat_tot, sqrt(var_hat_tot)) if t_prod==4 & choose==1	
xtile perc_tau_hat_tot = tau_hat_tot, nq(100)
twoway (kdensity tau_hat_tot if perc_tau_hat_tot>=5, k(gauss) lwidth(thick) color(maroon)), xline(0) legend(off) ytitle(" ") xtitle("APR")
graph export "$directorio/Figuras/he_dist_tau_hat_tot.pdf", replace
	
replace tau_hat_tut = rnormal(tau_hat_tut, sqrt(var_hat_tut)) if t_prod==4 & choose==0	
twoway (kdensity tau_hat_tut, k(gauss) lwidth(thick) color(dkgreen)), xline(0) legend(off) ytitle(" ") xtitle("APR")
graph export "$directorio/Figuras/he_dist_tau_hat_tut.pdf", replace
	
