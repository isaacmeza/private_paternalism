
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: April. 04, 2023  
* Modifications: Updated discounted results with new fc formula. Added TuT computation		
* Files used:     
		- pre_admin.dta
* Files created:  

* Purpose: Compute discount rate such that t. effect becomes 0 

*******************************************************************************/
*/

use "$directorio/_aux/pre_admin.dta", clear

sort prenda fecha_movimiento HoraMovimiento
	*Desempeno - defined as ever recovered in observation window 
by prenda: egen des_c=max(desempeno)
	*Default - defined as losing the piece - note that it is not symmetrical with recovered
gen def_c = concluyo_c
replace def_c = 0 if des_c==1
	*Payments
by prenda: egen sum_pay_fee_c=max(sum_pay_fee)
	*Days
by prenda: gen dias_ultimo_mov = dias_inicio[_N]
gen dias_inicio_d=dias_inicio if des_c==1
*Days towards recovery
by prenda: gen dias_al_desempenyo=dias_inicio_d[_N]
replace dias_al_desempenyo = 1 if dias_al_desempenyo==0


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

*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4
	
matrix results = J(1001, 4, .)
matrix results_tut = J(1001, 4, .)


local i = 1
forvalues d = 0(100)10000 {	
	di `d'
	qui {
	preserve

	local dd = (1+`d'/100)^(1/365)-1
	
	* DISCOUNTED with daily interest rate equivalent to a d% annual rate.
	gen pagos_disc=pagos/((1+`dd')^dias_inicio) if clave_movimiento <= 3 | clave_movimiento==5
	replace pagos_disc=0 if pagos_disc==.

	* DISCOUNTED interests
	gen intereses_disc = intereses/((1+`dd')^dias_inicio)
	sort prenda fecha_movimiento HoraMovimiento, stable
	by prenda: gen sum_int_disc=sum(intereses_disc)
	
	*'sum_p_disc' is the cumulative discounted sum of payments
	sort prenda fecha_movimiento HoraMovimiento, stable
	by prenda: gen sum_p_disc=sum(pagos_disc)
	by prenda: egen sum_pdisc_c=max(sum_p_disc)	
	by prenda: egen sum_int_c=max(sum_int_disc)
	
	*Financial cost
			*discounted
	gen double fc_admin_disc = .
		*Only fees and interest for recovered pawns
	replace fc_admin_disc = sum_int_c + sum_pay_fee_c if des_c==1
		*All payments + appraised value when default
	replace fc_admin_disc = sum_pdisc_c + prestamo_i/(0.7*(1 + `dd')^90) if def_c==1
		*Not ended at the end of observation period - only fees and interest
	replace fc_admin_disc = sum_int_c + sum_pay_fee_c if def_c==0 & des_c==0

	keep if visit_number==1
	gsort prenda fecha_inicial -fecha_movimiento clave_movimiento t_prod
	by prenda fecha_inicial : keep if _n==1

	tot_tut fc_admin Z choose_commitment,  vce(cluster suc_x_dia)
	local df = e(df_r)	
	matrix results[`i',1] = `d'
	matrix results[`i',2] = _b[ATE]
	matrix results[`i',3] = _se[ATE]
	matrix results[`i',4] = `df'
	
	matrix results_tut[`i',1] = `d'
	matrix results_tut[`i',2] = _b[TuT]
	matrix results_tut[`i',3] = _se[TuT]
	matrix results_tut[`i',4] = `df'
	
	local i = `i' + 1
	restore
	}
	}

*****************************************ATE************************************	
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
	xtitle("Annual discount rate %") ytitle("FC Effect") legend(off) yline(0, lcolor(black)) 
graph export "$directorio\Figuras\discount_effect.pdf", replace
	
	
	
*****************************************TuT************************************	
matrix colnames results_tut = "d" "beta" "se" "df"
clear
svmat results_tut, names(col) 
gen rcap_lo_5 = beta - invttail(df,.025)*se
gen rcap_hi_5 = beta + invttail(df,.025)*se	
gen rcap_lo_10 = beta - invttail(df,.05)*se
gen rcap_hi_10 = beta + invttail(df,.05)*se	




twoway 	(rarea rcap_hi_5 rcap_lo_5 d, color(navy%15))  ///
		(rarea rcap_hi_10 rcap_lo_10 d, color(navy%30))  ///
		(line beta d, color(navy) lwidth(thick)) ///
	, graphregion(color(white)) ///
	xtitle("Annual discount rate %") ytitle("FC Effect (TuT)") legend(off) yline(0, lcolor(black)) 
graph export "$directorio\Figuras\discount_effect_tut.pdf", replace	
