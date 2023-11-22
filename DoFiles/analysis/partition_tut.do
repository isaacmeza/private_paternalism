
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Feb. 28, 2023
* Last date of modification: Nov. 21, 2023
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Decomposition of TuT by binary variable

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

replace fc_admin = -fc_admin

*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4
	

matrix behavioral_te = J(2*2,5,.)
matrix tut = J(2,3,.)

local k = 1
local j = 1


foreach var of varlist  pb confidence_100   {
	
	tot_tut fc_admin Z choose_commitment if !missing(`var'),  vce(cluster suc_x_dia)
	local df = e(df_r)
	matrix tut[`j',1] = _b[TuT]
	matrix tut[`j',2] = _se[TuT]
	matrix tut[`j',3] = 2*ttail(`df', abs(_b[TuT]/_se[TuT]))		
	
	forvalues i = 0/1 {
		tot_tut fc_admin Z choose_commitment if `var'==`i',  vce(cluster suc_x_dia)	
		local df = e(df_r)
		matrix behavioral_te[`k',1] = _b[TuT]
		matrix behavioral_te[`k',2] = _se[TuT]
		matrix behavioral_te[`k',3] = 2*ttail(`df', abs(_b[TuT]/_se[TuT]))	
		
		matrix behavioral_te[`k',4] = `i'
		matrix behavioral_te[`k',5] = `j'
		
		local k = `k' + 1
		}
	
	local j = `j' + 1
}	

clear 
svmat behavioral_te
rename (behavioral_te2) (behavioral_te1_se)

label define behavioral_var 1 "P.B."  2 "Sure-confidence" 
label values behavioral_te5 behavioral_var

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
foreach var of varlist behavioral_te1 {
	gen `var'_lo = `var' - invttail(257,`=`alpha'/2')*`var'_se
	gen `var'_hi = `var' + invttail(257,`=`alpha'/2')*`var'_se
}

reshape wide behavioral_te1 behavioral_te1_se behavioral_te3 behavioral_te1_lo behavioral_te1_hi, i(behavioral_te5) j(behavioral_te4)

svmat tut
rename (tut2) (tut1_se)

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
foreach var of varlist tut1  {
	gen `var'_lo = `var' - invttail(257,`=`alpha'/2')*`var'_se
	gen `var'_hi = `var' + invttail(257,`=`alpha'/2')*`var'_se
}

gen ind0 = behavioral_te5 - 0.1
gen ind1 = behavioral_te5 + 0.1


	*Plot
twoway (rcap tut1_lo tut1_hi behavioral_te5, msize(large) color(navy)) (scatter tut1 behavioral_te5, msymbol(square) msize(medium) color(navy)) ///
	(rcap behavioral_te1_lo0 behavioral_te1_hi0 ind0, msize(large) color(maroon)) (scatter behavioral_te10 ind0, msymbol(diamond)  msize(medium) color(maroon)) ///
	(rcap behavioral_te1_lo1 behavioral_te1_hi1 ind1, msize(large) color(dkgreen)) (scatter behavioral_te11 ind1, msize(large) color(dkgreen)), yline(0) xline(1.5, lpattern(solid)) legend(order(4 "TuT | X=0" 2 "TuT" 6 "TuT | X=1") pos(6) rows(1)) xlabel(0.5 " " 1 2 2.5 " ", valuelabel)  
graph export "$directorio/Figuras/tut_beh_partition.pdf", replace	
	
