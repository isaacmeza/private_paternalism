
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

import delimited "$directorio/_aux/tot_apr_instr_forest.csv", clear
tempfile temp_tot
rename inst_hat_oobpredictions inst_hat_1
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_1
save `temp_tot'


import delimited "$directorio/_aux/tut_apr_instr_forest.csv", clear
tempfile temp_tut
rename inst_hat_oobpredictions inst_hat_0
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_0
save `temp_tut'

import delimited "$directorio/_aux/apr_te_grf.csv", clear
merge 1:1 prenda using `temp_tot', nogen
merge 1:1 prenda using `temp_tut', nogen
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)

********************************************************************************

gen winners_paternalism_choosers = (inst_hat_1>0) if pro_7==1
gen winners_paternalism_nonchoosers = (inst_hat_0>0) if pro_6==1
gen winners_paternalism = (tau_hat_oobpredictions>0) if t_prod==4

gen impatience = 1-t_consis1  

*Lists of variables according to its clasification
local familia fam_pide fam_comun 
local ingreso faltas ahorros
local self_control  pb confidence_100 impatience hace_presupuesto tentado rec_cel
local experiencia pres_antes cta_tanda pr_recup 
local otros  edad genero masqueprepa estresado_seguido low_cost low_time
 
 
foreach vardep of varlist winners_paternalism* {

preserve	
local alpha = .05 // for 95% confidence intervals 
 
matrix blp = J(19, 6, .)	
matrix blp_i = J(19, 6, .)

local row = 1
foreach var of varlist  `familia' `ingreso' `self_control' `experiencia' `otros'  {

	*Total effect
	qui reg `vardep' `familia' `ingreso' `self_control' `experiencia' `otros', r
	local df = e(df_r)
	
	matrix blp[`row',1] = `row'
	// Beta 
	matrix blp[`row',2] = _b[`var']
	
	// Standard error
	matrix blp[`row',3] = _se[`var']
	// P-value
	matrix blp[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix blp[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix blp[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	
	*-------------------------------------------------------------
	
	
	* Individual effect
	qui reg `vardep' `var', r
	local df = e(df_r)	
		
	matrix blp_i[`row',1] = `row' + 10
	// Beta 
	matrix blp_i[`row',2] = _b[`var']
	// Standard error
	matrix blp_i[`row',3] = _se[`var']
	// P-value
	matrix blp_i[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix blp_i[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix blp_i[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	
	local row = `row' + 1
	}
	
	
	matrix colnames blp_i = "k" "beta" "se" "p" "lo" "hi"
	matrix colnames blp = "k" "beta" "se" "p" "lo" "hi"

	
	mat rownames blp_i =  "Fam asks" "Common asks" ///
		 "Poverty index" "Savings" "Present bias" "Sure confidence" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca" "Prob recovery" ///
		 "Age"  "Gender" "More high school" "Stressed" "Low time" "Low cost"	 
	mat rownames blp =  "Fam asks" "Common asks" ///
		 "Poverty index" "Savings" "Present bias" "Sure confidence" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca" "Prob recovery" ///
		 "Age"  "Gender" "More high school" "Stressed" "Low time" "Low cost"		 
		 
			 
			 
coefplot (matrix(blp_i[,2]), offset(0.06) ci((blp_i[,5] blp_i[,6]))  ciopts(lcolor(gs4))) ///
	(matrix(blp[,2]), offset(-0.06) ci((blp[,5] blp[,6]))  ciopts(lcolor(gs4))) , ///
		headings("Fam asks" = "{bf:Family}" "Poverty index" = "{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(order(2 "Bivariate" 4 "Multivariate") pos(6) rows(1))  xline(0)  graphregion(color(white)) 
graph export "$directorio\Figuras\determinants_`vardep'.pdf", replace		
		

restore
}