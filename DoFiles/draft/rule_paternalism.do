
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	April. 22, 2022
* Last date of modification: May. 1, 2023
* Modifications: - Improvement of forests and change of definition in main outcomes
				- Extend the graph to full cdf
* Files used:     
		- tot_instr_forest.csv
		- tut_instr_forest.csv
		- Master.dta
* Files created:  

* Purpose: Who makes mistakes? Based on TuT & ToT forests predictions

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : te_grf.R & tot_tut_instr_forest.R

********************************************************************************


*Load data with forest predictions (created in te_grf.R & tot_tut_instr_forest.R)

import delimited "$directorio/_aux/tot_eff_instr_forest.csv", clear
tempfile temp_tot
rename inst_hat_oobpredictions inst_hat_1
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_1
save `temp_tot'


import delimited "$directorio/_aux/tut_eff_instr_forest.csv", clear
tempfile temp_tut
rename inst_hat_oobpredictions inst_hat_0
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_0
save `temp_tut'

import delimited "$directorio/_aux/eff_te_grf.csv", clear
merge 1:1 prenda using `temp_tot', nogen
merge 1:1 prenda using `temp_tut', nogen
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)



gen impatience = 1-t_consis1  
*Lists of variables according to its clasification
local familia fam_pide fam_comun 
local ingreso  ahorros
local self_control  pb confidence_100 impatience hace_presupuesto tentado rec_cel
local experiencia pres_antes cta_tanda  
local otros   genero masqueprepa estresado_seguido low_cost low_time
 
 
gen porc_benefitted = (inst_hat_0>0) if pro_6==1 
count if porc_benefitted==1
local totalobs = `r(N)'
 
matrix blp = J(19, 6, .)	
matrix blp_i = J(19, 6, .)

local row = 1
foreach var of varlist  `familia' `ingreso' `self_control' `experiencia' `otros'  {
	
	
	matrix blp[`row',1] = `row'
	count if porc_benefitted==1 & `var'==1 & !missing(`var')
	if `r(N)'/`totalobs'<=0.5 {
		matrix blp[`row',2] = 1-`r(N)'/`totalobs'
		matrix blp[`row',3] = -1
	}
	else {
		matrix blp_i[`row',2] = `r(N)'/`totalobs'
		matrix blp_i[`row',3] = 1
	}

local row = `row' + 1
}

	matrix colnames blp_i = "k" "beta" "se" "p" "lo" "hi"
	matrix colnames blp = "k" "beta" "se" "p" "lo" "hi"

	
	mat rownames blp_i =  "Fam asks" "Common asks" ///
		  "Savings" "Present bias" "Sure confidence" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca"  ///
		   "Gender" "More high school" "Stressed" "Low time" "Low cost"	 
	mat rownames blp = "Fam asks" "Common asks" ///
		  "Savings" "Present bias" "Sure confidence" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca"  ///
		   "Gender" "More high school" "Stressed" "Low time" "Low cost"		 
		 
			 
coefplot (matrix(blp[,2]), offset(-0.06) ci((blp[,5] blp[,6])) ciopts(lcolor(gs4))) ///
	(matrix(blp_i[,2]) , offset(-0.06) ci((blp_i[,5] blp_i[,6])) ciopts(lcolor(gs4))), ///
		headings("Fam asks" = "{bf:Family}" "Savings" = "{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Gender" = "{bf:Other}",labsize(medium))   graphregion(color(white)) legend(order(2 "Negative" 4 "Positive"))
graph export "$directorio\Figuras\rule_paternalism.pdf", replace



count if porc_benefitted==1
local totalobs = `r(N)'



foreach var of varlist  faltas   {
	cap drop pbenefit_`var'
	gen  pbenefit_`var' = .
	local j = 1
	su `var'
	gen normalize_`var' = (`var'-`r(min)')/(`r(max)'-`r(min)')
	forvalues t = 0(0.1)1 {
	
	count if porc_benefitted==1 & normalize_`var'>=`t' & !missing(`var')
	replace pbenefit_`var' = `r(N)'/`totalobs' in `j'
	
	local j = `j'+1
	}
}

libe



		
		