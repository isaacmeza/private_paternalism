
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Jan. 22, 2023
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Imputation of censored (not observed final default status) loans with best prediction

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
set seed 1
drop fc_admin cost_losing_pawn downpayment_capital apr

	*Recovery at 105 days
gen des_105 = des_c if dias_al_desempenyo<=110
replace des_105 = 0 if missing(des_105)	
	*Not recovery by 105 days
gen def_105 = 1-des_105
	*Sum of payments up to 105 days
gen sum_p105_c = sum_porcp105_c*prestamo
gen sum_105_int_c = sum_porc105_int_c*prestamo
gen sum_105_pay_fee_c = sum_porc105_pay_fee_c*prestamo


*-----------------------------------------------------------------------------------------------------
*Imputation

	*Days towards def/rec
replace dias_al_default = 110 if dias_al_default>110 & des_105==0
replace dias_al_desempenyo = . if dias_al_desempenyo>110

	*Financial cost
gen double fc_admin = .
		*Only fees and interest for recovered pawns (by 105)
replace fc_admin = sum_105_int_c + sum_105_pay_fee_c if des_105==1
		*All payments + appraised value when not recovered (by 105)
replace fc_admin = sum_p105_c + prestamo_i/(0.7) if des_105==0

	*cost of losing pawn
gen double cost_losing_pawn = 0
replace cost_losing_pawn = sum_p105_c - sum_105_int_c - sum_105_pay_fee_c + prestamo_i/(0.7) if des_105==0

	*Downpayment
gen double downpayment_capital = 0
replace downpayment_capital = sum_p105_c - sum_105_int_c - sum_105_pay_fee_c if des_105==0

	*APR
gen double apr = (1 + (fc_admin/prestamo)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_105==1
replace apr = (1 + (fc_admin/prestamo)/dias_al_default)^dias_al_default - 1  if des_105==0

*-------------------------------------------------------------------------------

eststo clear
*TE
foreach var of varlist fc_admin  sum_105_int_c sum_105_pay_fee_c downpayment_capital cost_losing_pawn def_105 apr {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
}

esttab using "$directorio/Tables/reg_results/decomposition_main_te_by105.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 

*-------------------------------------------------------------------------------

*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4

replace fc_admin = -fc_admin
replace apr = -apr*100
replace des_105 = des_105*100

******** TOT-TUT-ATE ********
*****************************

eststo clear
foreach var of varlist apr fc_admin des_105 {

		*ToT-TuT
	eststo : tot_tut `var' Z choose_commitment ,  vce(cluster suc_x_dia)	
	qui su `var' if e(sample) & t_prod==1
	local mn = `r(mean)'
	estadd scalar ContrMean = `mn'
	test ATE = TuT
	estadd scalar ate_tut = `r(p)'
	test ATE = ToT
	estadd scalar ate_tot = `r(p)'
	local sign_tt = sign(_b[ToT]-_b[TuT])
	test TuT-ToT = 0
	estadd scalar tut_tot = `r(p)'
	estadd scalar tut_tot_1 = ttail(r(df_r),`sign_tt'*sqrt(r(F)))
}


*Save results	
esttab using "$directorio/Tables/reg_results/tot_tut_by105.csv", se ${star} b(a2) ///
		scalars("ContrMean Control Mean"  ///
		"ate_tut H_0 : ATE-TuT=0" ///
		"ate_tot H_0 : ATE-ToT=0" ///
		"tut_tot H_0 : ToT-TuT=0" ///
		"tut_tot_1 H_0 : ToT-TuT$\geq$ 0" ///
		)  replace 
		
*-------------------------------------------------------------------------------		
		