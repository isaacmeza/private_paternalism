
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

* Purpose: Imputation of censored (not observed final default status) loans with extreme cases.

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
drop fc_admin cost_losing_pawn downpayment_capital apr

forvalues i = 0/1 {
	forvalues j = 0/1 {
		
		preserve
		*Imputation

			*Default/Recovery
		gen def_imp = def_c
		replace def_imp = `i' if t_prod==1 & concluyo_c==0
		replace def_imp = `j' if t_prod==2 & concluyo_c==0
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


		eststo clear
		*TE
		foreach var of varlist fc_admin sum_int_c downpayment_capital cost_losing_pawn def_imp apr {
			*OLS 
			eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2), vce(cluster suc_x_dia)
			su `var' if e(sample) & t_prod==1
			estadd scalar ContrMean = `r(mean)'
		}

		esttab using "$directorio/Tables/reg_results/decomposition_main_te_`i'_`j'.csv", se r2 ${star} b(a2) ///
				scalars("ContrMean Control Mean") keep(2.t_producto) replace 

*-------------------------------------------------------------------------------	
	restore		
	}
}