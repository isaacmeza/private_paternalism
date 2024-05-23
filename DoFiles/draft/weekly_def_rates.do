
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
tsset weekly

tsline def_c, xtitle("Date (Experimental)") ytitle("Weekly defaut rate") lwidth(medthick) ylabel(.30(.05).60) name(def_exp, replace)


use "${directorio}\DB\base_expansion.dta", clear

local var fechaaltadelprestamo
sort fechaaltadelprestamo
gen weekly=yw(year(fechaaltadelprestamo), week(fechaaltadelprestamo))
format weekly %tw
collapse (mean) def_vta , by(weekly)
tsset weekly

tsline def_vta if weekly<yw(2020, 12), xtitle("Date (Observational)") ytitle("") lwidth(medthick) ylabel(.30(.05).60)  name(def_obs, replace)


graph combine def_exp def_obs, ycommon cols(2) 
graph export "$directorio\Figuras\weekly_def_rates.pdf", replace
