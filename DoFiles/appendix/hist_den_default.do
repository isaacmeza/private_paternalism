/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: 
* Modifications: 
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Histogram of payment behaviour conditional on default


*******************************************************************************/
*/

set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

*Conditional on default
keep if t_prod==1
keep if def_c==1


hist dias_ultimo_mov, percent w(10)  graphregion(color(white)) ///
	xtitle("Elapsed days to last payment") title("") note("")
graph export "$directorio\Figuras\hist_days_default.pdf", replace

hist dias_primer_pago, percent w(10)  graphregion(color(white)) ///
	xtitle("Elapsed days") title("") note("")
graph export "$directorio\Figuras\hist_firstdays_default.pdf", replace			
			
hist sum_porcp_c, percent w(0.1) graphregion(color(white)) ///
	title("") note("")
graph export "$directorio\Figuras\hist_percpay_default.pdf", replace			
			
catplot num_p if num_p<=5, percent vertical graphregion(color(white)) ///
	 ytitle("Percent")
graph export "$directorio\Figuras\hist_numpay_default.pdf", replace			
			
