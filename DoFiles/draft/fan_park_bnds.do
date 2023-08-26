
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Oct. 2, 2022
* Last date of modification: 
* Modifications:
* Files used:     
		- 
* Files created:  

* Purpose: Fan & Park (2010) bounds

*******************************************************************************/
*/

clear all
set maxvar 100000
set seed 321
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)
keep apr fc_admin prestamo des_c choose_commitment t_prod prod suc_x_dia $C0 
********************************************************************************

*Binary treatment variable
gen treat = t_prod==2 if inlist(t_prod,1,2)

*Dep var in benefit
replace apr = -apr
replace fc_admin = -fc_admin/prestamo

*Bounds at 0
fan_park apr treat $C0 , delta_values(0) cov_partition(8) nograph seed(321)
mat list r(bounds)
mat list r(sigma_2)
mat bnd = r(bounds)
mat varz = r(sigma_2)

count if treat==1
local n1 = `r(N)'
local signif = 5
*Lower bound CI
di bnd[1,1] - invnormal(1-`signif'/100)*sqrt(varz[1,1])/sqrt(`n1')
di bnd[1,1] + invnormal(1-`signif'/100)*sqrt(varz[1,1])/sqrt(`n1')

*Upper bound CI
di bnd[1,2] - invnormal(1-`signif'/100)*sqrt(varz[1,2])/sqrt(`n1')
di bnd[1,2] + invnormal(1-`signif'/100)*sqrt(varz[1,2])/sqrt(`n1')

*Fan Park bounds with covariates
fan_park apr treat $C0 , delta_partition(100) cov_partition(7) seed(321)
graph export "$directorio/Figuras/fan_park_bounds_apr.pdf", replace


