/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	November. 6, 2021 
* Last date of modification: November. 22, 2021 
* Modifications: Analysis of differential attrition & keep obs for pure randomization/experimental 
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
*Identify previous contract
gen comb_prod = prod
replace comb_prod = 4 if prod==6
replace comb_prod = 5 if prod==7

by NombrePignorante : gen previous = comb_prod[_n-1]

*Identify previous outcomes
by NombrePignorante : gen previous_def = def_c[_n-1]
by NombrePignorante : gen previous_des = des_c[_n-1]

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
	
cap drop coll
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
by NombrePignorante : gen num_prods = _N
keep NombrePignorante first num_prods
duplicates drop
tempfile tempfirst
save `tempfirst'
restore
merge m:1 NombrePignorante using `tempfirst'

sort NombrePignorante fecha_inicial
by NombrePignorante : gen comes_next = (num_prods>1) if _n==1 & !missing(num_prods)

putexcel set "$directorio/Tables/SS_learning.xlsx", sheet("SS_learning") modify	
orth_out comes_next if !missing(comes_next) & first!=3, by(first) vce(cluster suc_x_dia) bdec(3) se count prop pcompare
putexcel L31 = matrix(r(matrix)) 
reg comes_next i.first if first!=3, r
test 2.first==4.first==5.first==0

*coming next and having the option to choose	
sort NombrePignorante fecha_inicial
by NombrePignorante : egen cnc = max(kp) 
replace cnc = 0 if missing(cnc) 
by NombrePignorante : gen comes_next_choose = cnc if _n==1 
orth_out comes_next_choose if !missing(comes_next_choose) & first!=3, by(first) vce(cluster suc_x_dia) bdec(3) se count prop pcompare
putexcel L37 = matrix(r(matrix)) 
reg comes_next_choose i.first if first!=3, r
test 2.first==4.first==5.first==0

*Ever again takes a loan & chooses commitment (0 - if I didn't take a loan, 0 - if I took a loan and didn't choose commitment, only 1 - if took a loan and choose commtiment)
sort NombrePignorante fecha_inicial
by NombrePignorante : egen ecc = max(choose_nsq_fee) 
replace ecc = 0 if missing(ecc) & !missing(comes_next_choose)
by NombrePignorante : gen ever_chooses_commitment = ecc if _n==1 
*Outcome in first product
by NombrePignorante : gen fpd = def_c[1] 

********************************************************
*			      SUMMARY STATISTICS				   *
********************************************************

su choose_nsq_fee if previous==1
su choose_nsq_fee if previous==2
su choose_nsq_fee if previous==4
su choose_nsq_fee if previous==5

gen partition = .
replace partition = 1 if previous==1 & previous_def==0
replace partition = 2 if previous==2 & previous_def==0
replace partition = 3 if previous==4 & previous_def==0
replace partition = 4 if previous==5 & previous_def==0
replace partition = 5 if previous==1 & previous_def==1
replace partition = 6 if previous==2 & previous_def==1
replace partition = 7 if previous==4 & previous_def==1
replace partition = 8 if previous==5 & previous_def==1

*num_learning==1 & kp==1 ----> pure randomization/experimental
orth_out choose_nsq_fee if previous!=3 & kp==1, by(partition) vce(cluster suc_x_dia) bdec(3) se count prop pcompare
putexcel L5 = matrix(r(matrix)) 
orth_out choose_nsq_fee if previous!=3 &  kp==1, by(previous) vce(cluster suc_x_dia) bdec(3) se count prop pcompare
putexcel L10 = matrix(r(matrix)) 

*ever again chooses commitment
gen partition_1 = .
replace partition_1 = 1 if first==1 & fpd==0
replace partition_1 = 2 if first==2 & fpd==0
replace partition_1 = 3 if first==4 & fpd==0
replace partition_1 = 4 if first==5 & fpd==0
replace partition_1 = 5 if first==1 & fpd==1
replace partition_1 = 6 if first==2 & fpd==1
replace partition_1 = 7 if first==4 & fpd==1
replace partition_1 = 8 if first==5 & fpd==1

orth_out ever_chooses_commitment if first!=3, by(partition_1) vce(cluster suc_x_dia) bdec(3) se count prop pcompare
putexcel L46 = matrix(r(matrix)) 
orth_out ever_chooses_commitment if first!=3, by(first) vce(cluster suc_x_dia) bdec(3) se count prop pcompare
putexcel L51 = matrix(r(matrix)) 
		
********************************************************
*				LEARNING REGRESSIONS				   *
********************************************************

eststo clear


eststo : reghdfe choose_nsq_fee i.previous, absorb(NombrePignorante) vce(cluster suc_x_dia)
su choose_nsq if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo : reghdfe choose_nsq_fee i.previous##i.num_learning, absorb(NombrePignorante)  vce(cluster suc_x_dia)
eststo : reghdfe choose_nsq_fee i.previous##i.previous_def, absorb(NombrePignorante)  vce(cluster suc_x_dia)

*Coefficients 
putexcel M21 = (e(b)[1,2])
putexcel N21 = (e(b)[1,4])
putexcel O21 = (e(b)[1,5])
putexcel L23 = (e(b)[1,7])
putexcel M23 = (e(b)[1,7] + e(b)[1,2] + e(b)[1,11])
putexcel N23 = (e(b)[1,7] + e(b)[1,4] + e(b)[1,15])
putexcel O23 = (e(b)[1,7] + e(b)[1,5] + e(b)[1,17])
*Std Errors
putexcel M22 = (sqrt(e(V)[2,2]))
putexcel N22 = (sqrt(e(V)[4,4]))
putexcel O22 = (sqrt(e(V)[5,5]))
putexcel L24 = (sqrt(e(V)[7,7]))
putexcel M24 = (sqrt(e(V)[7,7] + e(V)[2,2] + e(V)[11,11] + 2*e(V)[7,2] + 2*e(V)[11,2] + 2*e(V)[11,7]))
putexcel N24 = (sqrt(e(V)[7,7] + e(V)[4,4] + e(V)[15,15] + 2*e(V)[7,4] + 2*e(V)[15,4] + 2*e(V)[15,7]))
putexcel O24 = (sqrt(e(V)[7,7] + e(V)[5,5] + e(V)[17,17] + 2*e(V)[7,5] + 2*e(V)[17,5] + 2*e(V)[17,7]))

reghdfe choose_nsq_fee i.previous, absorb(NombrePignorante)  vce(cluster suc_x_dia)

*Coefficients
putexcel M25 = (e(b)[1,2])
putexcel N25 = (e(b)[1,4])
putexcel O25 = (e(b)[1,5])
*Std Errors
putexcel M26 = (sqrt(e(V)[2,2]))
putexcel N26 = (sqrt(e(V)[4,4]))
putexcel O26 = (sqrt(e(V)[5,5]))

eststo : reghdfe choose_nsq_promise i.previous, absorb(NombrePignorante)  vce(cluster suc_x_dia)
su choose_nsq if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo : reghdfe choose_nsq_promise i.previous##i.num_learning, absorb(NombrePignorante)  vce(cluster suc_x_dia)
eststo : reghdfe choose_nsq_promise i.previous##i.previous_def, absorb(NombrePignorante)  vce(cluster suc_x_dia)

	*Save results	
esttab using "$directorio/Tables/reg_results/learning_exp.csv", se r2 ${star} b(a2) scalars("DepVarMean DepVarMean") replace 
