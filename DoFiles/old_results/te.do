*Treatment effects main results (Graphs and Table)

set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear

*Aux Dummies 
tab dow, gen(dummy_dow)
tab suc, gen(dummy_suc)
tab num_arms, gen(num_arms_d)
tab visit_number, gen(visit_number_d)
tab num_arms_75, gen(num_arms_75_d)
tab visit_number_75, gen(visit_number_75_d)
drop num_arms_d1 num_arms_d2 num_arms_75_d1 num_arms_75_d2 visit_number_d1 visit_number_75_d1

local resultados fc_admin

eststo clear
	
*Regressions at the 'prenda' level	
foreach var of varlist `resultados'  {
	do "$directorio\DoFiles\plot_te.do" ///
				`var' "${C0}"
	}

	
*Regressions at the 'customer' level	
collapse reincidence prestamo dummy* t_prod (min) prod, by(NombrePignorante fecha_inicial)
*Hack to preserve sintaxis of dofile 'plot_te.do'
gen suc_x_dia = _n
sort NombrePignorante fecha_inicial
bysort NombrePignorante : keep if _n==1

	do "$directorio\DoFiles\plot_te.do" ///
				reincidence "`C0'"
	
*************************
	esttab using "$directorio/Tables/reg_results/te.csv", se r2 star(* 0.1 ** 0.05 *** 0.01) b(a2) ///
	scalars("DepVarMean Dependent Var Mean") replace 
	
	


	
********************************************************************************	
********************************************************************************
*Robustness check


*ADMIN DATA
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", clear

*CONDITION TO POSITIVE PAYMENT
keep if sum_p_c>0

*Aux Dummies 
tab dow, gen(dummy_dow)
tab suc, gen(dummy_suc)


local C0 = "prestamo dummy_*" /*Controls*/
local resultados des_c  dias_al_desempenyo   num_p  sum_porcp_c ref_c

foreach var of varlist `resultados' {
	rename `var' `var'_robust
	}
	
eststo clear
	
*Regressions at the 'prenda' level	
foreach var of varlist `resultados'  {
	do "$directorio\DoFiles\plot_te.do" ///
				`var' "`C0'"
	}

	
*Regressions at the 'customer' level
collapse reincidence prestamo dummy* t_prod  (min) prod, by(NombrePignorante fecha_inicial)
*Hack to preserve sintaxis of dofile 'plot_te.do'
gen suc_x_dia = _n
sort NombrePignorante fecha_inicial
bysort NombrePignorante : keep if _n==1
rename reincidence reincidence_robust

	do "$directorio\DoFiles\plot_te.do" ///
				reincidence_robust "`C0'"
	
*************************
	esttab using "$directorio/Tables/reg_results/te_robust.csv", se r2 star(* 0.1 ** 0.05 *** 0.01) b(a2) ///
	scalars("DepVarMean Dependent Var Mean") replace 


