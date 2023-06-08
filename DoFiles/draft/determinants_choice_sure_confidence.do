/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	May. 25, 2023
* Last date of modification: 
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  
		
* Purpose: Propensity score determinants for 
			- choose_commitment
			- confidence_100
*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

*Standarize
foreach var of varlist edad pr_recup {
	su `var'
	replace `var' = (`var' - `r(mean)')/`r(sd)'
}

gen impatience = 1-t_consis1  

*Lists of variables according to its clasification
local familia fam_pide fam_comun 
local ingreso faltas ahorros
local self_control  pb confidence_100 impatience hace_presupuesto tentado rec_cel
local experiencia pres_antes cta_tanda pr_recup 
local otros  edad genero masqueprepa estresado_seguido low_cost low_time
 
 
	
local alpha = .05 // for 95% confidence intervals 
 
matrix blp = J(19, 6, .)	
matrix blp_i = J(19, 6, .)

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
	
	
	local row = `row' + 1
	}
	
	
matrix colnames blp_i = "k" "beta" "se" "p" "lo" "hi"
matrix colnames blp = "k" "beta" "se" "p" "lo" "hi"

	
mat rownames blp_i =  "Fam asks money" "Common asks money" ///
	 "Trouble paying bills" "Savings" "Present bias" "Sure confidence" "Impatience" "Makes budget" "Tempted" "Want SMS Reminder" ///
	 "Pawn before" "Rosca participant" "Prob recovery" ///
	 "Age"  "Female" "More high school" "Stressed" "< med transport time" "< med transport cost"	 
mat rownames blp =  "Fam asks money" "Common asks money" ///
	 "Trouble paying bills" "Savings" "Present bias" "Sure confidence" "Impatience" "Makes budget" "Tempted" "Want SMS Reminder" ///
	 "Pawn before" "Rosca participant" "Prob recovery" ///
	 "Age"  "Female" "More high school" "Stressed" "< med transport time" "< med transport cost"		 
		 
			 
			 
coefplot (matrix(blp_i[,2]), offset(0.06) ci((blp_i[,5] blp_i[,6]))  ciopts(lcolor(gs4))) ///
	(matrix(blp[,2]), offset(-0.06) ci((blp[,5] blp[,6]))  ciopts(lcolor(gs4))) , ///
		headings("Fam asks money" = "{bf:Family}" "Trouble paying bills" = "{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(order(2 "Bivariate" 4 "Multivariate") pos(6) rows(1))  xline(0)  graphregion(color(white)) 
graph export "$directorio\Figuras\determinants_choose_commitment.pdf", replace		
		

		
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------



keep if choose_commitment==0 | t_prod==1

*Lists of variables according to its clasification
local familia fam_pide fam_comun 
local ingreso faltas ahorros
local self_control  pb  impatience hace_presupuesto tentado rec_cel
local experiencia pres_antes cta_tanda  
local otros  edad genero masqueprepa estresado_seguido low_cost low_time

matrix blp = J(17, 6, .)	
matrix blp_i = J(17, 6, .)

local row = 1
foreach var of varlist  `familia' `ingreso' `self_control' `experiencia' `otros'  {

	*Total effect
	qui reg confidence_100 `familia' `ingreso' `self_control' `experiencia' `otros', r
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
	qui reg confidence_100 `var', r
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

	
mat rownames blp_i =  "Fam asks money" "Common asks money" ///
	 "Trouble paying bills" "Savings" "Present bias"  "Impatience" "Makes budget" "Tempted" "Want SMS Reminder" ///
	 "Pawn before" "Rosca participant" ///
	 "Age"  "Female" "More high school" "Stressed" "< med transport time" "< med transport cost"	 
mat rownames blp =  "Fam asks money" "Common asks money" ///
	 "Trouble paying bills" "Savings" "Present bias" "Impatience" "Makes budget" "Tempted" "Want SMS Reminder" ///
	 "Pawn before" "Rosca participant" ///
	 "Age"  "Female" "More high school" "Stressed" "< med transport time" "< med transport cost"		 
		 
			 
			 
coefplot (matrix(blp_i[,2]), offset(0.06) ci((blp_i[,5] blp_i[,6]))  ciopts(lcolor(gs4))) ///
	(matrix(blp[,2]), offset(-0.06) ci((blp[,5] blp[,6]))  ciopts(lcolor(gs4))) , ///
		headings("Fam asks money" = "{bf:Family}" "Trouble paying bills" = "{bf:Income}" "Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(order(2 "Bivariate" 4 "Multivariate") pos(6) rows(1))  xline(0)  graphregion(color(white)) 
graph export "$directorio\Figuras\determinants_confidence_100.pdf", replace		
		
