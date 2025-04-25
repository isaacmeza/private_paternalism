
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

clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear

keep if inlist(t_prod,1,2,4)

keep fc_admin sum_p_c prestamo_i dias_al_desempenyo dias_al_default dias_ultimo_mov def_c des_c choose_commitment t_prod prod suc_x_dia 

*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4

matrix tut_fc = J(101, 4, .)
matrix tut_apr = J(101, 4, .)

********************************************************************************

forvalues i = 0(1)100 {
	qui {
	preserve
	
	gen fc_admin_liq = fc_admin + sum_p_c*`i'/100

	gen double apr_liq  = .
	replace apr_liq = (1 + (fc_admin_liq/prestamo_i)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_c==1
	replace apr_liq = (1 + (fc_admin_liq/prestamo_i)/dias_al_default)^dias_al_default - 1  if def_c==1
	replace apr_liq = (1 + (fc_admin_liq/prestamo_i)/dias_ultimo_mov)^dias_ultimo_mov - 1  if def_c==0 & des_c==0

	replace fc_admin_liq = -fc_admin_liq
	replace apr_liq = -apr_liq*100
	
	tot_tut fc_admin_liq Z choose_commitment ,  vce(cluster suc_x_dia)
	local df = e(df_r)	
	matrix tut_fc[`=`i'+1',1] = `i'
	matrix tut_fc[`=`i'+1',2] = _b[TuT]
	matrix tut_fc[`=`i'+1',3] = _se[TuT]
	matrix tut_fc[`=`i'+1',4] = `df'
	
	tot_tut apr_liq Z choose_commitment ,  vce(cluster suc_x_dia)
	local df = e(df_r)
	matrix tut_apr[`=`i'+1',1] = `i'
	matrix tut_apr[`=`i'+1',2] = _b[TuT]
	matrix tut_apr[`=`i'+1',3] = _se[TuT]
	matrix tut_apr[`=`i'+1',4] = `df'
	
	restore
	}
	if `i'==0 {
		di ""
		_dots 0, title(Interest rate) reps(100)
	}
	_dots `i' 0
	}
		
		
*---------------------------------------------

matrix colnames tut_fc = "i" "beta" "se" "df"
clear
svmat tut_fc, names(col) 

gen rcap_lo_5 = beta - invttail(df,.025)*se
gen rcap_hi_5 = beta + invttail(df,.025)*se	
gen rcap_lo_10 = beta - invttail(df,.05)*se
gen rcap_hi_10 = beta + invttail(df,.05)*se	


twoway 	(rarea rcap_hi_5 rcap_lo_5 i, color(navy%15))  ///
		(rarea rcap_hi_10 rcap_lo_10 i, color(navy%30))  ///
		(line beta i, color(navy) lwidth(thick)) ///
	, graphregion(color(white)) ///
	xtitle("External interest rate %") ytitle("FC Benefit") legend(off) yline(0, lcolor(black)) 
graph export "$directorio\Figuras\ext_int_fctut_noeffect.pdf", replace

*---------------------------------------------

matrix colnames tut_apr = "i" "beta" "se" "df"
clear
svmat tut_apr, names(col) 

gen rcap_lo_5 = beta - invttail(df,.025)*se
gen rcap_hi_5 = beta + invttail(df,.025)*se	
gen rcap_lo_10 = beta - invttail(df,.05)*se
gen rcap_hi_10 = beta + invttail(df,.05)*se	


twoway 	(rarea rcap_hi_5 rcap_lo_5 i, color(navy%15))  ///
		(rarea rcap_hi_10 rcap_lo_10 i, color(navy%30))  ///
		(line beta i, color(navy) lwidth(thick)) ///
	, graphregion(color(white)) ///
	xtitle("External interest rate %") ytitle("APR Benefit") legend(off) yline(0, lcolor(black)) 
graph export "$directorio\Figuras\ext_int_aprtut_noeffect.pdf", replace
	