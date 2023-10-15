********************
version 17.0
********************

/*
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: Februrary. 8, 2022
* Modifications: 
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Determinants of choice (linear model)

*******************************************************************************/
*/


*ADMIN DATA
use "$directorio/DB/Master.dta", clear

gen confidence = (pr_recup==100)
gen dif_value = (val_pren>=prestamo)

local mod1 genero edad dif_value pres_antes confidence masqueprepa
local mod2 genero edad dif_value pres_antes confidence masqueprepa t_consis1


eststo clear
forvalues m = 1/2 {
	*OLS
	eststo : reg choose_commitment  `mod`m''  , r
	su choose_commitment if e(sample) 
	estadd scalar DepVarMean = `r(mean)'
	
	*LASSO
	cvlasso choose_commitment  `mod`m''
	local lopt =  e(lopt)
	eststo : lasso2 choose_commitment  `mod`m'', lambda(`lopt') 
	

	forvalues t = 4/5 {
			*OLS
		eststo : reg choose_commitment  `mod`m'' if t_prod==`t' , r
		su choose_commitment if e(sample) 
		estadd scalar DepVarMean = `r(mean)'
		
		*LASSO
		cvlasso choose_commitment  `mod`m'' if t_prod==`t'
		local lopt =  e(lopt)
		eststo : lasso2 choose_commitment  `mod`m'' if t_prod==`t', lambda(`lopt') 

	}
}
	

esttab using "$directorio/Tables/reg_results/determinants_choose.csv", se r2 ${star} b(a2) ///
		scalars("DepVarMean Dependent Variable Mean") replace 
