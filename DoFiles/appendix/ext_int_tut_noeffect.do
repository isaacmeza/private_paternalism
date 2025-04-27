
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Apr. 25, 2025
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Find (external) interest rate such that the TuT = 0

*******************************************************************************/
*/

use "$directorio/_aux/pre_admin.dta", clear
keep if inlist(t_prod,1,2,4)

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
*Days towards default
gen dias_al_default = dias_ultimo_mov if def_c==1
replace dias_al_default = 105 if dias_al_default<90 & def_c==1
replace dias_al_default = 210 if inrange(dias_ultimo_mov, 110, 180) & def_c==1
replace dias_al_default = 315 if inrange(dias_ultimo_mov, 220, 270) & def_c==1
*Days for external contract
gen dias_ext = 1 

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
	
matrix fc_tut = J(101, 4, .)
matrix apr_tut = J(101, 4, .)


local i = 1
forvalues d = 0(10)100 {	
	qui {
	preserve
	
	local dd = (1+`d'/100)^(1/1)-1
	
	* Cumulative interest compund at rate above
	gen pagos_liq=pagos*((1+`dd')^(dias_ext) - 1)
	replace pagos_liq=0 if pagos_liq==.

	sort prenda fecha_movimiento HoraMovimiento, stable	
	*'sum_p_disc' is the cumulative discounted sum of payments
	by prenda: gen sum_p_liq=sum(pagos_liq)
	by prenda: egen sum_p_liq_c=max(sum_p_liq)
	by prenda: egen sum_p_c=max(sum_p)	
	by prenda: egen sum_int_c=max(sum_int)
	
	*Financial cost
			*discounted
	gen double fc_admin_liq = .
		*Only fees and interest for recovered pawns
	replace fc_admin_liq = sum_int_c + sum_pay_fee_c if des_c==1
		*All payments + appraised value when default
	replace fc_admin_liq = sum_p_c + prestamo_i*(0.3/0.7) if def_c==1
		*Not ended at the end of observation period - only fees and interest
	replace fc_admin_liq = sum_int_c + sum_pay_fee_c if def_c==0 & des_c==0
		*Add external interest rate (we interpret it as the discounted preference for liquidity)
	replace fc_admin_liq = fc_admin_liq + sum_p_liq_c 
	
	*APR
	gen double apr_liq  = .
	replace apr_liq = (1 + (fc_admin_liq/prestamo_i)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_c==1
	replace apr_liq = (1 + (fc_admin_liq/prestamo_i)/dias_al_default)^dias_al_default - 1  if def_c==1
	replace apr_liq = (1 + (fc_admin_liq/prestamo_i)/dias_ultimo_mov)^dias_ultimo_mov - 1  if def_c==0 & des_c==0

		*Financial cost gain (negative scale)
	replace fc_admin_liq = -fc_admin_liq
	replace apr = -apr*100
	
	keep if visit_number==1
	gsort prenda fecha_inicial -fecha_movimiento clave_movimiento t_prod
	by prenda fecha_inicial : keep if _n==1

	tot_tut fc_admin_liq Z choose_commitment,  vce(cluster suc_x_dia)
	local df = e(df_r)	
	matrix fc_tut[`i',1] = `d'
	matrix fc_tut[`i',2] = _b[TuT]
	matrix fc_tut[`i',3] = _se[TuT]
	matrix fc_tut[`i',4] = `df'
	
	tot_tut apr_liq Z choose_commitment,  vce(cluster suc_x_dia)
	local df = e(df_r)	
	matrix apr_tut[`i',1] = `d'
	matrix apr_tut[`i',2] = _b[TuT]
	matrix apr_tut[`i',3] = _se[TuT]
	matrix apr_tut[`i',4] = `df'
	
	local i = `i' + 1
	restore
	}
	if `d'==0 {
		di ""
		_dots 0, title(Interest rate) reps(5000)
	}
	_dots `d' 0
	}

**************************************TUT FC************************************	
matrix colnames fc_tut = "d" "beta" "se" "df"
clear
svmat fc_tut, names(col) 
gen rcap_lo_5 = beta - invttail(df,.025)*se
gen rcap_hi_5 = beta + invttail(df,.025)*se	
gen rcap_lo_10 = beta - invttail(df,.05)*se
gen rcap_hi_10 = beta + invttail(df,.05)*se	


twoway 	(rarea rcap_hi_5 rcap_lo_5 d, color(navy%15))  ///
		(rarea rcap_hi_10 rcap_lo_10 d, color(navy%30))  ///
		(line beta d, color(navy) lwidth(thick)) ///
	, graphregion(color(white)) ///
	xtitle("Daily external interest rate %") ytitle("FC Benefit (TuT)") legend(off) yline(0, lcolor(black)) 
graph export "$directorio\Figuras\ext_int_fctut_noeffect.pdf", replace
	
	

*************************************TuT APR************************************	
matrix colnames apr_tut = "d" "beta" "se" "df"
clear
svmat apr_tut, names(col) 
gen rcap_lo_5 = beta - invttail(df,.025)*se
gen rcap_hi_5 = beta + invttail(df,.025)*se	
gen rcap_lo_10 = beta - invttail(df,.05)*se
gen rcap_hi_10 = beta + invttail(df,.05)*se	


twoway 	(rarea rcap_hi_5 rcap_lo_5 d, color(navy%15))  ///
		(rarea rcap_hi_10 rcap_lo_10 d, color(navy%30))  ///
		(line beta d, color(navy) lwidth(thick)) ///
	, graphregion(color(white)) ///
	xtitle("Daily external interest rate %") ytitle("APR Benefit (TuT)") legend(off) yline(0, lcolor(black)) 
graph export "$directorio\Figuras\ext_int_aprtut_noeffect.pdf", replace

