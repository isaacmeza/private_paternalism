
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
		- eff_narrow_te_grf.csv, eff_te_grf.csv
		- eff_narrow_te_grf.csv, eff_admin_te_grf.csv
		- Master.dta
* Files created:  

* Purpose: Comparison narrow & wide forest. 

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : te_narrow_grf.R, te_grf.R

********************************************************************************


*Load data with forest predictions 

import delimited "$directorio/_aux/apr_te_grf.csv", clear
tempfile temp_eff
rename tau_hat_oobpredictions tau_hat_eff
rename tau_hat_oobvarianceestimates var_hat_eff
save `temp_eff'

import delimited "$directorio/_aux/apr_narrow_te_grf.csv", clear
rename tau_hat_oobpredictions tau_hat_eff_narrow
rename tau_hat_oobvarianceestimates var_hat_eff_narrow

merge 1:1 prenda using `temp_eff', nogen
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
keep if inlist(t_prod,4)

********************************************************************************

gen tau_sim = . 
gen tau_sim_narrow = . 
gen better_forceall = 0

gen bfa = 0
gen bfa_normal_l = .
gen bfa_normal_h = .


gen acc_fit = .
gen acc_fit_l = .
gen acc_fit_h = .

gen type_i = .
gen type_i_l = .
gen type_i_h = .

gen type_ii = .
gen type_ii_l = .
gen type_ii_h = .

gen acc_fit_lg = .
gen acc_fit_lg_l = .
gen acc_fit_lg_h = .

gen type_i_lg = .
gen type_i_lg_l = .
gen type_i_lg_h = .

gen type_ii_lg = .
gen type_ii_lg_l = .
gen type_ii_lg_h = .

