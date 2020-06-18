/*
Histogram of payment behaviour conditional on default
*/

set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear

*Conditional on default
keep if pro_2==0 | missing(pro_2)
keep if des_c==0


hist dias_ultimo_mov, percent w(10) scheme(s2mono) graphregion(color(white)) ///
	xtitle("Elapsed days to last payment") title("") note("")
graph export "$directorio\Figuras\hist_days_default.pdf", replace

hist dias_primer_pago, percent w(10) scheme(s2mono) graphregion(color(white)) ///
	xtitle("Elapsed days") title("") note("")
graph export "$directorio\Figuras\hist_firstdays_default.pdf", replace			
			
hist sum_porcp_c, percent w(0.1) scheme(s2mono) graphregion(color(white)) ///
	title("") note("")
graph export "$directorio\Figuras\hist_percpay_default.pdf", replace			
			
catplot num_p if num_p<=5, percent vertical scheme(s2mono) graphregion(color(white)) ///
	 ytitle("Percent")
graph export "$directorio\Figuras\hist_numpay_default.pdf", replace			
			
