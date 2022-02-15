
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

gen desempeno=(clave_movimiento==3)


*Recidivism
preserve
bysort prenda: egen des_c=max(desempeno)
bysort prenda: egen dias_ultimo_mov = max(dias_inicio)
gen dias_inicio_d=dias_inicio if des_c
bysort prenda: egen dias_al_desempenyo=max(dias_inicio_d)
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial
*Number of visits to pawn 
bysort NombrePignorante: gen visit_number = _n
qui su visit_number, d
local tr99 = `r(p99)'
replace visit_number = `tr99' if visit_number>=`tr99'

*Dummy indicating if customer received more than one treatment arm
bysort NombrePignorante t_prod : gen unique_arms = _n==1
replace unique_arms = 0 if missing(t_prod)
bysort NombrePignorante : egen num_arms = sum(unique_arms)
gen more_one_arm = (num_arms>1)


keep NombrePignorante fecha_inicial visit_number num_arms 
tempfile temp_rec
save  `temp_rec'
restore
merge m:1 NombrePignorante fecha_inicial using `temp_rec', nogen


*Recover pawn
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen des_c=desempeno[_N]

*Days to recover
gen dias_inicio_d=dias_inicio if des_c
by prenda: gen dias_al_desempenyo=dias_inicio_d[_N]
replace dias_al_desempenyo = 1 if dias_al_desempenyo==0
replace dias_inicio = 1 if dias_inicio==0 & des_c==1

*Suc by day
egen suc_x_dia=group(suc fecha_inicial)


*Number of pledges by suc and day
gen dow=dow(fecha_inicial)


*Aux Dummies (Fixed effects)
tab num_arms, gen(num_arms_d)
tab visit_number, gen(visit_number_d)
foreach var of varlist dow suc /*prenda_tipo edo_civil choose_same trabajo*/  {
	tab `var', gen(dummy_`var')
	}
drop num_arms_d1 num_arms_d2 visit_number_d1
	
	
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
	
	
