/*
Treatment effect with all arms
*/


use "$directorio/DB/Master.dta", clear


foreach var of varlist fc_admin_disc def_c eff_cost_loan  {
	do "$directorio\DoFiles\appendix\plot_te_allarms.do" ///
				`var' "${C0}"
	}
