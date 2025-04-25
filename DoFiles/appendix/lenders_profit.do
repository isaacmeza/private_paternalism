
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
*-------------------------------------------------------------------------------	
*Dataset with first visit only
use "$directorio/DB/Master.dta", clear
bysort NombreP :  gen id_nombrep = _n


reg reincidence i.t_prod if inlist(t_prod,1,2,4) & id_nombrep==1, vce(cluster suc_x_dia)
local re_control = _b[_cons]
local re_forced = _b[_cons]+_b[2.t_prod]
local re_choice = _b[_cons]+_b[4.t_prod]

reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)

gen est_control_noreturn = _b[_cons]
gen est_forced_noreturn = (_b[_cons]+_b[2.t_prod])-est_control_noreturn
gen est_choice_noreturn = (_b[_cons]+_b[4.t_prod])-est_control_noreturn

gen est_control_exp = _b[_cons]*(1/(1-`re_control'))
gen est_forced_exp = (_b[_cons]+_b[2.t_prod])*(1/(1-`re_forced'))-est_control_exp
gen est_choice_exp = (_b[_cons]+_b[4.t_prod])*(1/(1-`re_choice'))-est_control_exp

gen est_control_lin = _b[_cons]*(1+(2*`re_control'))
gen est_forced_lin = (_b[_cons]+_b[2.t_prod])*(1+(2*`re_forced'))-est_control_lin
gen est_choice_lin = (_b[_cons]+_b[4.t_prod])*(1+(2*`re_choice'))-est_control_lin

gen est_control_exp_btsp = .
gen est_forced_exp_btsp = .
gen est_choice_exp_btsp = .

gen est_control_noreturn_btsp = .
gen est_forced_noreturn_btsp = .
gen est_choice_noreturn_btsp = .

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
	
	reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	restore
	
	replace est_control_noreturn_btsp = _b[_cons] in `i'
	replace est_forced_noreturn_btsp = (_b[_cons]+_b[2.t_prod])-est_control_noreturn in `i'
	replace est_choice_noreturn_btsp = (_b[_cons]+_b[4.t_prod])-est_control_noreturn in `i'
	
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
 
su est_forced_noreturn 
putexcel A5 = `r(mean)', nformat(number_d2)
su est_forced_noreturn_btsp
putexcel A6 = `r(sd)', nformat(number_d2)
local pval = 2*(1-normal(abs(est_forced_noreturn / `r(sd)')))
putexcel B5 = `pval', nformat(number_d3)
	
su est_choice_noreturn  
putexcel A7= `r(mean)', nformat(number_d2)
su est_choice_noreturn_btsp
putexcel A8 = `r(sd)', nformat(number_d2)
local pval = 2*(1-normal(abs(est_choice_noreturn / `r(sd)')))
putexcel B7 = `pval', nformat(number_d3)

su est_control_noreturn  
putexcel A12= `r(mean)', nformat(number_d2)

*-------------------------------------------------------------------------------
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

*-------------------------------------------------------------------------------
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

reg fc_admin i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
putexcel E10= `e(N)'
