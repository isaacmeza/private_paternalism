
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	(Adapted from tot_tut.do)
* Last date of modification: February. 25, 2022
* Modifications: Regression based LATE TOT vs TUT- Computation of Ri & Bootsrtap p-values
* Files used:     
		- 
* Files created:  

* Purpose: ToT-TuT analysis 

*******************************************************************************/
*/
clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)
local rep = 1000

* Rescale to positive scale (benefits)
gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr des_c eff_cost_loan pay_default choose_commitment t_prod suc_x_dia $C0

********************************************************************************
foreach var of varlist  apr des_c eff_cost_loan pay_default {
	*Randomization inference 
	preserve
	qui su choose_commitment 
	local p_rate = `r(mean)'
	keep `var' t_prod suc_x_dia $C0

	ritest  t_prod ((_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')) , reps(`rep') cluster(suc_x_dia) left seed(5413) : reg `var' i.t_prod  
	local pval_ri1_`var' = r(p)[1,1]

	ritest  t_prod ((_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')) , reps(`rep') cluster(suc_x_dia) left seed(5413) : reg `var' i.t_prod $C0  
	local pval_ri2_`var' = r(p)[1,1]

	restore
	********************************************************************************

	*Bootstrap difference between ToT-TuT
	matrix btsp = J(`rep', 2, .) 
	forvalues i = 1/`rep' {
		di `i'
		preserve
		qui bsample, cluster(suc_x_dia)
		qui su choose_commitment 
		local p_rate = `r(mean)'
		qui reg `var' i.t_prod  
		if (e(V)[2,2]!=0 & e(V)[3,3]!=0) {
								*TOT - TUT
			matrix btsp[`i',1] = (_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
		}
		
		qui reg `var' i.t_prod $C0  
		if (e(V)[2,2]!=0 & e(V)[3,3]!=0) {
			matrix btsp[`i',2] = (_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
		}
		restore
	}
	
	cap drop btsp1 btsp2
	svmat btsp
	*Bootstrap p-values (one-sided)
	forvalues i = 1/2 {
		*Normal
		su btsp`i'
		local btsp_p`i'_`var' =  1-normal(-(`r(mean)'/`r(sd)'))
		*Percentile
		cap drop pc
		gen pc = btsp`i'>=0 if !missing(btsp`i')
		su pc
		local btsp_pc`i'_`var' = `r(mean)'
	}
}
********************************************************************************	
	
eststo clear
foreach var of varlist apr des_c eff_cost_loan pay_default  {

	qui su choose_commitment 
	local p_rate = `r(mean)'
		*ToT/TuT
	eststo : reg `var' i.t_prod ,  vce(cluster suc_x_dia)	 
	qui su `var' if e(sample) & t_prod==1
	local mn = `r(mean)'	
		*ToT
	local tot = (_b[4.t_prod])/(`p_rate')
	test (_b[4.t_prod])/(`p_rate')=0
	local p_tot = `r(p)'
		*TuT
	local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
	test (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')=0
	local p_tut = `r(p)'	
		*ToT-TuT
	local tot_tut = (_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
	test (_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate') = 0
	local sign_tot_tut = sign((_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate'))
		*p-value one-sided test - H_0 : tot-tut>=0
	local pvalue = 1 - ttail(`r(df_r)',`sign_tot_tut'*sqrt(`r(F)'))

	estadd scalar ContrMean = `mn'	
	estadd scalar tot = `tot'
	estadd scalar p_tot = `p_tot'	
	estadd scalar tut = `tut'	
	estadd scalar p_tut = `p_tut'
	estadd scalar tot_tut = `tot_tut'	
	estadd scalar pvalue = `pvalue'	
	estadd scalar btsp_p = `btsp_p1_`var''	
	estadd scalar btsp_pc = `btsp_pc1_`var''	
	estadd scalar pval_ri = `pval_ri1_`var''		

*-------------------------------------------------------------------------------
		*ToT/TuT
	eststo : reg `var' i.t_prod $C0 , 	vce(cluster suc_x_dia)
	qui su `var' if e(sample) & t_prod==1
	local mn = `r(mean)'
		*ToT
	local tot = (_b[4.t_prod])/(`p_rate')
	test (_b[4.t_prod])/(`p_rate')=0
	local p_tot = `r(p)'
		*TuT
	local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
	test (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')=0
	local p_tut = `r(p)'	
		*ToT-TuT
	local tot_tut = (_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
	test (_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate') = 0
	local sign_tot_tut = sign((_b[4.t_prod])/(`p_rate') - (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate'))
		*p-value one-sided test - H_0 : tot-tut>=0
	local pvalue = 1 - ttail(`r(df_r)',`sign_tot_tut'*sqrt(`r(F)'))

	estadd scalar ContrMean = `mn'	
	estadd scalar tot = `tot'
	estadd scalar p_tot = `p_tot'	
	estadd scalar tut = `tut'	
	estadd scalar p_tut = `p_tut'
	estadd scalar tot_tut = `tot_tut'	
	estadd scalar pvalue = `pvalue'	
	estadd scalar btsp_p = `btsp_p2_`var''	
	estadd scalar btsp_pc = `btsp_pc2_`var''		
	estadd scalar pval_ri = `pval_ri2_`var''	
	
	}


*Save results	
esttab using "$directorio/Tables/reg_results/tot_tut_reg.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean"  ///
		"tot ToT" "p_tot p-value" ///
		"tut TuT" "p_tut p-value" ///
		"tot_tut ToT-TuT" "pvalue F p-value" ///
		"btsp_p Bootstrap (normal) p-val" ///
		"btsp_pc Bootstrap (percentile) p-val" ///
		"pval_ri RI p-val" ///
		) keep(2.t_producto 4.t_producto) replace 
		
 	