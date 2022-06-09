
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: February. 23, 2022
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Survival graph (recovery)

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear

*Survival graph (probability of ending) by treatment arm
forvalues i = 1/5 {
	cumul dias_ultimo_mov if concluyo_c==1 & t_prod==`i', gen(ecd_t`i') 
	su concluyo_c if t_prod==`i'
	replace ecd_t`i' = ecd_t`i'*`r(mean)'*100
	}
	

*Graph
sort t_producto dias_ultimo_mov
twoway (line ecd_t1 dias_ultimo_mov, lwidth(medthick) lcolor(black) xline(105, lpattern(dot) lcolor(gs10))) ///
	(line ecd_t2 dias_ultimo_mov, lwidth(medthick) lcolor(navy%90) xline(30 60 90, lcolor(gs12))) ///
	(line ecd_t4 dias_ultimo_mov, lwidth(medthick) lcolor(maroon%90)) ///
	, graphregion(color(white)) ///
	 xtitle("Elapsed days") ytitle("Percentage (%)") ///
	 legend(order(1 "Status-quo" 2 "Forced commitment" 3 "Choice commitment") size(small) pos(6) rows(1))
graph export "$directorio\Figuras\survival_graph_ended.pdf", replace

********************************************************************************

*Survival graph (probability of recovery) by treatment arm
forvalues i = 1/5 {
	cumul dias_al_desempenyo if t_prod==`i', gen(ecdf_t`i') 
	su des_c if t_prod==`i'
	replace ecdf_t`i' = ecdf_t`i'*`r(mean)'*100
	}

*Graph	
sort t_producto dias_al_desempenyo	
twoway (line ecdf_t1 dias_al_desempenyo, lwidth(medthick) lcolor(black) xline(105, lpattern(dot) lcolor(gs10))) ///
	(line ecdf_t2 dias_al_desempenyo, lwidth(medthick) lcolor(navy%90) xline(30 60 90, lcolor(gs12))) ///
	(line ecdf_t4 dias_al_desempenyo, lwidth(medthick) lcolor(maroon%90)) ///
	, graphregion(color(white)) ///
	xtitle("Elapsed days to recovery") ytitle("Percentage %") ///
	 legend(order(1 "Status-quo" 2 "Forced commitment" 3 "Choice commitment") size(small) pos(6) rows(1))
graph export "$directorio\Figuras\survival_graph_unpledge.pdf", replace
		
