clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)

* Rescale to positive scale (benefits)
gen eff_cost_loan = -fc_admin/prestamo
*replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr des_c eff_cost_loan pay_default choose_commitment t_prod prod suc_x_dia $C0 edad  faltas val_pren_std genero masqueprepa
********************************************************************************

gen treat = t_prod==2 if inlist(t_prod,1,2)



fan_park apr treat, cov_partition(6) delta_values(-10 0 10) 