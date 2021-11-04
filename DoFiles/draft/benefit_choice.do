/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 10, 2021
* Last date of modification: November. 4, 2021  
* Modifications: Different ways to graph choice_benefit plot	
				Discretize predicted probability and plot CDF's to identify Stochasic Dominance
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

su choose_commitment if t_prod==4
di 100-round(`r(mean)'*100)
*Percentile to identify cut in predicted probability
local perc_pr_gbc = 100-round(`r(mean)'*100)
xtile perc =  pr_gbc_1, nq(100)
su pr_gbc_1 if  perc==`perc_pr_gbc'
gen predicted_choose = pr_gbc_1>=`r(mean)'
tempfile tempmaster
save `tempmaster'
	
*-------------------------------------------------------------------------------
foreach var of varlist tau_eff tau_des {
	binscatter `var' pr_gbc_1, nq(99) savedata("$directorio/_aux/bin_tau_pr1") replace 
	binscatter `var' pr_gbc_1 if pr_gbc_1>0.30, nq(11) savedata("$directorio/_aux/bin_tau_pr2") replace 

	preserve
	import delimited "$directorio/_aux/bin_tau_pr2.csv", clear
	tempfile temp
	gen sct = 2
	save `temp'

	import delimited "$directorio/_aux/bin_tau_pr1.csv", clear
	append using `temp'

	* Generate smoothing line
	lpoly `var' pr_gbc_1 if sct!=2, deg(1) ci gen(x s) se(se) nograph
	lpoly `var' pr_gbc_1 if sct==2 , deg(5) ci gen(x2 s2) se(se2) nograph

	*Interpolation
	replace se = . if se<0.0000001
	ipolate s x, generate(s_aux) epolate

	* CI
	gen lw = s_aux - 1.96*se
	gen hi = s_aux + 1.96*se

	*Continuous plot
	twoway (rarea hi lw x) (line s_aux x, lpattern(solid)) (lfit `var' pr_gbc_1 if sct!=2, lpattern(dot) lwidth(medthick) color(black)) (scatter `var' pr_gbc_1 if sct!=2, color(navy) msymbol(O)) ///
			, legend(off) scheme(s2mono) graphregion(color(white)) xtitle("Probability to choose commitment") ytitle("Effective cost/loan benefit TE") 
	graph export "$directorio\Figuras\benefit_choice_`var'.pdf", replace


	*Discretize predicted probability and plot CDF's to identify Stochasic Dominance
	use `tempmaster', clear

	twoway (hist `var' if predicted_choose==0, percent color(navy%70) ) (hist `var' if predicted_choose==1 ,color(none) lcolor(black) percent), xtitle("Effective cost/loan benefit TE") scheme(s2mono) graphregion(color(white)) legend(order(1 "No Choose" 2 "Choose"))
	graph export "$directorio\Figuras\hist_predchoose_`var'.pdf", replace


	*ECDF
	cumul `var' if predicted_choose==1, gen(t1)
	cumul `var' if predicted_choose==0, gen(t0)

	*Function to obtain significance difference region
	distcomp `var' , by(predicted_choose) alpha(0.1) p noplot
	mat ranges = r(rej_ranges)

	*To plot both ECDF
	stack  t1 `var'  t0 `var', into(c inst) ///
		wide clear
	keep if !missing(t1) | !missing(t0)
	tempfile temp
	save `temp'
	*Get difference of the CDF
	duplicates drop inst _stack, force
	keep c inst _stack
	reshape wide c, i(inst) j(_stack)
	*Interpolate
	ipolate c2 inst, gen(c2_i) epolate
	ipolate c1 inst, gen(c1_i) epolate
	gen dif=c2_i-c1_i
	tempfile temp_dif
	save `temp_dif'
	use `temp', clear
	merge m:1 inst using `temp_dif', nogen 
	*Signifficant region
	gen sig_range = .
	local rr = rowsof(ranges)
	forvalues i=1/`rr' {
		local lo = ranges[`i',1]
		local hi = ranges[`i',2]
		replace sig_range = 0.01 if inrange(inst,`lo',`hi')
		}

	*Plot
	twoway (line t1 t0 inst , ///
		sort ylab(, grid)) ///
		(line sig_range inst , lcolor(navy)) , ///
		legend(order(1 "Choose" 2 "No Choose") rows(1)) xtitle("T.effect") scheme(s2mono) graphregion(color(white)) 
	graph export "$directorio/Figuras/cdf_predchoose_`var'.pdf", replace
	restore	
}
*-------------------------------------------------------------------------------


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

