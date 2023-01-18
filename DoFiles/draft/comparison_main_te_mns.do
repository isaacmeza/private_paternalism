
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: 

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear


*Mark individuals with observables
gen sample_cov = !missing(edad) | !missing(faltas) | !missing(val_pren_std) | !missing(genero) | !missing(pres_antes) | !missing(plan_gasto) | !missing(masqueprepa) | !missing(pb)



*Decomposition of APR
	*effective cost of each component 
foreach var of varlist 	sum_int_c sum_pay_fee_c cost_losing_pawn downpayment_capital {
	gen double eff_`var'  = .
	replace eff_`var' = (1 + (`var'/prestamo)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_i_c==1
	replace eff_`var' = (1 + (`var'/prestamo)/dias_al_default)^dias_al_default - 1  if def_i_c==1
	replace eff_`var' = (1 + (`var'/prestamo)/dias_ultimo_mov)^dias_ultimo_mov - 1  if def_i_c==0 & des_i_c==0

}

eststo clear

*FC
foreach var of varlist  fc_admin  sum_int_c sum_pay_fee_c cost_losing_pawn downpayment_capital def_c {
	*OLS 
	eststo : reg `var' ibn.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia) nocons
	
	eststo : reg `var' ibn.t_prod if inlist(t_prod,1,2,4) & sample_cov==1, vce(cluster suc_x_dia) nocons
	
	
	
}

*APR
foreach var of varlist  apr eff_sum_int_c eff_sum_pay_fee_c eff_cost_losing_pawn eff_downpayment_capital {
	*OLS 
	eststo : reg `var' ibn.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia) nocons
	
	eststo : reg `var' ibn.t_prod if inlist(t_prod,1,2,4) & sample_cov==1, vce(cluster suc_x_dia) nocons
	
	
}


eststo : reg choose_commitment ibn.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia) nocons
	
eststo : reg choose_commitment ibn.t_prod if inlist(t_prod,1,2,4) & sample_cov==1, vce(cluster suc_x_dia) nocons

esttab using "$directorio/Tables/reg_results/decomposition_main_te_mns.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(1.t_producto 2.t_producto 4.t_producto) replace 
		
		
		
		
		
		
twoway 	(kdensity apr if t_prod==1) (kdensity apr if t_prod==2) (kdensity apr if t_prod==4), legend(order(1 "Control" 2 "Forced" 3 "Choice") pos(6) rows(1))