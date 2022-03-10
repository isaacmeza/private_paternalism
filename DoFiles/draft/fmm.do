
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 6, 2021
* Last date of modification: February. 28, 2022 
* Modifications: Redefinition of cost/loan to be expressed as benefit (switch signs)		
	- Include APR
* Files used:     
		- 
* Files created:  

* Purpose: Identify types according to propensity to choose.

- Sophisticated hyperbolic:
		Choose commitment in choice arm, and would have defaulted in control arm.
- Naïve hyperbolics:
		Don't choose commitment in choice arm, default in control arm, repay if forced into commitment.

*******************************************************************************/
*/


*Load data with eff_te predictions (created in te_grf.R)
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
tempfile temp_eff
save `temp_eff'

import delimited "$directorio/_aux/apr_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_apr tau_apr)
tempfile temp_apr
save `temp_apr'

*Load data with propensity score (created in choice_prediction.ipynb)
import delimited "$directorio/_aux/prop_choose.csv", clear

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
merge 1:1 prenda using `temp_des', nogen keep(3)
merge 1:1 prenda using `temp_def', nogen keep(3)
merge 1:1 prenda using `temp_sum', nogen keep(3)
merge 1:1 prenda using `temp_eff', nogen keep(3)
merge 1:1 prenda using `temp_apr', nogen keep(3)

*-------------------------------------------------------------------------------


* Finite Mixture Model 
* The class (type) which is positively correlated with choose_commitment might be identified with sophisticated. The hypothesis is that this class is the less benefit from being forced.
eststo clear
eststo: fmm 2 if t_prod==4,  lcbase(2) lcprob(choose_commitment faltas pb i.plan_gasto pres_antes pr_recup   edad genero    masqueprepa) emopts(iter(2000))  difficult technique(nr dfp bfgs) startvalues(randomid) : logit def_c log_prestamo val_pren_pr

* Latent class marginal means
estat lcmean
mat lcmm1 = r(b)
mat lcmmsd1 = r(V)

estadd scalar prop_def1 = lcmm1[1,1]
estadd scalar prop_def1_lw = lcmm1[1,1] - 1.96*sqrt(lcmmsd1[1,1])
estadd scalar prop_def1_hi = lcmm1[1,1] + 1.96*sqrt(lcmmsd1[1,1])


esttab using "$directorio/Tables/reg_results/fmm_types.csv", se ${star} b(a2) ///
	scalars("prop_def1 prop_def1" "prop_def1_lw prop_def1_lw" "prop_def1_hi prop_def1_hi") replace 

		
* Latent class marginal probabilities	
estat lcprob
mat lcmp1 = r(b)
mat lcmpsd1 = r(V)

gen share1 = lcmp1[1,1]
gen share1_lw = lcmp1[1,1] - 1.96*sqrt(lcmpsd1[1,1])
gen share1_hi = lcmp1[1,1] + 1.96*sqrt(lcmpsd1[1,1])
		
* Prediction latent class probability
predict classpr*, classpr
* posterior
predict classpost*, classpost

* Relation between the Propensity of being Type 1 & the HTE
* A positive relation indicates that being Type 1 has less benefits from being forced
binscatter tau_apr classpr1 if t_prod==4, xtitle("Probability of being Type 1") ytitle("Effective APR benefit TE") 
graph export "$directorio\Figuras\binscatter_tau_classpr.pdf", replace
binscatter tau_apr classpost1 if t_prod==4, xtitle("Posterior probability of being Type 1") ytitle("Effective APR benefit TE") 
graph export "$directorio\Figuras\binscatter_tau_classpost.pdf", replace


* Correlation between HTE from being forced and propensity of being Type 1
cap drop beta lw lwp hi hip prop_clase_1 prop_clasep_1
cap drop betap
local alpha = .05 // for 95% confidence intervals 

gen beta =.
gen betap = .
gen lw =.
gen lwp = .
gen hi =.
gen hip = .
gen prop_clase_1 = .
gen prop_clasep_1 = .

forvalues t = 10/90 {
	cap drop clase_1 
	cap drop clasep_1
	gen clase_1 = (classpr1>=`t'/100) if !missing(classpr1)
	su clase_1
	replace prop_clase_1 = r(mean) in `t'
	gen clasep_1 = (classpost1>=`t'/100) if !missing(classpost1)
	su clasep_1
	replace prop_clasep_1 = r(mean) in `t'
	
	qui reg tau_apr clase_1 if t_prod==4 , r 
	replace beta = _b[clase_1] in `t'
	replace lw = _b[clase_1] - invttail(`e(df_r)',`=`alpha'/2')*_se[clase_1] in `t'
	replace hi = _b[clase_1] + invttail(`e(df_r)',`=`alpha'/2')*_se[clase_1] in `t'
	
	qui reg tau_apr clasep_1 if t_prod==4 , r 	
	replace betap = _b[clasep_1] in `t'
	replace lwp = _b[clasep_1] - invttail(`e(df_r)',`=`alpha'/2')*_se[clasep_1] in `t'
	replace hip = _b[clasep_1] + invttail(`e(df_r)',`=`alpha'/2')*_se[clasep_1] in `t'
	
}

cap drop prob_threshold
gen prob_threshold = _n 


* Change in benefit for Type 1 individuals
twoway 	(rarea lwp hip prob_threshold if inrange(prob_threshold, 10,90), color(navy*.9) xaxis(1) yaxis(1) xlabel(10(10)90, axis(1))) ///
	(line betap prob_threshold if inrange(prob_threshold, 10,90), yline(0) lpattern(solid) xaxis(1) yaxis(1) xlabel(10(10)90)) ///
	(rarea share1_lw share1_hi prob_threshold if inrange(prob_threshold, 10,90), color(gs5%25) xaxis(2) yaxis(2) xlabel(10(10)90, nolabel noticks axis(2))) ///
	(line share1 prob_threshold if inrange(prob_threshold, 10,90), lpattern(dot) lwidth(medthick) color(black) xaxis(2) yaxis(2) xlabel(10(10)90, nolabel noticks axis(2))) ///	
	(line prop_clasep_1 prob_threshold if inrange(prob_threshold, 10,90), color(red%70)  lpattern(solid) xaxis(2) yaxis(2) xlabel(10(10)90, nolabel noticks axis(2))) , scheme(s2mono) graphregion(color(white)) ///
	legend(order(2 "Change in benefit" 5 "Proportion of Type 1 individuals")) xtitle("Probability threshold", axis(1)) xtitle("", axis(2)) ytitle("Change in benefit for Type 1 individuals", axis(1)) ytitle("Proportion", axis(2)) 
graph export "$directorio\Figuras\benefit_type1p.pdf", replace


twoway 	(rarea lw hi prob_threshold if inrange(prob_threshold, 10,90), color(navy*.9) xaxis(1) yaxis(1) xlabel(10(10)90, axis(1))) ///
	(line beta prob_threshold if inrange(prob_threshold, 10,90), yline(0) lpattern(solid) xaxis(1) yaxis(1) xlabel(10(10)90)) ///
	(rarea share1_lw share1_hi prob_threshold if inrange(prob_threshold, 10,90), color(gs5%25) xaxis(2) yaxis(2) xlabel(10(10)90, nolabel noticks axis(2))) ///
	(line share1 prob_threshold if inrange(prob_threshold, 10,90), lpattern(dot) lwidth(medthick) color(black) xaxis(2) yaxis(2) xlabel(10(10)90, nolabel noticks axis(2))) ///	
	(line prop_clase_1 prob_threshold if inrange(prob_threshold, 10,90), color(red%70)  lpattern(solid) xaxis(2) yaxis(2) xlabel(10(10)90, nolabel noticks axis(2))) , scheme(s2mono) graphregion(color(white)) ///
	legend(order(2 "Change in benefit" 5 "Proportion of Type 1 individuals")) xtitle("Probability threshold", axis(1)) xtitle("", axis(2)) ytitle("Change in benefit for Type 1 individuals", axis(1)) ytitle("Proportion", axis(2)) 
graph export "$directorio\Figuras\benefit_type1.pdf", replace
	


