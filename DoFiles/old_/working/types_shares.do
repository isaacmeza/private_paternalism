/*
Find shares of types in dataset.
*****************************************************************************
- Always compliers: 
		Repay under the control arm.
- Never compliers:
		Don't repay under forced fee arm.
- Sophisticated hyperbolic:
		Choose commitment in choice arm, and would have defaulted in control arm.
- Naïve hyperbolics:
		Don't choose commitment in choice arm, default in control arm, repay if forced into commitment.
*****************************************************************************		
Author : Isaac Meza
*/

use "$directorio/DB/Master.dta", clear


* Proportion of types in data

* Always compliers
su des_c if pro_2==0
local prop_ac = round(`r(mean)'*100,.1)
di `prop_ac'
* Never compliers
su def_c if pro_2==1
local prop_nc = round(`r(mean)'*100,.1)
di `prop_nc'
* The discussion for the hyperbolics is more complicated
* In principle individuals choosing commitment may be thought of as sophisticated hyperbolics.

gen choose_commitment = (producto==5) if (producto==4 | producto==5)
su choose_commitment
local prop_takeup = round(`r(mean)'*100,.1)
di `prop_takeup'
su des_c if choose_commitment==1
local prop_sh = round(`r(mean)'*`prop_takeup',.1)
di `prop_sh'

* However based on Figure 7 :  The effect of choice between fee-commitment and status quo. Panel (c) (def_te_choice_dec.do), we find that the `treatment effect' of the self selected take-up individuals is the same as in the forced-fee arm, i.e. take-up looks random (from the point of view of treatment effects).




* What if we attempt to follow the naive sequential (stepwise) algorithm to match types based on the proportions found above?

*Recode missing values
foreach var of varlist genero  masqueprepa faltas  {
	gen `var'_m = `var'
	replace `var'_m = 2 if missing(`var')
	}
tab faltas_m, gen(dummy_faltas)
foreach var of varlist val_pren_pr edad {
	gen `var'_m = `var'
	qui su `var'
	replace `var'_m = `r(mean)' if missing(`var')
	}	

* Predict repayment in the control arm
gen train = (runiform()<0.8)

*Using logit models
logit des_c genero edad val_pren_pr log_prestamo masqueprepa faltas dummy_* visit_number_d* if pro_2==0 & train==1
predict pr_des_c_control_1 if train==0 
 
logit des_c i.genero_m edad_m val_pren_pr_m log_prestamo i.masqueprepa_m dummy_* visit_number_d* if pro_2==0 & train==1
predict pr_des_c_control_2 if train==0 

cap drop perc
xtile perc = pr_des_c_control_1, nq(100)
gen predicted_des_c_c_1 =(perc>100-`prop_ac') if !missing(pr_des_c_control_1)
cap drop perc
xtile perc = pr_des_c_control_2, nq(100)
gen predicted_des_c_c_2 =(perc>100-`prop_ac') if !missing(pr_des_c_control_2)

tab predicted_des_c_c_1 des_c, cell
tab predicted_des_c_c_2 des_c, cell
tab predicted_des_c_c_*, cell


*Based on previous analysis
logit des_c i.genero_m edad_m val_pren_pr_m log_prestamo i.masqueprepa_m dummy_* visit_number_d* if pro_2==0 
predict pr_des_c_control 
cap drop perc
xtile perc = pr_des_c_control, nq(100)
gen always_compliers = (perc>100-`prop_ac') if !missing(pr_des_c_control)


* Predict default in forced-fee arm
logit def_c i.genero_m edad_m val_pren_pr_m log_prestamo i.masqueprepa_m dummy_* visit_number_d* if pro_2==1
predict pr_def_c_forced
cap drop perc
xtile perc = pr_def_c_forced, nq(100)
gen never_compliers = (perc>100-`prop_nc') if !missing(pr_def_c_forced)



* Predict choice
logit choose_commitment i.genero_m edad_m val_pren_pr_m log_prestamo i.masqueprepa_m dummy_* visit_number_d* if (producto==4 | producto==5)



	
	
	logit def_c genero edad val_pren_pr masqueprepa faltas ${C0} if pro_2==1 & always_compliers != 1
	predict pr_def_c_forced_fee if always_compliers==0
	
	su def_c if  pro_2==1 & always_compliers != 1
	local prop = round(`r(mean)'*100)
	di `prop'
 cap drop perc
 xtile perc = pr_def_c_forced_fee, nq(100)
gen never_compliers = (perc>=`prop') 




