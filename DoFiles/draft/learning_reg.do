
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	November. 6, 2021 
* Last date of modification: February. 28, 2022 
* Modifications: - Analysis of differential attrition & keep obs for pure randomization/experimental 
	- Learning by not doing in reg format
* Files used:     
		- 
* Files created:  

* Purpose: Learning regressions in the experiment

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
duplicates drop NombrePignorante fecha_inicial suc prod t_prod, force


*Complete NA's
sort NombrePignorante fecha_inicial prod
by NombrePignorante fecha_inicial : replace prod = prod[_n-1] if missing(prod) & prod[_n-1]!=.
by NombrePignorante fecha_inicial : replace t_prod = t_prod[_n-1] if missing(t_prod) & t_prod[_n-1]!=.
duplicates drop NombrePignorante fecha_inicial suc prod t_prod, force

*Drop "contaminated" treatments
duplicates tag  NombrePignorante fecha_inicial , gen(tg)
duplicates tag  NombrePignorante fecha_inicial suc, gen(tg1)

*contaminated with two treatments
by NombrePignorante : egen estos = max(tg)
drop if estos==2
*different branches
gen difbr = tg==1 & tg1==0
by NombrePignorante : egen estos1 = max(difbr)
drop if estos1==1
*when option to choose is available drop when they choose two different treatments with same outcomes
bysort NombrePignorante fecha_inicial : egen mn_def = mean(def_c) if tg==1
bysort NombrePignorante : gen twodif = mn_def!=0.5 if estos!=0
bysort NombrePignorante : egen estos2 = min(twodif)
drop if estos2==1

drop if estos!=0 & tg==1 & def_c==1


sort NombrePignorante fecha_inicial
*Identify previous contract (Hard commitment)
gen comb_prod = prod
replace comb_prod = . if prod==6
replace comb_prod = . if prod==7

gen pt_prod = t_prod


by NombrePignorante : gen previous = comb_prod[_n-1]
by NombrePignorante : gen prev_t_prod = pt_prod[_n-1]

*Identify previous outcomes
by NombrePignorante : gen previous_def = def_c[_n-1]
by NombrePignorante : gen previous_des = des_c[_n-1]

*Identify previous suc_x_dia
by NombrePignorante : gen prev_suc_x_dia = suc_x_dia[_n-1]

*Identify periods where individual had option to choose after experiencing
by NombrePignorante : gen option_choose = inlist(t_prod,4,5) if !missing(previous)
by NombrePignorante : gen option_choose_fee = inlist(t_prod,4) if !missing(previous)
by NombrePignorante : gen option_choose_promise = inlist(t_prod,5) if !missing(previous)
foreach var of varlist option_choose* {
	replace `var' = . if `var'==0
}

*Identify what they chose
by NombrePignorante : gen choose_nsq = inlist(prod,5,7) if option_choose==1
by NombrePignorante : gen choose_nsq_fee = inlist(prod,5) if option_choose_fee==1
by NombrePignorante : gen choose_nsq_promise = inlist(prod,7) if option_choose_promise==1


*Identify murky cases : murky cases are ones where we have many treatment status before the choice
cap drop num_pr_tr
sort NombrePignorante  fecha_inicial
*Number of previous treatments
by NombrePignorante : gen num_pr_tr = _n -1 if choose_nsq!=.
replace num_pr_tr = 3 if num_pr_tr>3 & !missing(num_pr_tr)
tab num_pr_tr
*Number of potential decisions to choose
gen ax = !missing(num_pr_tr)
by NombrePignorante : gen num_learning = sum(ax)
replace num_learning = num_pr_tr if missing(num_pr_tr)
replace num_learning = 3 if num_learning>3 & !missing(num_learning)
tab num_learning
	
