
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 17, 2022
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Robustness check to account for multiple-loans.

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear

eststo clear

  
*Put dummies for these cases as we are currently doing (to allow for flexibility in the regression and let them have less influence on the estimation of TE --ie the slope)
eststo: reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su fc_admin if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg apr i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su apr if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
	
*Drop multiple pawns
preserve
keep if visit_number==1
eststo: reg fc_admin i.t_prod dummy_* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su fc_admin if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
eststo: reg apr i.t_prod dummy_* if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su apr if e(sample) & t_prod==1
estadd scalar ContrMean = `r(mean)'
restore

*A more standard thing to do here would be to estimate a regression that always given clients the FIRST treatment status they were assigned. ITT method where we use the FIRST treatment
preserve
sort NombreP fecha_inicial
by NombreP  : gen first_tr = t_prod[1] if !missing(t_prod)
eststo: reg fc_admin i.first_tr $C0 if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
su fc_admin if e(sample) & first_tr==1
estadd scalar ContrMean = `r(mean)'
eststo: reg apr i.first_tr $C0 if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
su apr if e(sample) & first_tr==1
estadd scalar ContrMean = `r(mean)'
restore

esttab using "$directorio/Tables/reg_results/multiple_loans.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(1.t_producto 2.t_producto 4.t_producto 2.first_tr 4.first_tr) replace 
