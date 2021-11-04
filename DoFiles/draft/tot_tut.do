/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 20, 2021
* Last date of modification:  
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: TOT-TUT

*******************************************************************************/
*/


*Load data with eff_te predictions (created in eff_te_grf.R)
import delimited "$directorio/_aux/des_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_des tau_des)
tempfile temp_des
save `temp_des'

import delimited "$directorio/_aux/def_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_def tau_def)
tempfile temp_def
save `temp_def'

import delimited "$directorio/_aux/sumporcp_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_sum tau_sum)
tempfile temp_sum
save `temp_sum'

import delimited "$directorio/_aux/eff_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_eff tau_eff)

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
merge 1:1 prenda using `temp_des', nogen keep(3)
merge 1:1 prenda using `temp_def', nogen keep(3)
merge 1:1 prenda using `temp_sum', nogen keep(3)


********************************************************************************
eststo clear

* TOT-TUT using the Causal Forest
preserve

keep if t_prod==4
keep tau_eff tau_des choose_commitment  $C0

foreach var of varlist tau_eff  {
	ritest choose_commitment _b[choose_commitment], rep(1000) : reg `var' choose_commitment ,  r
	local rp = r(p)[1,1]
	eststo : reg `var' choose_commitment ,  vce(bootstrap, rep(2500))	
	su tau_eff if e(sample) 
	estadd scalar DepVarMean = `r(mean)'
	estadd scalar ri_p = `rp'
	*------------------------------
	ritest choose_commitment _b[choose_commitment], rep(1000) : reg `var' choose_commitment $C0 ,  r
	local rp = r(p)[1,1]
	eststo : reg `var' choose_commitment $C0 ,  vce(bootstrap, rep(2500))
	su tau_eff if e(sample) 
	estadd scalar DepVarMean = `r(mean)'
	estadd scalar ri_p = `rp'
	}

restore

*-------------------------------------------------------------------------------

* TOT-TUT using LATE approach


*IV
gen choice_nsq = (prod==5) 
gen choice_vs_control = (t_prod==4) if inlist(t_prod,4,1)
gen choice_nonsq = (prod!=4)
gen forced_fee_vs_choice = (t_prod==2) if inlist(t_prod,2,4)

foreach var of varlist eff_cost_loan  {
		*TOT
	eststo : ivregress 2sls `var'  (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	cap drop esample_tot
	gen esample_tot = e(sample)
	su tau_eff if e(sample) 
	estadd scalar DepVarMean = `r(mean)'
	eststo : ivregress 2sls `var'   $C0 (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	eststo : ivregress 2sls `var'   $C0  edad  faltas val_pren_std genero masqueprepa (choice_nsq =  choice_vs_control) , vce(bootstrap, rep(5000))

		*TUT
	eststo : ivregress 2sls `var'  (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
	cap drop esample_tut	
	gen esample_tut = e(sample)
	su tau_eff if e(sample) 
	estadd scalar DepVarMean = `r(mean)'	
	eststo : ivregress 2sls `var'  $C0 (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
	eststo : ivregress 2sls `var'  $C0  edad  faltas val_pren_std genero masqueprepa (choice_nonsq =  forced_fee_vs_choice) , vce(bootstrap, rep(5000))
	
	*----------------------
	preserve
	keep if esample_tot==1 | esample_tut==1
	keep `var' $C0  edad  faltas val_pren_std genero masqueprepa choice_nsq choice_vs_control choice_nonsq forced_fee_vs_choice esample_tot esample_tut prenda
	*Drop individuals without observables
	foreach var of varlist edad  faltas val_pren_std genero masqueprepa { 
		drop if missing(`var') 
	}
	export delimited "$directorio/_aux/tot_tut_`var'.csv", replace nolabel
	restore
	}
	

Save results	
esttab using "$directorio/Tables/reg_results/tot_tut.csv", se r2 ${star} b(a2) ///
		scalars("DepVarMean DepVarMean" "ri_p ri_p") replace 