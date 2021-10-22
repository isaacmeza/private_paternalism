/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 10, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- 
* Files created:  

* Purpose: We investigate the relation between choice (commitment) and benefit. First, we compute the Treatment Effect benefit in the control vs fee arm. Then, we calculate a propensity to choose commitment, and analyze the correlation between this two variables.

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
tempfile temp_eff
save `temp_eff'

*Load data with propensity score (created in choice_prediction.ipynb)
import delimited "$directorio/_aux/prop_choose.csv", clear

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
merge 1:1 prenda using `temp_des', nogen keep(3)
merge 1:1 prenda using `temp_def', nogen keep(3)
merge 1:1 prenda using `temp_sum', nogen keep(3)
merge 1:1 prenda using `temp_eff', nogen keep(3)


* Correlation between propensity to choose and benefit when choose forced fee.
reg tau_eff pr_gbc_1  , r 
reg tau_def pr_gbc_1  , r 
reg tau_des pr_gbc_1  , r 
reg tau_sum pr_gbc_1  , r 



binscatter tau_eff pr_gbc_1, nq(99) savedata("$directorio/_aux/bin_tau_pr1") replace 
binscatter tau_eff pr_gbc_1 if pr_gbc_1>0.30, nq(11) savedata("$directorio/_aux/bin_tau_pr2") replace 

preserve
import delimited "$directorio/_aux/bin_tau_pr2.csv", clear
tempfile temp
gen sct = 2
save `temp'

import delimited "$directorio/_aux/bin_tau_pr1.csv", clear
append using `temp'

* Generate smoothing line
lpoly tau_eff pr_gbc_1 if sct!=2, deg(1) ci gen(x s) se(se) nograph
lpoly tau_eff pr_gbc_1 if sct==2 , deg(5) ci gen(x2 s2) se(se2) nograph

*Interpolation
replace se = . if se<0.0000001
ipolate s x, generate(s_aux) epolate

* CI
gen lw = s_aux - 1.96*se
gen hi = s_aux + 1.96*se


twoway (rarea hi lw x) (line s_aux x, lpattern(solid)) (lfit tau_eff pr_gbc_1 if sct!=2, lpattern(dot) lwidth(medthick) color(black)) (scatter tau_eff pr_gbc_1 if sct!=2, color(navy) msymbol(O)) ///
		, legend(off) scheme(s2mono) graphregion(color(white)) xtitle("Probability to choose commitment") ytitle("Effective cost/loan benefit TE") 
graph export "$directorio\Figuras\benefit_choice.pdf", replace
restore	

*-------------------------------------------------------------------------------


local alpha = .05 // for 95% confidence intervals 

matrix choice = J(10, 6, .)
local row = 1
foreach var of varlist log_prestamo val_pren_std faltas pb plan_gasto_bin pres_antes pr_recup edad genero masqueprepa {
	
	qui reg pr_gbc_1 `var', r
	local df = e(df_r)	
	
	matrix choice[`row',1] = `row'
	// Beta 
	matrix choice[`row',2] = _b[`var']
	// Standard error
	matrix choice[`row',3] = _se[`var']
	// P-value
	matrix choice[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix choice[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix choice[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	local row = `row' + 1
}
matrix colnames choice = "k" "beta" "se" "p" "lo" "hi"

mat rownames choice =  "Loan value" "Subjective value (std)" ///
	 "Income index" "Present bias"  "Makes budget" "Pawn before" "Prob recovery"  ///
	 "Age"  "Gender" "More high school" 
	 	 
coefplot (matrix(choice[,2]), ci((choice[,5] choice[,6]))  ciopts(lcolor(gs4))), ///
	headings("Loan value" = "{bf:Loan characteristics}" "Income index" = "{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(off) offset(0) xline(0)  graphregion(color(white)) 
graph export "$directorio\Figuras\HE\ps_int_vertical_pr_gbc_1.pdf", replace

