
********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification:  
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Weekly default rates in experimental and observational sample to show default rates are not atypical in exp period.

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear
sort fecha_inicial
gen weekly=yw(year(fecha_inicial), week(fecha_inicial))
format weekly %tw
collapse (mean) def_c , by(weekly)
tempfile temp_exp
save `temp_exp'


use "${directorio}\DB\base_expansion.dta", clear
sort fechaaltadelprestamo
gen weekly=yw(year(fechaaltadelprestamo), week(fechaaltadelprestamo))
format weekly %tw
collapse (mean) def_vta , by(weekly)
rename def_vta def_c
append using `temp_exp'
tsset weekly

twoway (tsline def_c if weekly<yw(2013, 12), lwidth(medthick) ylabel(.30(.05).60)) ///
(tsline def_c if inrange(weekly,yw(2016, 1),yw(2020, 12)), xtitle("Date") ytitle("Defualt rate (weekly)") lwidth(medthick) ylabel(.30(.05).60)), ///
legend(order(1 "Experimental" 2 "Observational") pos(6) cols(2))
graph export "$directorio\Figuras\weekly_def_rates.pdf", replace