local k = 1
forvalues i = -10(1)10 {
	gen bfa_normal_l`k' = .
	gen bfa_normal_h`k' = .
	
	gen acc_fit_`k' = .
	gen type_i_`k' = .
	gen type_ii_`k' = .
	
	gen acc_fit_lg_`k' = .
	gen type_i_lg_`k' = .
	gen type_ii_lg_`k' = .
	
	local k = `k' + 1
	}

	
	
local k = 1
forvalues i = -10(1)10 {	
	di "`k'"
	
	*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
	local rep_num = 100
	forvalues rep = 1/`rep_num' {
		qui {
			
			*Draw random effect from normal distribution with standard error according to Athey
		replace tau_sim = rnormal(tau_hat_eff, sqrt(var_hat_eff))	
		replace tau_sim_narrow = rnormal(tau_hat_eff_narrow, sqrt(var_hat_eff_narrow))		

		*------------------------------Wide forest------------------------------	

		*If we were to force everyone to the FEE contract, how many would be
		* benefited from this policy?
		replace bfa = .
		replace bfa = (tau_sim>`=`i'/100') if !missing(tau_sim) & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su bfa
		estat bootstrap, all
		mat point_estimate = e(b)
		replace better_forceall = better_forceall + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace bfa_normal_l`k' =  confidence_int[1,1]*100 in `rep'
			replace bfa_normal_h`k' =  confidence_int[2,1]*100 in `rep'
		
			
		*-----------------------------------------------------------------------
		*-----------------------------------------------------------------------
		*-----------------------------------------------------------------------
		
		*Identification of positive TE with narrow variables
		preserve
		keep if !missing(bfa)
		su bfa
		if `r(sd)'!=0 {
			*Random Forest
			rforest bfa genero pres_antes masqueprepa edad , type(class) iter(1500) numvars(4) seed(1) 
			predict fit_fit_rf0 fit_fit_rf1, pr
			
			xtile perc_fit_rf = fit_fit_rf1, nq(100)
			su bfa, d
			su fit_fit_rf1 if inlist(perc_fit_rf, 100-ceil(`r(mean)'*100))
			if `r(N)'==0 {
				su bfa, d
				su fit_fit_rf1 if inrange(perc_fit_rf, 100-ceil(`r(mean)'*100)-1, 100-ceil(`r(mean)'*100)+1) 
			}

			replace fit_fit_rf1 = (fit_fit_rf1>=`r(mean)') 
			
			count
			local num_t = `r(N)'
			count if fit_fit_rf1==1 & bfa==1 | fit_fit_rf1==0 & bfa==0
			local accuracy = `r(N)'/`num_t'	* 100	
			
			count if fit_fit_rf1==0 & bfa==1
			local type_i = `r(N)'/`num_t'	* 100
			
			count if fit_fit_rf1==1 & bfa==0
			local type_ii = `r(N)'/`num_t'	* 100
			
			*Logit
			logit bfa genero pres_antes masqueprepa edad
			predict fit_fit_lg
			
			xtile perc_fit_lg = fit_fit_lg, nq(100)
			su bfa, d
			su fit_fit_lg if inlist(perc_fit_lg, 100-ceil(`r(mean)'*100))
			if `r(N)'==0 {
				su bfa, d
				su fit_fit_lg if inrange(perc_fit_lg, 100-ceil(`r(mean)'*100)-1, 100-ceil(`r(mean)'*100)+1)  
			}

			replace fit_fit_lg = (fit_fit_lg>=`r(mean)') 
			
			count
			local num_t = `r(N)'
			count if fit_fit_lg==1 & bfa==1 | fit_fit_lg==0 & bfa==0
			local accuracy_lg = `r(N)'/`num_t'	* 100	
			
			count if fit_fit_lg==0 & bfa==1
			local type_i_lg = `r(N)'/`num_t'	* 100
			
			count if fit_fit_lg==1 & bfa==0
			local type_ii_lg = `r(N)'/`num_t'	* 100
		}
		else {
			local accuracy =  100
			local type_i = 0
			local type_ii = 0
			
			local accuracy_lg =  100
			local type_i_lg = 0
			local type_ii_lg = 0			
		}
		restore

		replace acc_fit_`k' = `accuracy' in `rep'
		replace type_i_`k' = `type_i' in `rep'
		replace type_ii_`k' = `type_ii' in `rep'
		
		replace acc_fit_lg_`k' = `accuracy_lg' in `rep'
		replace type_i_lg_`k' = `type_i_lg' in `rep'
		replace type_ii_lg_`k' = `type_ii_lg' in `rep'
		
		}
		}
		
		local k = `k' + 1

	}	

*Recover the means
foreach var of varlist better_forceall {
	replace `var' = `var'/`rep_num'
	}


*Distribution of the CI
local k = 1
forvalues i = -10(1)10 {
	foreach vr in bfa_normal  {
		su `vr'_l`k', d
		replace `vr'_l = `r(p5)' in `k'
		replace `vr'_l = 0 if `vr'_l < 0 & !missing(`vr'_l )
		su `vr'_h`k', d
		replace `vr'_h = `r(p95)' in `k'
		replace `vr'_h = 100 if `vr'_h > 100 & !missing(`vr'_h )
	}
	
	foreach var in acc_fit type_i type_ii acc_fit_lg type_i_lg type_ii_lg {
		su `var'_`k', d
		replace `var' = `r(mean)' in `k'
		replace `var'_l = `r(p5)' in `k'
		replace `var'_h = `r(p95)' in `k'
	}
	
	local k = `k' + 1
	}

gen threshold = -10 + (_n-1)*1 if (_n-1)*1<=20
save "$directorio/_aux/wide_narrow_fit.dta", replace

*-------------------------------------------------------------------------------

use "$directorio/_aux/wide_narrow_fit.dta", clear


*Accuracy of rules
replace better_forceall = . if missing(threshold)

twoway (function y = 100, range(-10 10) lcolor(black) lwidth(medthick) lpattern(solid)) ///
	(rarea bfa_normal_l bfa_normal_h threshold, lcolor(navy%5) fcolor(navy%50) fintensity(40)) ///
	(line better_forceall threshold, lpattern(solid) lwidth(thick) lcolor(navy)) ///
	(scatter better_forceall threshold,  msymbol(X) color(navy) ) ///
	(rarea acc_fit_l acc_fit_h threshold, fcolor(dkgreen%50) lcolor(dkgreen%5) fintensity(40)) ///
	(line acc_fit threshold, lpattern(solid) lwidth(medthick) lcolor(dkgreen)) ///
	(scatter acc_fit threshold,  msymbol(x) color(dkgreen) ) ///
	(rarea acc_fit_lg_l acc_fit_lg_h threshold, fcolor(maroon%50) lcolor(maroon%5) fintensity(40)) ///
	(line acc_fit_lg threshold, lpattern(solid) lwidth(medthick) lcolor(maroon)) ///
	(scatter acc_fit_lg threshold,  msymbol(x) color(maroon) ) ///
	, legend(order( 1 "Optimal rule (WF)" 3 "Universal paternalism" 6 "Narrow rule (RF)" 9 "Narrow rule (Logit)") pos(6) rows(1))  ///
	graphregion(color(white)) xtitle("APR threshold") ///
	ytitle("% benefitted") ///
	xline(0, lcolor(black) lwidth(medthick) lpattern(dash)) 
graph export "$directorio/Figuras/wide_narrow_rule.pdf", replace

*-------------------------------------------------------------------------------

*Choice type error (choose_wrong_quant_wrong_tot_tut.do)
replace threshold = -1000.5 if missing(threshold)
merge m:m threshold using "$directorio/_aux/choose_wrong_tot_tut.dta", nogen keepusing(cwf cwf_choose cwf_nonchoose) keep(1 3)
replace threshold = . if threshold==-1000.5 


*Table with both type errors
putexcel set "$directorio\Tables\hit_miss_rule.xlsx", sheet("hit_miss_rule") modify

*Universal paternalism
su better_forceall if threshold==0
	*Control
putexcel H5 = matrix(`r(mean)')
	*Commitment
