clear all

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)
local rep = 10000

* Rescale to positive scale (benefits)
gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)



su choose_commitment

tebounds des_c, treat(t_prod) control(1) treatment(4)  ncells(20) bs reps(100) graph

tebounds des_c, treat(t_prod) control(4) treatment(2)  ncells(20) bs reps(100) 





*IV
gen choice_nsq = (prod==5) /*z=2, t=1*/
gen choice_vs_control = (t_prod==4) if inlist(t_prod,4,1) 
gen choice_nonsq = (prod!=4) /*z!=2, t!=0*/
gen forced_fee_vs_choice = (t_prod==2) if inlist(t_prod,2,4)

ivregress 2sls des_c  (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
ivregress 2sls des_c  (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)


tebounds des_c, treat(choice_nonsq)  miv(forced_fee_vs_choice) ncells(5) bs reps(100) 




foreach var of varlist eff_cost_loan  {
		*TOT
	eststo : ivregress 2sls `var'  (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	cap drop esample_tot
	gen esample_tot = e(sample)
	su tau_eff if e(sample) 
	estadd scalar DepVarMean = `r(mean)'
	eststo : ivregress 2sls `var'   $C0 (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	eststo : ivregress 2sls `var'   $C0  edad  faltas val_pren_std genero masqueprepa (choice_nsq =  choice_vs_control) , vce(bootstrap, rep(5000))

		*TUT
	eststo : ivregress 2sls `var'  (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)