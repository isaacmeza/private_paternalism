
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification:  January. 26, 2022 
* Modifications: Add confidence intervals for HTE distribution		
* Files used:     
		- 
* Files created:  

* Purpose: 

*******************************************************************************/
*/

** RUN R CODE : grf.R

*TREATMENT ARM
local arm pro_2

set more off
graph drop _all
foreach depvar in  apr eff_cost_loan  def_c  fc_admin {

	*Load data with heterogeneous predictions & propensities (extended)
	import delimited "$directorio/_aux/grf_extended_`arm'_`depvar'.csv", clear

	*Confidence intervals for 
	gen lo_tau_hat = tau_hat_oobpredictions - 1.96*sqrt(tau_hat_oobvarianceestimates)
	gen hi_tau_hat = tau_hat_oobpredictions + 1.96*sqrt(tau_hat_oobvarianceestimates)
			
	*Overlap assumption	
	destring propensity_score, force replace
	twoway (kdensity propensity_score if !missing(`arm'), lpattern(solid) lwidth(medthick)) ///
			, ///
		scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Propensity score") ///
		legend(off)			
	graph export "$directorio\Figuras\ps_overlap_`depvar'_`arm'.pdf", replace
		
		
	*Heterogeneous effect distributions
	if strpos("`depvar'","fc")!=0 {
		cap drop esample
		su tau_hat_oobpredictions  , d
		gen esample = inrange(tau_hat_oobpredictions, `r(p1)', `r(p99)') 
		su lo_tau_hat, d
		replace lo_tau_hat = . if lo_tau_hat<=`r(p5)'
		su hi_tau_hat, d
		replace hi_tau_hat = . if hi_tau_hat>=`r(p95)'		
		qui kdensity tau_hat_oobpredictions if esample==1,  nograph 
		local width =  `r(bwidth)'
		}

	else {
		cap drop esample
		gen esample = 1 
		qui kdensity tau_hat_oobpredictions ,  nograph 
		local width =  `r(bwidth)'
		}
		
	do "$directorio\DoFiles\main_results\yaxis_kdensity.do" ///
		 "tau_hat_oobpredictions" "`width'" "esample" "uno"
		 
	twoway (hist tau_hat_oobpredictions if esample==1, xline(0, lcolor(gs8) lwidth(thick) lpattern(dot)) yaxis(1) ytitle("Percent", axis(1)) w(`width') percent lcolor(white) fcolor(none) ) ///		
		(kdensity tau_hat_oobpredictions if esample==1, yaxis(2) ylab(${uno}, notick nolab axis(2))  lpattern(solid) lcolor(black)) ///
		(kdensity lo_tau_hat if esample==1, yaxis(2) ylab(${uno}, notick nolab axis(2)) lcolor(navy) lpattern(dot)) ///		
		(kdensity hi_tau_hat if esample==1, yaxis(2) ylab(${uno}, notick nolab axis(2)) ///		
						ytitle(" ", axis(2)) xtitle("Effect")  ///
						lcolor(maroon) lwidth(thick) lpattern(dot)), ///
						legend(order(2 "HTE" 3 "Lower bound CI" 4 "Upper bound CI") rows(1))  graphregion(color(white))	
	graph export "$directorio\Figuras\he_dist_`depvar'_`arm'.pdf", replace

	****************************************************************************
	
	*Load data with BLP
	import delimited "$directorio/_aux/grf_`arm'_`depvar'_blp.csv", clear
	
	matrix blp_i = J(10, 6, .)
	matrix blp = J(10, 6, .)
	local row = 1
	foreach name in "log.loan" "subj.loan.value" "income.index" "pb" "makes.budget" "pawn.before" "subj.pr" "age" "female" "more.high.school"  {
		
		* Individual effect
		matrix blp_i[`row',1] = `row'
		// Beta 
		su estimate_i if term=="`name'", meanonly 
		matrix blp_i[`row',2] = `r(mean)'
	
		// Standard error
		su stderror_i if term=="`name'", meanonly
		matrix blp_i[`row',3] = `r(mean)'
		// P-value
		su pvalue_i if term=="`name'", meanonly
		matrix blp_i[`row',4] = `r(mean)'
		// Confidence Intervals
		matrix blp_i[`row',5] = blp_i[`row',2] - 1.96*blp_i[`row',3]
		matrix blp_i[`row',6] = blp_i[`row',2] + 1.96*blp_i[`row',3]
		
		*-------------------------------------------------------------
		
		* Total effect
		matrix blp[`row',1] = `row'
		// Beta 
		su estimate if term=="`name'", meanonly 
		matrix blp[`row',2] = `r(mean)'
	
		// Standard error
		su stderror if term=="`name'", meanonly
		matrix blp[`row',3] = `r(mean)'
		// P-value
		su pvalue if term=="`name'", meanonly
		matrix blp[`row',4] = `r(mean)'
		// Confidence Intervals
		matrix blp[`row',5] = blp[`row',2] - 1.96*blp[`row',3]
		matrix blp[`row',6] = blp[`row',2] + 1.96*blp[`row',3]
		local row = `row' + 1
	}
	matrix colnames blp_i = "k" "beta" "se" "p" "lo" "hi"
	matrix colnames blp = "k" "beta" "se" "p" "lo" "hi"
	mat rownames blp_i =  "Loan value" "Subjective value (std)" ///
		 "Income index" "Present bias"  "Makes budget" "Pawn before" "Prob recovery"  ///
		 "Age"  "Gender" "More high school" 	 
	mat rownames blp =  "Loan value" "Subjective value (std)" ///
		 "Income index" "Present bias"  "Makes budget" "Pawn before" "Prob recovery"  ///
		 "Age"  "Gender" "More high school" 		 
	
	*Load data with heterogeneous predictions & propensities 
	import delimited "$directorio/_aux/grf_`arm'_`depvar'.csv", clear
	
	*Variable interaction results

	local alpha = .05 // for 95% confidence intervals 

	matrix blp_reg = J(10, 6, .)
	local row = 1
	foreach var of varlist log_prestamo val_pren_std faltas pb plan_gasto_bin pres_antes pr_recup edad genero masqueprepa {
		
		qui reg tau_hat_oobpredictions `var', r
		local df = e(df_r)	
		
		matrix blp_reg[`row',1] = `row' + 10
		// Beta 
		matrix blp_reg[`row',2] = _b[`var']
		// Standard error
		matrix blp_reg[`row',3] = _se[`var']
		// P-value
		matrix blp_reg[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
		// Confidence Intervals
		matrix blp_reg[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
		matrix blp_reg[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
		
		local row = `row' + 1
	}
	matrix colnames blp_reg = "k" "beta" "se" "p" "lo" "hi"

	mat rownames blp_reg =  "Loan value" "Subjective value (std)" ///
		 "Income index" "Present bias"  "Makes budget" "Pawn before" "Prob recovery"  ///
		 "Age"  "Gender" "More high school" 
			 
	coefplot (matrix(blp_i[,2]), offset(0.06) ci((blp_i[,5] blp_i[,6]))  ciopts(lcolor(gs4))) ///
	(matrix(blp_reg[,2]), offset(-0.06) ci((blp_reg[,5] blp_reg[,6]))  ciopts(lcolor(gs4))) , ///
		headings("Loan value" = "{bf:Loan characteristics}" "Income index" = "{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(order(2 "AIPW DR" 4 "OLS"))  xline(0)  graphregion(color(white)) 
	graph export "$directorio\Figuras\HE\he_int_vertical_`depvar'_`arm'.pdf", replace


	}	
		
