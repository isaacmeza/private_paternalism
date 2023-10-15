
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Jan. 22, 2023
* Last date of modification: September. 21, 2023
* Modifications: - Change value of lost pawn to (0.3/0.7) x loan
* Files used:     
		- 
* Files created:  

* Purpose: Imputation of censored (not observed final default status) loans with best prediction

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
set seed 1
drop fc_admin cost_losing_pawn downpayment_capital apr

	*% of first payment
gen first_pay_porc = first_pay/prestamo
	*% of mean payment
gen mn_porc_p105_c = mn_p105_c/prestamo
gen mn_porc_p210_c = mn_p210_c/prestamo

gen train = (runiform()<.8) if concluyo_c==1

*Elapsed days since treatment by treatment start date
twoway (scatter dias_ultimo_mov fecha_inicial if !missing(prod) & des_c==1, yline(110 220) msymbol(Oh)) ///
	(scatter dias_ultimo_mov fecha_inicial if !missing(prod) & def_c==1, msymbol(Oh)) ///
	(scatter dias_ultimo_mov fecha_inicial if !missing(prod) & concluyo_c==0, msymbol(Oh)), ///
	legend(order(1 "Recovery" 2 "Default" 3 "Not ended (Rollover)")) xtitle("Treatment date") ytitle("Elapsed days")
	
	 
********************************Slice obs model*********************************	 

gen slice = 1 if inrange(dias_ultimo_mov,0,220)
replace slice = 2 if dias_ultimo_mov>220


gen def_pr_m = .
gen def_pr = .

forvalues i = 1/2 {
	if `i'==1 {
		*Train prediction model insample 
		lasso logit def_c dias_ultimo_mov dias_primer_pago first_pay_porc sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c sum_porc105_int_c mn_porc_p105_c prestamo i.suc if concluyo_c==1 & slice==`i' & train==1
		qui predict pred_`i'
	}
	else {
		*Train prediction model insample 
		lasso logit def_c dias_ultimo_mov dias_primer_pago first_pay_porc sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c  sum_porcp150_c sum_porcp180_c sum_porcp210_c sum_porc105_int_c sum_porc210_int_c mn_porc_p105_c mn_porc_p210_c prestamo i.suc if concluyo_c==1 & slice==`i' & train==1
		qui predict pred_`i'
	}
}	 
forvalues i = 1/2 {
	replace def_pr_m = (pred_`i'>=0.5) if slice==`i'
}

*Classification error
tab def_pr_m def_c if train==1
tab def_pr_m def_c if train==0

forvalues i = 1/2 {
	if `i'==1 {
		*Train prediction model insample 
		lasso logit def_c dias_ultimo_mov dias_primer_pago first_pay_porc sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c sum_porc105_int_c mn_porc_p105_c prestamo i.suc if concluyo_c==1 & slice==`i'
		qui predict predf_`i'
	}
	else {
		*Train prediction model insample 
		lasso logit def_c dias_ultimo_mov dias_primer_pago first_pay_porc sum_porcp30_c sum_porcp60_c sum_porcp90_c sum_porcp105_c  sum_porcp150_c sum_porcp180_c sum_porcp210_c sum_porc105_int_c sum_porc210_int_c mn_porc_p105_c mn_porc_p210_c prestamo i.suc if concluyo_c==1 & slice==`i'
		qui predict predf_`i'
	}
}	 
forvalues i = 1/2 {
	qui replace def_pr = (predf_`i'>=0.5) if slice==`i'
}


*-----------------------------------------------------------------------------------------------------
*Imputation

	*Default/Recovery
gen def_imp = def_c
replace def_imp = def_pr if concluyo_c==0
gen des_imp = 1-def_imp


	*Days towards def/rec
replace dias_al_default = dias_ultimo_mov if concluyo_c==0 & def_imp==1
replace dias_al_default = 105 if dias_ultimo_mov<90 & concluyo_c==0 & def_imp==1
replace dias_al_default = 210 if inrange(dias_ultimo_mov, 110, 180) & concluyo_c==0 & def_imp==1
replace dias_al_default = 315 if inrange(dias_ultimo_mov, 220, 270) & concluyo_c==0 & def_imp==1
replace dias_al_default = 420 if dias_ultimo_mov>315 & concluyo_c==0 & def_imp==1
replace dias_al_desempenyo = dias_ultimo_mov if concluyo_c==0 & des_imp==1


	*Payment if imputed recovery
replace sum_p_c = prestamo + sum_inc_int if concluyo_c==0 & des_imp==1


	*Interest if imputed recovery
replace sum_int_c = sum_inc_int if concluyo_c==0 & des_imp==1 	


	*Financial cost
gen double fc_admin = .
		*Only fees and interest for recovered pawns
replace fc_admin = sum_int_c + sum_pay_fee_c if des_imp==1
		*All payments + appraised value net of loan when default
replace fc_admin = sum_p_c + prestamo_i*(0.3/0.7) if def_imp==1

	*cost of losing pawn
gen double cost_losing_pawn = 0
replace cost_losing_pawn = sum_p_c - sum_int_c - sum_pay_fee_c + prestamo_i*(0.3/0.7) if def_imp==1

	*Downpayment
gen double downpayment_capital = 0
replace downpayment_capital = sum_p_c - sum_int_c - sum_pay_fee_c if def_imp==1

	*APR
gen double apr = (1 + (fc_admin/prestamo)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_imp==1
replace apr = (1 + (fc_admin/prestamo)/dias_al_default)^dias_al_default - 1  if def_imp==1

*-------------------------------------------------------------------------------
save "$directorio/_aux/censoring_imp.dta", replace	
 
use "$directorio/_aux/censoring_imp.dta", clear	

eststo clear
*TE
foreach var of varlist fc_admin sum_int_c downpayment_capital cost_losing_pawn def_imp apr {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
}

esttab using "$directorio/Tables/reg_results/decomposition_main_te_imppr.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 
