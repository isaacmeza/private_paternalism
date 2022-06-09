clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

* Rescale to positive scale (benefits)
gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr des_c eff_cost_loan pay_default choose_commitment t_prod prod suc_x_dia $C0 edad  faltas val_pren_std genero masqueprepa
********************************************************************************

* TOT-TUT using LATE approach
*IV
gen choice_nsq = (prod==5) /*z=2, t=1*/
gen choice_vs_control = (t_prod==4) if inlist(t_prod,1,4) 
gen choice_nonsq = (prod!=4) /*z!=2, t!=0*/
gen forced_fee_vs_choice = (t_prod==2) if inlist(t_prod,2,4)

 
*Stack IV/GMM
gen x1 = -(t_prod==4)*(prod==4)
gen x2 = (t_prod==4)*(prod==5)
gen z0 = -(t_prod==1)
gen z1 = (t_prod==2)
gen z2 = (t_prod==4)




qui su choose_commitment 
local p_rate = `r(mean)'


gen apr_tut = apr/(1-`p_rate')	

gen treat_tut = t_prod==2 if inlist(t_prod,4,2)

reg apr_tut i.treat_tut
fan_park apr_tut treat_tut $C0 edad  faltas val_pren_std genero masqueprepa, cov_partition(5)
mat bounds_tut = r(bounds)
*mat delta_tut = r(q_val)
mat delta_tut = r(delta_val)



gen apr_tot = apr/(`p_rate')	

gen treat_tot = t_prod==4 if inlist(t_prod,4,1)

reg apr_tot i.treat_tot
fan_park apr_tot treat_tot $C0 edad  faltas val_pren_std genero masqueprepa, cov_partition(5)
mat bounds_tot = r(bounds)
*mat delta_tot = r(q_val)
mat delta_tot = r(delta_val)


svmat bounds_tut 
svmat bounds_tot
svmat delta_tut 
svmat delta_tot



twoway (line bounds_tot1 delta_tot if inrange(delta_tot,-1000,1000))  (line bounds_tot2 delta_tot if inrange(delta_tot,-1000,1000))  (line bounds_tut1 delta_tut)  (line bounds_tut2 delta_tut, xline(0))

