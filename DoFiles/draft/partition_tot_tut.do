
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
replace des_c = des_c*100
replace def_c = -def_c*100
replace ref_c = -ref_c*100
 
*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4


*Behavioral variables
gen confidence_100 = (pr_recup==100) if !missing(pr_recup)
gen confidence_50 = (pr_recup>=50) if !missing(pr_recup)

gen distressed = (f_estres==1)*(r_estress==1) if !missing(f_estres) & !missing(r_estress)
gen tentacion = (tempt==3) if !missing(tempt)
	

matrix behavioral_te = J(11*2,8,.)
matrix prob_weights = J(11*2,4,.)
matrix prob_take = J(11*2,3,.)

local k = 1
local j = 1


foreach var of varlist pb confidence_100  confidence_50 genero fam_pide plan_gasto  ahorros otra_prenda cta_tanda distressed tentacion {
	
	reg choose_commitment `var', r 
	local df = e(df_r)
	matrix prob_take[`k',1] = _b[`var']
	matrix prob_take[`k',2] = _se[`var']
	matrix prob_take[`k',3] = 2*ttail(`df', abs(_b[`var']/_se[`var']))	
	
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
svmat prob_take

rename (behavioral_te2 behavioral_te5 prob_take2) (behavioral_te1_se behavioral_te4_se prob_take1_se)

label define behavioral_var 1 "P.B." 2 "Sure-confidence" 3 "Half-confidence" 4 "Woman" 5 "Fam. asks" 6 "Makes budget" 7 "Savings" 8 "Extra pawn" 9 "ROSCA" 10 "Distressed" 11 "Tempted"
label values behavioral_te8 behavioral_var


*TE weighted by estimated prob_weights
gen behavioural_tot_weighted = behavioral_te1*prob_weights1
gen behavioural_tut_weighted = behavioral_te4*prob_weights2

gen behavioural_tot_weighted_e = behavioral_te1*prob_weights3
gen behavioural_tot_weighted_e_se = behavioral_te1_se*prob_weights3

gen behavioural_tut_weighted_e = behavioral_te4*prob_weights4
gen behavioural_tut_weighted_e_se = behavioral_te4_se*prob_weights3

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
foreach var of varlist behavioral_te1 behavioral_te4 behavioural_tot_weighted_e behavioural_tut_weighted_e  {
	gen `var'_lo = `var' - invttail(257,`=`alpha'/2')*`var'_se
	gen `var'_hi = `var' + invttail(257,`=`alpha'/2')*`var'_se
}

gen prob_take1_lo = prob_take1 - invnormal(`=`alpha'/2')*prob_take1_se
gen prob_take1_hi = prob_take1 + invnormal(`=`alpha'/2')*prob_take1_se


keep behavioral_te1 prob_weights3 behavioral_te3 behavioral_te4 prob_weights4 behavioral_te6 behavioural_tot_weighted_e behavioural_tut_weighted_e prob_take1 prob_take3 behavioral_te7 behavioral_te8

reshape wide behavioral_te1 prob_weights3 behavioral_te3 behavioral_te4 prob_weights4 behavioral_te6 behavioural_tot_weighted_e behavioural_tut_weighted_e prob_take1 prob_take3, i(behavioral_te8) j(behavioral_te7)

*Aux plotting variables
gen indx_par = behavioral_te8 
replace indx_par = indx_par*2 + 2*_n
gen indx_impar = (behavioral_te8*2-1) + 2*_n

*Significance stars
cap drop sig_*
gen sig_1_0 = behavioral_te10 + sign(behavioral_te10)*0.10 if behavioral_te30<0.01
gen sig_5_0 = behavioral_te10 + sign(behavioral_te10)*0.125 if behavioral_te30<0.05
gen sig_10_0 = behavioral_te10 + sign(behavioral_te10)*0.15 if behavioral_te30<0.1

gen sig_1_1 = behavioral_te11 + sign(behavioral_te11)*0.10 if behavioral_te31<0.01
gen sig_5_1 = behavioral_te11 + sign(behavioral_te11)*0.125 if behavioral_te31<0.05
gen sig_10_1 = behavioral_te11 + sign(behavioral_te11)*0.15 if behavioral_te31<0.1


*TOT----------------------------------------------------------------------------
twoway (bar behavioral_te10  indx_impar if behavioral_te30<0.1, horizontal) (bar behavioral_te11  indx_par if behavioral_te31<0.1, horizontal) ///
	(bar behavioral_te10  indx_impar, horizontal fcolor("31 119 180%20")) (bar behavioral_te11  indx_par, horizontal fcolor("255 127 14%20")) ///
	(scatter indx_impar sig_1_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_5_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_10_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	(scatter indx_par sig_1_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_5_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_10_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	(scatter indx_impar prob_weights30, msymbol(Oh) color(gs4%90) mlwidth(medthick) msize(vsmall)) (scatter indx_par prob_weights31, msymbol(Oh) color(gs4%90) mlwidth(medthick) msize(vsmall) ), xline(0, lpattern(solid) lwidth(medthick)) ylabel(3 "P.B." 7 "Sure confidence" 11 "Half-confidence" 15 "Woman" 19 "Fam. asks" 23 "Makes budget" 27 "Savings" 31 "Extra pawn" 35 "ROSCA" 39 "Distressed" 43 "Tempted") legend(order(1 "=0" 2 "=1") pos(6) rows(1))	
graph export "$directorio/Figuras/tot_beh_partition_pr.pdf", replace
	
	
drop sig_*	
gen sig_1_0 = behavioural_tot_weighted_e0 + sign(behavioural_tot_weighted_e0)*0.10 if behavioral_te30<0.01
gen sig_5_0 = behavioural_tot_weighted_e0 + sign(behavioural_tot_weighted_e0)*0.125 if behavioral_te30<0.05
gen sig_10_0 = behavioural_tot_weighted_e0 + sign(behavioural_tot_weighted_e0)*0.15 if behavioral_te30<0.1

gen sig_1_1 = behavioural_tot_weighted_e1 + sign(behavioural_tot_weighted_e1)*0.10 if behavioral_te31<0.01
gen sig_5_1 = behavioural_tot_weighted_e1 + sign(behavioural_tot_weighted_e1)*0.125 if behavioral_te31<0.05
gen sig_10_1 = behavioural_tot_weighted_e1 + sign(behavioural_tot_weighted_e1)*0.15 if behavioral_te31<0.1


twoway (bar behavioural_tot_weighted_e0  indx_impar if behavioral_te30<0.1, horizontal) (bar behavioural_tot_weighted_e1  indx_par if behavioral_te31<0.1, horizontal) ///
	(bar behavioural_tot_weighted_e0  indx_impar, horizontal fcolor("31 119 180%20")) (bar behavioural_tot_weighted_e1  indx_par, horizontal fcolor("255 127 14%20")) ///
	(scatter indx_impar sig_1_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_5_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_10_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	(scatter indx_par sig_1_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_5_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_10_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	, xline(0, lpattern(solid) lwidth(medthick)) ylabel(3 "P.B." 7 "Sure confidence" 11 "Half-confidence" 15 "Woman" 19 "Fam. asks" 23 "Makes budget" 27 "Savings" 31 "Extra pawn" 35 "ROSCA" 39 "Distressed" 43 "Tempted") legend(order(1 "=0" 2 "=1") pos(6) rows(1))
graph export "$directorio/Figuras/tot_beh_partition.pdf", replace

	
*TuT----------------------------------------------------------------------------	
drop sig_*
gen sig_1_0 = behavioral_te40 + sign(behavioral_te40)*0.10 if behavioral_te60<0.01
gen sig_5_0 = behavioral_te40 + sign(behavioral_te40)*0.125 if behavioral_te60<0.05
gen sig_10_0 = behavioral_te40 + sign(behavioral_te40)*0.15 if behavioral_te60<0.1

gen sig_1_1 = behavioral_te41 + sign(behavioral_te41)*0.10 if behavioral_te61<0.01
gen sig_5_1 = behavioral_te41 + sign(behavioral_te41)*0.125 if behavioral_te61<0.05
gen sig_10_1 = behavioral_te41 + sign(behavioral_te41)*0.15 if behavioral_te61<0.1

twoway (bar behavioral_te40  indx_impar if behavioral_te60<0.1, horizontal) (bar behavioral_te41  indx_par if behavioral_te61<0.1, horizontal) ///
	(bar behavioral_te40  indx_impar, horizontal fcolor("31 119 180%20")) (bar behavioral_te41  indx_par, horizontal fcolor("255 127 14%20")) ///
	(scatter indx_impar sig_1_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_5_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_10_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	(scatter indx_par sig_1_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_5_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_10_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	(scatter indx_impar prob_weights40, msymbol(Oh) color(gs4%90) mlwidth(medthick) msize(vsmall)) (scatter indx_par prob_weights41, msymbol(Oh) color(gs4%90) mlwidth(medthick) msize(vsmall) ), xline(0, lpattern(solid) lwidth(medthick)) ylabel(3 "P.B." 7 "Sure confidence" 11 "Half-confidence" 15 "Woman" 19 "Fam. asks" 23 "Makes budget" 27 "Savings" 31 "Extra pawn" 35 "ROSCA" 39 "Distressed" 43 "Tempted") legend(order(1 "=0" 2 "=1") pos(6) rows(1))
graph export "$directorio/Figuras/tut_beh_partition_pr.pdf", replace

	
drop sig_*
gen sig_1_0 = behavioural_tut_weighted_e0 + sign(behavioural_tut_weighted_e0)*0.10 if behavioral_te60<0.01
gen sig_5_0 = behavioural_tut_weighted_e0 + sign(behavioural_tut_weighted_e0)*0.125 if behavioral_te60<0.05
gen sig_10_0 = behavioural_tut_weighted_e0 + sign(behavioural_tut_weighted_e0)*0.15 if behavioral_te60<0.1

gen sig_1_1 = behavioural_tut_weighted_e1 + sign(behavioural_tut_weighted_e1)*0.10 if behavioral_te61<0.01
gen sig_5_1 = behavioural_tut_weighted_e1 + sign(behavioural_tut_weighted_e1)*0.125 if behavioral_te61<0.05
gen sig_10_1 = behavioural_tut_weighted_e1 + sign(behavioural_tut_weighted_e1)*0.15 if behavioral_te61<0.1
	

twoway (bar behavioural_tut_weighted_e0  indx_impar if behavioral_te60<0.1, horizontal) (bar behavioural_tut_weighted_e1  indx_par if behavioral_te61<0.1, horizontal) ///
	(bar behavioural_tut_weighted_e0  indx_impar, horizontal fcolor("31 119 180%20")) (bar behavioural_tut_weighted_e1  indx_par, horizontal fcolor("255 127 14%20")) ///
	(scatter indx_impar sig_1_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_5_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_10_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	(scatter indx_par sig_1_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_5_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_par sig_10_1, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///	
	, xline(0, lpattern(solid) lwidth(medthick)) ylabel(3 "P.B." 7 "Sure confidence" 11 "Half-confidence" 15 "Woman" 19 "Fam. asks" 23 "Makes budget" 27 "Savings" 31 "Extra pawn" 35 "ROSCA" 39 "Distressed" 43 "Tempted") legend(order(1 "=0" 2 "=1") pos(6) rows(1))
graph export "$directorio/Figuras/tut_beh_partition.pdf", replace	
	

*Pr Take-up --------------------------------------------------------------------
drop sig_*
gen sig_1_0 = prob_take10 + sign(prob_take10)*0.010 if prob_take30<0.01
gen sig_5_0 = prob_take10 + sign(prob_take10)*0.0125 if prob_take30<0.05
gen sig_10_0 = prob_take10 + sign(prob_take10)*0.015 if prob_take30<0.1

		
twoway (bar prob_take10 indx_impar if prob_take30<0.1, horizontal)  ///
	(bar prob_take10  indx_impar, horizontal fcolor("31 119 180%20"))  ///
	(scatter indx_impar sig_1_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_5_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///
	(scatter indx_impar sig_10_0, color(black) msymbol(x) mlwidth(medthick) msize(large)) ///		
	, xline(0, lpattern(solid) lwidth(medthick)) ylabel(3 "P.B." 7 "Sure confidence" 11 "Half-confidence" 15 "Woman" 19 "Fam. asks" 23 "Makes budget" 27 "Savings" 31 "Extra pawn" 35 "ROSCA" 39 "Distressed" 43 "Tempted") legend(off) ytitle("")
graph export "$directorio/Figuras/prtakeup_beh.pdf", replace
		