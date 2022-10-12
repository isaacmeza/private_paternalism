
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: February. 13, 2022  
* Modifications:		
* Files used:     
		- pre_admin.dta
* Files created:  

* Purpose: Compute discount rate such that t. effect becomes 0 

*******************************************************************************/
*/

use "$directorio/_aux/pre_admin.dta", clear

*This first part of the code is a verbatim copy of the cleaning_admin.do file in order to 
*create a replica of the main dataset.

*Suc by day
egen suc_x_dia=group(suc fecha_inicial)
*DoW
gen dow=dow(fecha_inicial)

*Aux Dummies (Fixed effects)
tab num_arms, gen(num_arms_d)
tab visit_number, gen(visit_number_d)
foreach var of varlist dow suc  {
	tab `var', gen(dummy_`var')
	}
drop num_arms_d1 visit_number_d1 dummy_dow1 dummy_suc1

	
matrix results = J(1001, 4, .)

local i = 1
forvalues d = 0(20)6000 {	
	di `d'
	qui {
	preserve
	local dd = (1+`d'/100)^(1/365)-1

	* DISCOUNTED with daily interest rate equivalent to a d% annual rate.
	gen pagos_disc=pagos/((1+`dd')^dias_inicio) if clave_movimiento <= 3 | clave_movimiento==5
	replace pagos_disc=0 if pagos_disc==.

	*'sum_p_disc' is the cumulative discounted sum of payments
	sort prenda fecha_movimiento HoraMovimiento
	by prenda: gen sum_p_disc=sum(pagos_disc)
	by prenda: gen sum_pdisc_c=sum_p_disc[_N]
	
	*Financial cost
		*discounted
	gen fc_admin_disc = sum_pdisc_c 
	replace fc_admin_disc = fc_admin_disc + prestamo/(0.7*(1 + `dd')^90) if des_c == 0

	sort prenda fecha_inicial fecha_movimiento t_prod
	by prenda fecha_inicial: keep if _n==1
	reg fc_admin_disc pro_2  $C0 , vce(cluster suc_x_dia)
	local df = e(df_r)	
	matrix results[`i',1] = `d'
	matrix results[`i',2] = _b[pro_2]
	matrix results[`i',3] = _se[pro_2]
	matrix results[`i',4] = `df'
	
	local i = `i' + 1
	restore
	}
	}

	
matrix colnames results = "d" "beta" "se" "df"
clear
svmat results, names(col) 
gen rcap_lo_5 = beta - invttail(df,.025)*se
gen rcap_hi_5 = beta + invttail(df,.025)*se	
gen rcap_lo_10 = beta - invttail(df,.05)*se
gen rcap_hi_10 = beta + invttail(df,.05)*se	




twoway 	(rarea rcap_hi_5 rcap_lo_5 d, color(navy%15))  ///
		(rarea rcap_hi_10 rcap_lo_10 d, color(navy%30))  ///
		(line beta d, color(navy) lwidth(thick)) ///
	, graphregion(color(white)) ///
	xtitle("Annual discount rate %") ytitle("FC Effect") legend(off) yline(0, lcolor(black)) ///
	xline(1060 2120, lcolor(black%90) lpattern(dot)) xlabel(0(1000)6000) text(-500 1060 "1060%" -500 2120 "2120%", size(vsmall))
graph export "$directorio\Figuras\discount_effect.pdf", replace
	
	
