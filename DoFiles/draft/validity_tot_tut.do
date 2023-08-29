********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	August. 21, 2023
* Last date of modification: 
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  
* Purpose:  Huber & Mellace (2015) exclusion validity for TOT & TUT

*******************************************************************************/
*/

clear all
set maxvar 100000
do "$directorio/DoFiles/draft/tot_tut_noexclusion.do"
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

keep apr des_c def_c ref_c fc_admin  choose_commitment t_prod prod suc_x_dia 
replace fc_admin = -fc_admin
replace apr = -apr*100
replace des_c = des_c*100
replace def_c = 100-def_c*100
replace ref_c = 100-ref_c*100
 
********************************************************************************

gen touse = 1
*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4

gen ub_tut_fc = .
gen lb_tut_fc = .
gen ub_tot_fc = .
gen lb_tot_fc = .
 
gen ub_tut_fc_2 = .
gen lb_tut_fc_2 = .
gen ub_tot_fc_2 = .
gen lb_tot_fc_2 = .

gen pval_tot_fc_ = .
gen pval_tut_fc_ = .
gen pval_fc_ = .

su choose_commitment
local qq = `r(mean)'

tot_tut apr Z choose_commitment 
local tot= _b[ToT]
local tut = _b[TuT]
tot_tut_noexclusion apr Z, quantile(`qq') tot(`tot') tut(`tut')

*1. Estimate the vector of parameters θ in the original sample.
local ub_tut_validity = `r(ub_tut_validity)'
local lb_tut_validity = `r(lb_tut_validity)' 
local ub_tot_validity = `r(ub_tot_validity)'
local lb_tot_validity = `r(lb_tot_validity)'

*2. Draw B1 bootstrap samples of size n from the original sample.
local b_rep1 = 500
noi di " "
noi _dots 0, title(B1 bootstrap repetitions) reps(`b_rep1')
noi di " "
forvalues i = 1/`b_rep1' {
	qui {	
	preserve
	bsample , cluster(suc_x_dia)
	tot_tut apr Z choose_commitment 	
	restore
	local tot= _b[ToT]
	local tut = _b[TuT]
	tot_tut_noexclusion apr Z, quantile(`qq') tot(`tot') tut(`tut')
	*3. In each bootstrap sample, compute the fully recentered vector θ^f_b 
	replace ub_tut_fc = `r(ub_tut_validity)'-`ub_tut_validity' in `i'
	replace lb_tut_fc = `r(lb_tut_validity)'-`lb_tut_validity' in `i'
	replace ub_tot_fc = `r(ub_tot_validity)'-`ub_tot_validity' in `i'
	replace lb_tot_fc = `r(lb_tot_validity)'-`lb_tot_validity' in `i'
	}
	noi _dots `i' 0	
}

*4. Estimate the vector of p-values under full recentering
gen ub_tut_fc_1 = ub_tut_fc>`ub_tut_validity' if !missing(ub_tut_fc)
gen lb_tut_fc_1 = lb_tut_fc>`lb_tut_validity' if !missing(lb_tut_fc)
gen ub_tot_fc_1 = ub_tot_fc>`ub_tot_validity' if !missing(ub_tot_fc)
gen lb_tot_fc_1 = lb_tot_fc>`lb_tot_validity' if !missing(lb_tot_fc)

egen pval_ub_tut = mean(ub_tut_fc_1) if !missing(ub_tut_fc_1)
egen pval_lb_tut = mean(lb_tut_fc_1) if !missing(lb_tut_fc_1)
egen pval_ub_tot = mean(ub_tot_fc_1) if !missing(ub_tot_fc_1)
egen pval_lb_tot = mean(lb_tot_fc_1) if !missing(lb_tot_fc_1)


*5. Compute the minimum p-values under full recentering
gen min_pval_tot = min(pval_ub_tot, pval_lb_tot)
gen min_pval_tut = min(pval_ub_tut, pval_lb_tut)
gen min_pval = min(min_pval_tot, min_pval_tut)

*6. Draw B2 values from the distributions of θ^f_b 
local b_rep2 = 1000
gen drw = runiformint(1, `b_rep1') if _n<=`b_rep2'


noi di " "
noi _dots 0, title(B2 bootstrap repetitions) reps(`b_rep2')
noi di " "
forvalues j = 1/`b_rep2' {
	local b2 = drw[`j']
	replace ub_tut_fc_2 = ub_tut_fc>ub_tut_fc[`b2'] if !missing(ub_tut_fc)
	replace lb_tut_fc_2 = lb_tut_fc>lb_tut_fc[`b2'] if !missing(lb_tut_fc)
	replace ub_tot_fc_2 = ub_tot_fc>ub_tot_fc[`b2'] if !missing(ub_tot_fc)
	replace lb_tot_fc_2 = lb_tot_fc>lb_tot_fc[`b2'] if !missing(lb_tot_fc)
	
	cap drop pval_ub_tut pval_lb_tut pval_ub_tot pval_lb_tot
	egen pval_ub_tut = mean(ub_tut_fc_2) 
	egen pval_lb_tut = mean(lb_tut_fc_2) 
	egen pval_ub_tot = mean(ub_tot_fc_2) 
	egen pval_lb_tot = mean(lb_tot_fc_2) 
	
	*7. In each bootstrap sample, compute the minimum p-values of B.f
	replace pval_tot_fc_ = min(pval_ub_tot, pval_lb_tot)<=min_pval_tot[1] in `j'
	replace pval_tut_fc_ = min(pval_ub_tut, pval_lb_tut)<=min_pval_tut[1] in `j'
	replace pval_fc_ = min(min_pval_tot, min_pval_tut)<=min_pval[1] in `j'
	
	noi _dots `j' 0	
}

*8. Compute the p-values of the B.f tests by the share of bootstrapped minimum p-values that are smaller than the respective minimum p-value of the original sample
egen pval_tot_fc = mean(pval_tot_fc_) if _n<=`b_rep2'
egen pval_tut_fc = mean(pval_tut_fc_) if _n<=`b_rep2'
egen pval_fc = mean(pval_fc_) if _n<=`b_rep2'


