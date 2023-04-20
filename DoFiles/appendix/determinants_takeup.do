
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Feb. 28, 2023
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Determinants of take-up

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)


gen impatience = 1-t_consis1  

*Lists of variables according to its clasification
local familia fam_pide fam_comun 
local ingreso faltas ahorros
local self_control  pb impatience hace_presupuesto tentado rec_cel
local experiencia pres_antes cta_tanda pr_recup 
local otros  edad genero masqueprepa estresado_seguido low_cost low_time
 
logit choose_commitment `familia' `ingreso' `self_control' `experiencia' `otros', r
 logit choose_commitment pb, r
 
 
local alpha = .05 // for 95% confidence intervals 
 
matrix blp = J(18, 6, .)	
matrix blp_i = J(18, 6, .)

matrix lgit = J(18, 6, .)	
matrix lgit_i = J(18, 6, .)

local row = 1
foreach var of varlist  `familia' `ingreso' `self_control' `experiencia' `otros'  {

	*Total effect
	qui reg choose_commitment `familia' `ingreso' `self_control' `experiencia' `otros', r
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
		
	qui logit choose_commitment `familia' `ingreso' `self_control' `experiencia' `otros', r
	
	* LOGIT
	matrix lgit[`row',1] = `row'
	// Beta 
	matrix lgit[`row',2] = _b[`var']
	
	// Standard error
	matrix lgit[`row',3] = _se[`var']
	// P-value
	matrix lgit[`row',4] = 2*invnormal(abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix lgit[`row',5] =  _b[`var'] - invnormal(`=`alpha'/2')*_se[`var']
	matrix lgit[`row',6] =  _b[`var'] + invnormal(`=`alpha'/2')*_se[`var']
	
	
	*-------------------------------------------------------------
	
	
	* Individual effect
	qui reg choose_commitment `var', r
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
	
	* LOGIT
	qui logit choose_commitment `var', r
		
	matrix lgit_i[`row',1] = `row' + 10
	// Beta 
	matrix lgit_i[`row',2] = _b[`var']
	// Standard error
	matrix lgit_i[`row',3] = _se[`var']
	// P-value
	matrix lgit_i[`row',4] = 2*invnormal(abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix lgit_i[`row',5] =  _b[`var'] - invnormal(`=`alpha'/2')*_se[`var']
	matrix lgit_i[`row',6] =  _b[`var'] + invnormal(`=`alpha'/2')*_se[`var']
	
	local row = `row' + 1
	}
	
	
	matrix colnames blp_i = "k" "beta" "se" "p" "lo" "hi"
	matrix colnames blp = "k" "beta" "se" "p" "lo" "hi"
	
	matrix colnames lgit = "k" "beta" "se" "p" "lo" "hi"
	matrix colnames lgit_i = "k" "beta" "se" "p" "lo" "hi"
	
	mat rownames blp_i =  "Fam asks" "Common asks" ///
		 "Income index" "Savings" "Present bias" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca" "Prob recovery" ///
		 "Age"  "Gender" "More high school" "Stressed" "Low time" "Low cost"	 
	mat rownames blp =  "Fam asks" "Common asks" ///
		 "Income index" "Savings" "Present bias" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca" "Prob recovery" ///
		 "Age"  "Gender" "More high school" "Stressed" "Low time" "Low cost"		 

	mat rownames lgit =  "Fam asks" "Common asks" ///
		 "Income index" "Savings" "Present bias" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca" "Prob recovery" ///
		 "Age"  "Gender" "More high school" "Stressed" "Low time" "Low cost"	 
	mat rownames lgit_i =  "Fam asks" "Common asks" ///
		 "Income index" "Savings" "Present bias" "Impatience" "Makes budget" "Tempted" "Reminder" ///
		 "Pawn before" "Rosca" "Prob recovery" ///
		 "Age"  "Gender" "More high school" "Stressed" "Low time" "Low cost"			 
			 
			 
coefplot (matrix(blp_i[,2]), offset(0.06) ci((blp_i[,5] blp_i[,6]))  ciopts(lcolor(gs4))) ///
	(matrix(blp[,2]), offset(-0.06) ci((blp[,5] blp[,6]))  ciopts(lcolor(gs4))) , ///
		headings("Fam asks" = "{bf:Family}" "Income index" = "{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(order(2 "Bivariate" 4 "Multivariate") pos(6) rows(1))  xline(0)  graphregion(color(white)) 
graph export "$directorio\Figuras\determinants_takeup_reg.pdf", replace		
		
coefplot (matrix(lgit_i[,2]), offset(0.06) ci((lgit_i[,5] lgit_i[,6]))  ciopts(lcolor(gs4))) ///
	(matrix(lgit[,2]), offset(-0.06) ci((lgit[,5] lgit[,6]))  ciopts(lcolor(gs4))) , ///
		headings("Fam asks" = "{bf:Family}" "Income index" = "{bf:Income}" "Present bias" ="{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(order(2 "Bivariate" 4 "Multivariate") pos(6) rows(1))  xline(0)  graphregion(color(white)) 		
graph export "$directorio\Figuras\determinants_takeup_logit.pdf", replace

