*Treatment effects main results - (Table)

set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear

*TREATMENT ARM
local arm pro_2

*Aux Dummies 
tab dow, gen(dummy_dow)
tab suc, gen(dummy_suc)
tab num_arms, gen(num_arms_d)
tab visit_number, gen(visit_number_d)
tab num_arms_75, gen(num_arms_75_d)
tab visit_number_75, gen(visit_number_75_d)
drop num_arms_d1 num_arms_d2 num_arms_75_d1 num_arms_75_d2 visit_number_d1 visit_number_75_d1

*Var creation
gen sum_porcp_rec = sum_porcp_c if des_c==1

global C0 = "dummy_* num_arms_d* visit_number_d*" /*Controls*/
global C1 = "dummy_* num_arms_75_d* visit_number_75_d*" /*Controls customer level*/
global dep_vars num_p dias_al_desempenyo trans_cost apr mn_p_c sum_porcp_rec


********************************************************************************
**********************************Treatment arm*********************************
********************************************************************************

eststo clear
foreach var of varlist $dep_vars {
	eststo : reg `var' `arm' ${C0}, r cluster(suc_x_dia) 
	su `var' if e(sample) & `arm'==0
	estadd scalar DepVarMean = `r(mean)'
	}

	
*************************
	esttab using "$directorio/Tables/reg_results/te_`arm'.csv", se r2 star(* 0.1 ** 0.05 *** 0.01) b(a2) ///
	scalars("DepVarMean Control Mean") replace 
	
	
