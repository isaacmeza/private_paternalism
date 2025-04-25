
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	March. 16, 2022
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Effects of repeat pawning

*******************************************************************************/
*/
*Dataset with first visit only
use "$directorio/DB/Master.dta", clear
*Borrower level
duplicates drop NombreP, force

*Ever pawns again conditional on repaying first pawn
gen reincidence_des = !missing(days_second_pawns)  if first_pawn==1 & !missing(first_dias_des)


*Dummy indicating if customer returned after first visit & after 90
gen reincidence_ar =  !missing(days_second_pawns) & (days_second_pawns>=90) if first_pawn==1
*Dummy indicating if customer returned after first visit & within 90 days
gen reincidence_br =  !missing(days_second_pawns) & (days_second_pawns<=90) if first_pawn==1


*-------------------------------------------------------------------------------

********************************************************
*			      		 REGRESSIONS				   *
********************************************************

eststo clear

foreach var of varlist reincidence reincidence_ar reincidence_br  reincidence_other reincidence_des {
	
	eststo : reg `var' i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'	
	
}

esttab using "$directorio/Tables/reg_results/repeat_loans.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 
	