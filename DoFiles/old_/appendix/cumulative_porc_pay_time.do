
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: March. 15, 2022
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Cumulative graph of % payment over time by teratment arm

*******************************************************************************/
*/

set more off
use "$directorio/DB/Master.dta", clear

foreach var of varlist sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c {
	
	local dy = substr("`var'",10,2)
	replace `var' = `var'*100
	reg `var' i.t_prod ${C0} if inlist(t_prod,1,2,4),  vce(cluster suc_x_dia) 	
	local beta`dy' = round(_b[2.t_prod],.01)
	local se`dy' = round(_se[2.t_prod],.01)
		
	*Conditional on default
	gen `var'_d = `var' if def_c==1
	replace `var'_d = `var'_d
	reg `var'_d i.t_prod ${C0} if inlist(t_prod,1,2,4),  vce(cluster suc_x_dia) 	
	local betad`dy' = round(_b[2.t_prod],.01)
	local sed`dy' = round(_se[2.t_prod],.01)
	}


*_______________________________________________________________________________

use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv.dta", clear	   
keep if inlist(clave_mov,1,3,4,5) & !missing(t_prod)

sort prenda fecha_movimiento HoraMovimiento
replace porc_pagos = porc_pagos*100
collapse (sum) porc_pagos (mean) t_producto , by(prenda dias_inicio)

*Balance panel
xtset prenda dias_inicio
tsfill, full
replace porc_pagos = 0 if missing(porc_pagos)
by prenda : gen sum_porc_p = sum(porc_pagos)
by prenda : egen t_prod = mean(t_producto)

*Average % of payment over arm-day
collapse (mean) porc_pagos (mean) sum_porc_p (count) c_obs = porc_pagos , by(t_prod dias_inicio)
local te30 = 90
*Cumulative graph of % payment over time by teratment arm
twoway (line sum_porc_p dias_inicio if t_prod==1, lwidth(medthick) lcolor(black) xline(105, lpattern(dot) lcolor(gs10))) ///
	(line sum_porc_p dias_inicio if t_prod==2, lwidth(medthick) lcolor(navy%90) xline(30 60 90, lcolor(gs12))) ///
	(line sum_porc_p dias_inicio if t_prod==4, lwidth(medthick) lcolor(maroon%90)) ///
	(scatteri 15 29 (9) "{&beta}{subscript:30} = `=round(`beta30',.01)'" ///
		25 59 (9) "{&beta}{subscript:60} = `=round(`beta60',.01)'" ///
		45 89 (9) "{&beta}{subscript:90} = `=round(`beta90',.01)'" ///
		70 105 (3) "{&beta}{subscript:105} = `=round(`beta10',.01)'" ///
		, msymbol(i) mlabcolor(black)) ///	
	(scatteri 12 29 (9) "{&sigma}{subscript:30} = `=round(`se30',.1)'" ///
		22 59 (9) "{&sigma}{subscript:60} = `=round(`se60',.2)'" ///
		42 89 (9) "{&sigma}{subscript:90} = `=round(`se90',.1)'" ///
		67 105 (3) "{&sigma}{subscript:105} = `=round(`se10',.1)'" ///
		, msymbol(i) mlabcolor(black)) ///			
	, graphregion(color(white)) xtitle("Elapsed days") ytitle("% of payment") ///
	 legend(order(1 "Status-quo" 2 "Forced commitment" 3 "Choice commitment") size(small) pos(6) rows(1)) xlabel(0 30 60 90 180 270 320)
graph export "$directorio\Figuras\cumulative_porc_pay_time.pdf", replace



*******************************************************************************/



use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2fv.dta", clear	   
keep if inlist(clave_mov,1,3,4,5) & !missing(t_prod)
*Conditional on default
keep if def_i_c==1

sort prenda fecha_movimiento HoraMovimiento
replace porc_pagos = porc_pagos*100
collapse (sum) porc_pagos (mean) t_producto , by(prenda dias_inicio)

*Balance panel
xtset prenda dias_inicio
tsfill, full
replace porc_pagos = 0 if missing(porc_pagos)
by prenda : gen sum_porc_p = sum(porc_pagos)
by prenda : egen t_prod = mean(t_producto)

*Average % of payment over arm-day
collapse (mean) porc_pagos (mean) sum_porc_p (count) c_obs = porc_pagos , by(t_prod dias_inicio)

*Cumulative graph of % payment over time by teratment arm
twoway (line sum_porc_p dias_inicio if t_prod==1, lwidth(medthick) lcolor(black) xline(105, lpattern(dot) lcolor(gs10))) ///
	(line sum_porc_p dias_inicio if t_prod==2, lwidth(medthick) lcolor(navy%90) xline(30 60 90, lcolor(gs12))) ///
	(line sum_porc_p dias_inicio if t_prod==4, lwidth(medthick) lcolor(maroon%90)) ///
	(scatteri 4.0 105 (3) "{&beta}{subscript:105} = `=round(`betad10',.01)'" ///
		, msymbol(i) mlabcolor(black)) ///	
	(scatteri 3.5 105 (3) "{&sigma}{subscript:105} = `=round(`sed10',.1)'" ///
		, msymbol(i) mlabcolor(black)) ///			
	, graphregion(color(white)) xtitle("Elapsed days") ytitle("% of payment") ///
	 legend(order(1 "Status-quo" 2 "Forced commitment" 3 "Choice commitment") size(small) pos(6) rows(1)) xlabel(0 30 60 90 180 270 320)
graph export "$directorio\Figuras\cumulative_porc_pay_time_default.pdf", replace
	 