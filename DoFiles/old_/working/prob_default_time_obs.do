
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: February. 23, 2022
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Survival graph (recovery) in the expansion dataset

*******************************************************************************/
*/

use  "${directorio}\DB\base_expansion.dta", clear

*Sample as in experiment
keep if inlist(periodicidad,6,8,15,16)
keep if strpos(linea2, "Alhajas")!=0

*Days until contract termination
gen dias_end = fechavencimiento - fechaaltadelprestamo 

/*
*E[default | T = t]
levelsof dias_end, local(levels) 

matrix Edefault = J(`r(r)',2,.)
local i = 1
foreach l of local levels {
	di `l'
	qui {
	su def if dias_end==`l'
	matrix Edefault[`i',2] = `r(mean)'
	matrix Edefault[`i',1] = `l'
	local i = `i' + 1
	}
}

*/

*P(T <= t | default)
cumul dias_end if def==1, gen(ecdf_dias_def)
*P(default)
su def
local mn = `r(mean)'
*P(T<=t)
cumul dias_end, gen(ecdf_dias)

*P(default | T <= t) = [ P(T <= t | default) * P(default) ] / P(T<=t)
collapse (max) ecdf_dias_def (max) ecdf_dias, by(dias_end)

gen survival_def = ecdf_dias_def*`mn'/ecdf_dias



line survival_def dias_end, xline(30 230) xtitle("t (Elapsed days)") ytitle("P(default | T <= t)")



/*
su def
local mn = `r(mean)'

cumul dias_end if def==1, gen(ecdf_def)
cumul dias_end if def==0, gen(ecdf_des)
cumul dias_end, gen(ecdf_tot)

twoway (line ecdf_tot dias_end , sort)  (line ecdf_def dias_end , sort)

twoway (line ecdf_def dias_end, sort xline(230)), xtitle("Elapsed days") ytitle("Cumulative probability of default")



*/