putexcel I6 = matrix(`=100-`r(mean)'')
  
*Narrow rule (RF)  
su type_i if threshold==0  
putexcel H8 = matrix(`r(mean)')
su type_ii if threshold==0  
putexcel I8 = matrix(`r(mean)')

*Narrow rule (Logit)  
su type_i_lg if threshold==0  
putexcel H9 = matrix(`r(mean)')
su type_ii_lg if threshold==0  
putexcel I9 = matrix(`r(mean)')

*Choice  
	*Non-choosers incorrectly assigned to control
su cwf_nonchoose if threshold==0  
putexcel H10 = matrix(`r(mean)')
	*Choosers incorrectly assigned to control
su cwf_choose if threshold==0  
putexcel I10 = matrix(`r(mean)')
	*Weighted sum
su cwf if threshold==0  
putexcel J10 = matrix(`r(mean)')
	
*-------------------------------------------------------------------------------

*Scatter - histogram	

preserve
reg tau_sim_narrow tau_sim
local r2 = round(e(r2),0.001)

cap drop x0 d0 x1 d1
*Scatter plot
twoway (scatter tau_sim_narrow tau_sim, msymbol(smcircle_hollow) text(1.25 -0.5 "R-squared : `r2'")) (lfitci tau_sim_narrow tau_sim, lcolor(navy)) (line tau_sim tau_sim, sort lcolor(black) lpattern(dash)),  saving(sct,replace)  legend(off) xsc(off) ysc(off)  ///
xti("") yti("") xlab(-1(.5)2,nolab) ylab(-1(.5)2,nolab)

*Marginals
kdensity tau_sim_narrow, k(gauss) gen(x0 d0)
line x0 d0, xsc(rev off) ysc(alt) xlab(,nolab) ylab(-1(.5)2) xtick(,notick) saving(hist0, replace) fxsize(40) ytitle("Narrow forest")
kdensity tau_sim,  k(gauss) gen(x1 d1)
line d1 x1, xsc(alt) ysc(rev off) ylab(,nolab) xlab(-1(.5)2) ytick(,notick) saving(hist1, replace) fysize(35) xtitle("Wide forest")

*Scatter with marginals
graph combine hist0.gph sct.gph hist1.gph, cols(2) holes(3) imargin(0 0 0 0)  
graph export "$directorio/Figuras/scatter_hist_wide_narrow.pdf", replace
restore







