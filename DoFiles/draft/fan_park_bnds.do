
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
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)
keep apr fc_admin des_c choose_commitment t_prod prod suc_x_dia $C0 edad faltas val_pren_std genero masqueprepa
********************************************************************************

*Binary treatment variable
gen treat = t_prod==2 if inlist(t_prod,1,2)

*Dep var in benefit
replace apr = -apr

*Fan Park bounds with covariates
fan_park apr treat $C0 edad faltas val_pren_std genero masqueprepa, delta_partition(100) cov_partition(4) 
graph export "$directorio/Figuras/fan_park_bounds_apr.pdf", replace

fan_park des_c treat $C0 edad faltas val_pren_std genero masqueprepa, delta_partition(100) cov_partition(4) 
graph export "$directorio/Figuras/fan_park_bounds_des_c.pdf", replace
