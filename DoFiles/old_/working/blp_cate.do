
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	July. 31, 2023
* Last date of modification: 
* Modifications: - 
* Files used:     

* Files created:  

* Purpose: determinants of CATE (BLP) 

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : te_grf.R, tot_tut_instr_forest.R

********************************************************************************


*Load data with BLP
import delimited "$directorio/_aux/apr_te_blp.csv", clear
	
matrix blp_i = J(17, 6, .)
matrix blp = J(17, 6, .)
local row = 1
foreach name in "fam.asks" "trouble.paying.bills" "savings" "patience" "future.patience" "sure.confidence" "makes.budget" "tempted" "sms.reminder" "pawn.before" "rosca" "age" "female" "more.high.school" "stressed" "transport.time" "transport.cost"   {
		
	* Individual effect
	matrix blp_i[`row',1] = `row'
	// Beta 
	su estimate_i if term=="`name'", meanonly 
	matrix blp_i[`row',2] = `r(mean)'

	// Standard error
	su stderror_i if term=="`name'", meanonly
	matrix blp_i[`row',3] = `r(mean)'
	// P-value
	su pvalue_i if term=="`name'", meanonly
	matrix blp_i[`row',4] = `r(mean)'
	// Confidence Intervals
	matrix blp_i[`row',5] = blp_i[`row',2] - 1.96*blp_i[`row',3]
	matrix blp_i[`row',6] = blp_i[`row',2] + 1.96*blp_i[`row',3]
	
	*-------------------------------------------------------------
	
	* Total effect
	matrix blp[`row',1] = `row'
	// Beta 
	su estimate if term=="`name'", meanonly 
	matrix blp[`row',2] = `r(mean)'

	// Standard error
	su stderror if term=="`name'", meanonly
	matrix blp[`row',3] = `r(mean)'
	// P-value
	su pvalue if term=="`name'", meanonly
	matrix blp[`row',4] = `r(mean)'
	// Confidence Intervals
	matrix blp[`row',5] = blp[`row',2] - 1.96*blp[`row',3]
	matrix blp[`row',6] = blp[`row',2] + 1.96*blp[`row',3]
	local row = `row' + 1
}


matrix colnames blp_i = "k" "beta" "se" "p" "lo" "hi"
matrix colnames blp = "k" "beta" "se" "p" "lo" "hi"

	
mat rownames blp_i =  "Fam asks money" ///
	 "Trouble paying bills" "Savings" "Patience" "Future patience" "Sure-confidence" "Makes budget" "Tempted" "Want SMS Reminder" ///
	 "Pawn before" "Rosca participant"  ///
	 "Age"  "Female" "More high school" "Stressed" "Transport time" "Transport cost"	
	 
mat rownames blp =  "Fam asks money" ///
	 "Trouble paying bills" "Savings" "Patience" "Future patience" "Sure-confidence" "Makes budget" "Tempted" "Want SMS Reminder" ///
	 "Pawn before" "Rosca participant"  ///
	 "Age"  "Female" "More high school" "Stressed" "Transport time" "Transport cost"			 
		 
			 
coefplot (matrix(blp_i[,2]), offset(0.06) ci((blp_i[,5] blp_i[,6]))  ciopts(lcolor(gs4))) ///
	(matrix(blp[,2]), offset(-0.06) ci((blp[,5] blp[,6]))  ciopts(lcolor(gs4))) , ///
		headings("Fam asks money" = "{bf:Family}" "Trouble paying bills" = "{bf:Income}" "Patience" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) legend(order(2 "Bivariate (DR)" 4 "Multivariate (DR)") pos(6) rows(1))  xline(0)  graphregion(color(white)) 
graph export "$directorio\Figuras\blp_cate_apr.pdf", replace
