
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

use "$directorio/DB/Master.dta", clear



*Ever pawns again conditional on repaying first pawn
gen reincidence_des = !missing(days_second_pawns)  if first_pawn==1 & !missing(first_dias_des)
*Ever pawns again conditional on not repaying first pawn
gen reincidence_def = !missing(days_second_pawns)  if first_pawn==1 & missing(first_dias_des)



*Ever pawns a different piece
gen reincidence_other = !missing(days_second_pawns) & another_piece_second==1 if first_pawn==1



*Dummy indicating if customer returned after first visit & after 90
gen reincidence_ar =  !missing(days_second_pawns) & (days_second_pawns>=90) if first_pawn==1
*Dummy indicating if customer returned after first visit & within 90 days
gen reincidence_br =  !missing(days_second_pawns) & (days_second_pawns<=90) if first_pawn==1



*-------------------------------------------------------------------------------

********************************************************
*			      		 REGRESSIONS				   *
********************************************************

eststo clear

foreach var of varlist reincidence reincidence_des reincidence_def reincidence_other reincidence_ar reincidence_br days_second_pawns {
	
	eststo : reg `var' i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'	
	
}
esttab using "$directorio/Tables/reg_results/repeat_loans.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 
	
	
	
*-------------------------------------------------------------------------------
	
********************************************************
*			      		 GRAPHS						   *
********************************************************	

foreach t in 1 2 4 {
	
	gen reincidence_days_before_`t' = .
		gen reincidence_days_beforeh_`t' = .
		gen reincidence_days_beforel_`t' = .	
	gen reincidence_days_after_`t' = .
		gen reincidence_days_afterh_`t' = .
		gen reincidence_days_afterl_`t' = .
}


forvalues x = 1(2)112 {
	qui {	
	*Dummy indicating if customer returned after first visit WITHIN x days
	cap drop aux
	gen aux = !missing(days_second_pawns) & days_second_pawns <= `x' if first_pawn==1 
	reg aux ibn.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia) nocons
	foreach t in 1 2 4 {
		replace reincidence_days_before_`t' = _b[`t'.t_prod] in `x'
		replace reincidence_days_beforeh_`t' = _b[`t'.t_prod] + invnormal(0.95)*_se[`t'.t_prod] in `x'
		replace reincidence_days_beforel_`t' = _b[`t'.t_prod] - invnormal(0.95)*_se[`t'.t_prod] in `x'
		}
		
	*Dummy indicating if customer returned after first visit AFTER x days 
	cap drop aux
	gen aux = !missing(days_second_pawns) & days_second_pawns >= `x' if first_pawn==1
	reg aux ibn.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia) nocons
	foreach t in 1 2 4 {
		replace reincidence_days_after_`t' = _b[`t'.t_prod] in `x'
		replace reincidence_days_afterh_`t' = _b[`t'.t_prod] + invnormal(0.95)*_se[`t'.t_prod] in `x'
		replace reincidence_days_afterl_`t' = _b[`t'.t_prod] - invnormal(0.95)*_se[`t'.t_prod] in `x'
		}
		
		}
	}	



gen dy = _n if _n<112

*Probability of a second loan within x time since first loan
twoway (rarea reincidence_days_beforeh_1 reincidence_days_beforel_1 dy, color(gs5%30)) ///
		(rarea reincidence_days_beforeh_2 reincidence_days_beforel_2 dy, color(navy%30))  ///
		(line reincidence_days_before_1 dy, color(black) lwidth(medthick)) ///
		(line reincidence_days_before_2 dy, color(navy) lwidth(medthick)) ///
		(line reincidence_days_before_4 dy, color(maroon) lwidth(medthick) xline(90 105, lcolor(gs12))) ///
		, graphregion(color(white)) xtitle("Days within first loan") xlabel(0(20)100) ytitle("Prob. of taking second loan") ///
		legend(order (3 "Control" 4 "Forced commitment" 5 "Choice commitment") pos(6) rows(1) size(small))
graph export "$directorio\Figuras\prob_reincidence_within.pdf", replace

*Probability of a second loan before x time 
twoway (rarea reincidence_days_afterh_1 reincidence_days_afterl_1 dy, color(gs5%30)) ///
		(rarea reincidence_days_afterh_2 reincidence_days_afterl_2 dy, color(navy%30))  ///
		(line reincidence_days_after_1 dy, color(black) lwidth(medthick)) ///
		(line reincidence_days_after_2 dy, color(navy) lwidth(medthick)) ///
		(line reincidence_days_after_4 dy, color(maroon) lwidth(medthick) xline(90 105, lcolor(gs12))) ///
		, graphregion(color(white)) xtitle("Days after first loan") xlabel(0(20)100) ytitle("Prob. of taking second loan") ///
		legend(order (3 "Control" 4 "Forced commitment" 5 "Choice commitment") pos(6) rows(1) size(small))
graph export "$directorio\Figuras\prob_reincidence_after.pdf", replace


