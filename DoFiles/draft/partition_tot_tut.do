
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Feb. 28, 2023
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Partition of ToT & TuT by binary variable

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

replace fc_admin = -fc_admin
replace apr = -apr*100
 
*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4
	

matrix behavioral_te = J(2*2,8,.)
matrix prob_weights = J(2*2,4,.)

local k = 1
local j = 1


foreach var of varlist  confidence_100  pb {
	
	tot_tut fc_admin Z choose_commitment if !missing(`var'),  vce(cluster suc_x_dia)
	local tot = _b[ToT]
	local tut = _b[TuT]
	
	forvalues i = 0/1 {
		tot_tut fc_admin Z choose_commitment if `var'==`i',  vce(cluster suc_x_dia)	
		local df = e(df_r)
		matrix behavioral_te[`k',1] = _b[ToT]/(`tot')
		matrix behavioral_te[`k',2] = _se[ToT]/(`tot')
		matrix behavioral_te[`k',3] = 2*ttail(`df', abs(_b[ToT]/_se[ToT]))	
		
		matrix behavioral_te[`k',4] = _b[TuT]/(`tut')
		matrix behavioral_te[`k',5] = _se[TuT]/(`tut')
		matrix behavioral_te[`k',6] = 2*ttail(`df', abs(_b[TuT]/_se[TuT]))	
		
		matrix behavioral_te[`k',7] = `i'
		matrix behavioral_te[`k',8] = `j'
		
		local k = `k' + 1
		}
		
	*Estimated weights	
	su `var' if choose_commitment==1
	matrix prob_weights[`=`k'-2',1] = 1-`r(mean)'
	matrix prob_weights[`=`k'-1',1] = `r(mean)'
	su `var' if choose_commitment==0
	matrix prob_weights[`=`k'-2',2] = 1-`r(mean)'
	matrix prob_weights[`=`k'-1',2] = `r(mean)'		
	
	*Exact weights
	matrix prob_weights[`=`k'-2',3] = 1-(1-behavioral_te[`=`k'-2',1])/(behavioral_te[`=`k'-1',1]-behavioral_te[`=`k'-2',1])
	matrix prob_weights[`=`k'-1',3] = 1 - prob_weights[`=`k'-2',3]
	
	matrix prob_weights[`=`k'-2',4] = 1-(1-behavioral_te[`=`k'-2',4])/(behavioral_te[`=`k'-1',4]-behavioral_te[`=`k'-2',4])
	matrix prob_weights[`=`k'-1',4] = 1 - prob_weights[`=`k'-2',4]
	
	local j = `j' + 1
}	

clear 
svmat behavioral_te
svmat prob_weights

rename (behavioral_te2 behavioral_te5) (behavioral_te1_se behavioral_te4_se)

label define behavioral_var   1 "Sure-confidence" 2 "P.B." 
label values behavioral_te8 behavioral_var


*TE weighted by estimated prob_weights
gen behavioural_tot_weighted = behavioral_te1
gen behavioural_tut_weighted = behavioral_te4

gen behavioural_tot_weighted_e = behavioral_te1
gen behavioural_tot_weighted_e_se = behavioral_te1_se

gen behavioural_tut_weighted_e = behavioral_te4
gen behavioural_tut_weighted_e_se = behavioral_te4_se

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
foreach var of varlist behavioral_te1 behavioral_te4 behavioural_tot_weighted_e behavioural_tut_weighted_e  {
	gen `var'_lo = `var' - invttail(257,`=`alpha'/2')*`var'_se
	gen `var'_hi = `var' + invttail(257,`=`alpha'/2')*`var'_se
}


keep behavioral_te1 prob_weights3 behavioral_te3 behavioral_te4 prob_weights4 behavioral_te6 behavioural_tot_weighted_e behavioural_tut_weighted_e behavioral_te7 behavioral_te8

reshape wide behavioral_te1 prob_weights3 behavioral_te3 behavioral_te4 prob_weights4 behavioral_te6 behavioural_tot_weighted_e behavioural_tut_weighted_e , i(behavioral_te8) j(behavioral_te7)

*Aux plotting variables
gen indx_par = behavioral_te8 
replace indx_par = indx_par*2 + 2*_n
gen indx_impar = (behavioral_te8*2-1) + 2*_n

*Significance stars
*TuT----------------------------------------------------------------------------	
gen sig_1_0 = behavioural_tut_weighted_e0 + sign(behavioural_tut_weighted_e0)*0.10 if behavioral_te60<0.01
gen sig_5_0 = behavioural_tut_weighted_e0 + sign(behavioural_tut_weighted_e0)*0.125 if behavioral_te60<0.05
gen sig_10_0 = behavioural_tut_weighted_e0 + sign(behavioural_tut_weighted_e0)*0.15 if behavioral_te60<0.1

gen sig_1_1 = behavioural_tut_weighted_e1 + sign(behavioural_tut_weighted_e1)*0.10 if behavioral_te61<0.01
gen sig_5_1 = behavioural_tut_weighted_e1 + sign(behavioural_tut_weighted_e1)*0.125 if behavioral_te61<0.05
gen sig_10_1 = behavioural_tut_weighted_e1 + sign(behavioural_tut_weighted_e1)*0.15 if behavioral_te61<0.1
	

twoway (bar behavioural_tut_weighted_e0  indx_impar, horizontal) (bar behavioural_tut_weighted_e1  indx_par, horizontal) ///
	(scatter indx_impar sig_1_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_5_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_10_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	(scatter indx_par sig_1_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_5_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_10_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	, xline(0, lpattern(solid) lwidth(medthick)) ylabel(3  "Sure-confidence" 7 "P.B.", labsize(large) ) legend(order(1 "=0" 2 "=1") pos(6) rows(1))
graph export "$directorio/Figuras/tut_beh_partition.pdf", replace	
	