*We look at the first time of learning, if treatment status in the previous (num_pr_tr) is unchanged we keep that obs
by NombrePignorante : egen min_numl = min(num_pr_tr)
cap drop kp
by NombrePignorante : gen kp = 1 if (choose_nsq!=. & (num_pr_tr==1  ///
		| (num_pr_tr==2 & num_pr_tr==min_numl & prod[_n-1]==prod[_n-2]) ///
		| (num_pr_tr==3 & num_pr_tr==min_numl & prod[_n-1]==prod[_n-2] & prod[_n-2]==prod[_n-3]) ///
		| (num_pr_tr==4 & num_pr_tr==min_numl & prod[_n-1]==prod[_n-2] & prod[_n-2]==prod[_n-3] & prod[_n-3]==prod[_n-4]) ///
		| (num_pr_tr==4 & num_pr_tr==min_numl & prod[_n-1]==prod[_n-2] & prod[_n-2]==prod[_n-3] & prod[_n-3]==prod[_n-4]  & prod[_n-4]==prod[_n-5]) ///
		))

*Differential Attrition
*coming next
sort NombrePignorante fecha_inicial
preserve
drop if missing(comb_prod)
by NombrePignorante : gen first = comb_prod[1]
by NombrePignorante : gen first_suc_x_dia = suc_x_dia[1]
by NombrePignorante : gen num_prods = _N
keep NombrePignorante first num_prods first_suc_x_dia
duplicates drop
tempfile tempfirst
save `tempfirst'
restore
merge m:1 NombrePignorante using `tempfirst'

sort NombrePignorante fecha_inicial
by NombrePignorante : gen comes_next = (num_prods>1) if _n==1 & !missing(num_prods)

*coming next and having the option to choose	
sort NombrePignorante fecha_inicial
by NombrePignorante : egen cnc = max(kp) 
replace cnc = 0 if missing(cnc) 
by NombrePignorante : gen comes_next_choose = cnc if _n==1 


*Differential attrition regression
eststo clear
eststo : reg comes_next i.first if first!=3, vce(cluster first_suc_x_dia)
su comes_next if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo : reg comes_next_choose i.first if first!=3, vce(cluster first_suc_x_dia)
su comes_next_choose if e(sample) 
estadd scalar DepVarMean = `r(mean)'
esttab using "$directorio/Tables/reg_results/differential_attrition.csv", se r2 ${star} b(a2)  scalars("DepVarMean DepVarMean") replace 


*Ever again takes a loan & chooses commitment (0 - if I didn't take a loan, 0 - if I took a loan and didn't choose commitment, only 1 - if took a loan and choose commtiment)
sort NombrePignorante fecha_inicial
by NombrePignorante : egen ecc = max(choose_nsq_fee) 
replace ecc = 0 if missing(ecc) & !missing(comes_next_choose)
by NombrePignorante : gen ever_chooses_commitment = ecc if _n==1 
*Outcome in first product
by NombrePignorante : gen fpd = def_c[1] 


********************************************************
*			      LEARNING REGRESSIONS				   *
********************************************************

eststo clear

eststo : reg choose_nsq_fee i.previous if previous!=3 & kp==1, vce(cluster prev_suc_x_dia)
su choose_nsq if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo : reg choose_nsq_fee i.previous##i.previous_def if previous!=3 & kp==1, vce(cluster prev_suc_x_dia)

	
eststo : reg ever_chooses_commitment i.first if first!=3, vce(cluster first_suc_x_dia)
su ever_chooses_commitment if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo : reg ever_chooses_commitment i.first##i.fpd if first!=3, vce(cluster first_suc_x_dia)

******

eststo : reg choose_nsq_fee i.previous $C0 if previous!=3 & kp==1, vce(cluster prev_suc_x_dia)
su choose_nsq if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo : reg choose_nsq_fee i.previous##i.previous_def $C0 if previous!=3 & kp==1, vce(cluster prev_suc_x_dia)

	
eststo : reg ever_chooses_commitment i.first $C0 if first!=3, vce(cluster first_suc_x_dia)
su ever_chooses_commitment if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo : reg ever_chooses_commitment i.first##i.fpd $C0 if first!=3, vce(cluster first_suc_x_dia)


	*Save results	
esttab using "$directorio/Tables/reg_results/learning_exp.csv", se r2 ${star} b(a2) scalars("DepVarMean DepVarMean") replace 
