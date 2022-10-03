
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 17, 2022
* Last date of modification: Sept. 26, 2022
* Modifications: Added consolidated outcomes to account for multiple pawns in a same day
	- Redefinition of main outcomes
* Files used:     
		- 
* Files created:  

* Purpose: Robustness check to account for multiple-visits/pawns.

*******************************************************************************/
*/

use "$directorio/_aux/preMaster.dta", clear

eststo clear

  
*Put dummies for these cases as we are currently doing (to allow for flexibility in the regression and let them have less influence on the estimation of TE --ie the slope)
eststo: reg fc_i_admin i.t_prod dummy_* num_arms_d* visit_number_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su fc_i_admin if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg apr_i i.t_prod dummy_* num_arms_d* visit_number_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su apr_i if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg des_i_c i.t_prod dummy_* num_arms_d* visit_number_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su des_i_c if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg def_i_c i.t_prod dummy_* num_arms_d* visit_number_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su def_i_c if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
	
*Drop multiple visits
preserve
keep if visit_number==1
eststo: reg fc_i_admin i.t_prod dummy_* num_arms_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su fc_i_admin if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg apr_i i.t_prod dummy_* num_arms_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su apr_i if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg des_i_c i.t_prod dummy_* num_arms_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su des_i_c if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg def_i_c i.t_prod dummy_* num_arms_d* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su def_i_c if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
restore

*A more standard thing to do here would be to estimate a regression that always given clients the FIRST treatment status they were assigned. ITT method where we use the FIRST treatment
preserve
sort NombreP fecha_inicial
by NombreP  : gen first_tr = t_prod[1] if !missing(t_prod)
eststo: reg fc_i_admin i.first_tr dummy_* num_arms_d* visit_number_d* if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
su fc_i_admin if e(sample) & first_tr==1
estadd scalar ContrMean = `r(mean)'
eststo: reg apr_i i.first_tr dummy_* num_arms_d* visit_number_d* if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
su apr_i if e(sample) & first_tr==1
estadd scalar ContrMean = `r(mean)'
eststo: reg des_i_c i.first_tr dummy_* num_arms_d* visit_number_d* if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
su des_i_c if e(sample) & first_tr==1
estadd scalar ContrMean = `r(mean)'
eststo: reg def_i_c i.first_tr dummy_* num_arms_d* visit_number_d* if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
su def_i_c if e(sample) & first_tr==1
estadd scalar ContrMean = `r(mean)'
restore



esttab using "$directorio/Tables/reg_results/multiple_loans.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(1.t_producto 2.t_producto 4.t_producto 2.first_tr 4.first_tr) replace 
