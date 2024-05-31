
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	May. 30, 2024
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Lender's Profit

*******************************************************************************/
*/
*Dataset with multiple visits
use "$directorio/_aux/preMaster.dta", clear

*Lender's profits
gen profits = sum_int_c + sum_pay_fee_c + (.30/.70)*prestamo_i*def_c  

*Identify first treatment
sort NombreP fecha_inicial visit_number prenda 
by NombreP : replace first_prod = first_prod[_n-1] if missing(first_prod)

*Collapse profits over all visits
sort NombreP visit_number fecha_inicial
by NombreP : gen sum_profits_aux = sum(profits) if visit_number<=2
by NombreP : egen sum_profits = max(sum_profits_aux)

*Collapse profits by borrower
duplicates drop NombreP, force
drop t_prod
rename first_prod t_producto

*-------------------------------------------------------------------------------

********************************************************
*			      		 REGRESSIONS				   *
********************************************************

eststo clear
eststo : reg sum_profits i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su sum_profits if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'	


esttab using "$directorio/Tables/reg_results/lenders_profit.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 
	
	
*-------------------------------------------------------------------------------	
*Dataset with first visit only
use "$directorio/DB/Master.dta", clear
gen profits = sum_int_c + sum_pay_fee_c + (.30/.70)*prestamo_i*def_c 
bysort NombreP :  gen id_nombrep = _n


reg reincidence i.t_prod if inlist(t_prod,1,2,4) & id_nombrep==1, vce(cluster suc_x_dia)
local re_control = _b[_cons]
local re_forced = _b[_cons]+_b[2.t_prod]
local re_choice = _b[_cons]+_b[4.t_prod]

reg profits i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)

gen est_control_exp = _b[_cons]*(1/(1-`re_control'))
gen est_forced_exp = (_b[_cons]+_b[2.t_prod])*(1/(1-`re_forced'))-est_control_exp
gen est_choice_exp = (_b[_cons]+_b[4.t_prod])*(1/(1-`re_choice'))-est_control_exp

gen est_control_lin = _b[_cons]*(1+(2*`re_control'))
gen est_forced_lin = (_b[_cons]+_b[2.t_prod])*(1+(2*`re_forced'))-est_control_lin
gen est_choice_lin = (_b[_cons]+_b[4.t_prod])*(1+(2*`re_choice'))-est_control_lin

gen est_control_exp_btsp = .
gen est_forced_exp_btsp = .
gen est_choice_exp_btsp = .

gen est_control_lin_btsp = .
gen est_forced_lin_btsp = .
gen est_choice_lin_btsp = .


*Bootstrap

forvalues i = 1/1000 {
	qui {
	preserve
	bsample, cluster(suc_x_dia)
	cap drop id_nombrep
	bysort NombreP : gen id_nombrep = _n
	reg reincidence i.t_prod if inlist(t_prod,1,2,4) & id_nombrep==1, vce(cluster suc_x_dia)
	local re_control = _b[_cons]
	local re_forced = _b[_cons]+_b[2.t_prod]
	local re_choice = _b[_cons]+_b[4.t_prod]
	
	reg profits i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	restore
	
	replace est_control_exp_btsp = _b[_cons]*(1/(1-`re_control')) in `i'
	replace est_forced_exp_btsp = (_b[_cons]+_b[2.t_prod])*(1/(1-`re_forced'))-est_control_exp in `i'
	replace est_choice_exp_btsp = (_b[_cons]+_b[4.t_prod])*(1/(1-`re_choice'))-est_control_exp in `i'

	replace est_control_lin_btsp = _b[_cons]*(1+(2*`re_control'))
	replace est_forced_lin_btsp = (_b[_cons]+_b[2.t_prod])*(1+(2*`re_forced'))-est_control_lin in `i'
	replace est_choice_lin_btsp = (_b[_cons]+_b[4.t_prod])*(1+(2*`re_choice'))-est_control_lin in `i'
	
	}
	if `i'==1 {
		di ""
		_dots 0, title(Bootstrap running) reps(1000)
	}
	_dots `i' 0
}

qui putexcel set  "$directorio/Tables/lenders_profit.xlsx", sheet("lenders_profit_aux") modify	
 
su est_forced_exp 
putexcel C5 = `r(mean)', nformat(number_d2)
su est_forced_exp_btsp
putexcel C6 = `r(sd)', nformat(number_d2)
local pval = 2*(1-normal(abs(est_forced_exp / `r(sd)')))
putexcel D5 = `pval', nformat(number_d3)
	
su est_choice_exp 
putexcel C7= `r(mean)', nformat(number_d2)
su est_choice_exp_btsp
putexcel C8 = `r(sd)', nformat(number_d2)
local pval = 2*(1-normal(abs(est_choice_exp / `r(sd)')))
putexcel D7 = `pval', nformat(number_d3)

su est_control_exp 
putexcel C12= `r(mean)', nformat(number_d2)


su est_forced_lin
putexcel E5 = `r(mean)', nformat(number_d2)
su est_forced_lin_btsp
putexcel E6 = `r(sd)', nformat(number_d2)
local pval = 2*(1-normal(abs(est_forced_lin / `r(sd)')))
putexcel F5 = `pval', nformat(number_d3)

su est_choice_lin
putexcel E7= `r(mean)', nformat(number_d2)
su est_choice_lin_btsp
putexcel E8 = `r(sd)', nformat(number_d2)
local pval = 2*(1-normal(abs(est_choice_lin / `r(sd)')))
putexcel F7 = `pval', nformat(number_d3)

su est_control_lin 
putexcel E12= `r(mean)', nformat(number_d2)

reg profits i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
putexcel E10= `e(N)'
