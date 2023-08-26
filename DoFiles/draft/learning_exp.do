
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	November. 6, 2021 
* Last date of modification: July. 04, 2023 
* Modifications: - Modify regression to have pure randomization/experimental analysis
	- Learning by not doing in reg format
* Files used:     
		- 
* Files created:  

* Purpose: Learning regressions in the experiment

*******************************************************************************/
*/

use "$directorio/_aux/preMaster.dta", clear
keep if inlist(t_prod,1,2,4)
duplicates drop NombrePignorante fecha_inicial suc prod t_prod, force

*br NombrePignorante fecha_inicial suc prod t_prod visit_number
*Complete NA's
sort NombrePignorante fecha_inicial prod
by NombrePignorante fecha_inicial : replace prod = prod[_n-1] if missing(prod) & prod[_n-1]!=.
by NombrePignorante fecha_inicial : replace t_prod = t_prod[_n-1] if missing(t_prod) & t_prod[_n-1]!=.
duplicates drop NombrePignorante fecha_inicial suc prod t_prod, force

br  NombrePignorante fecha_inicial suc prod t_prod
*Drop "contaminated" treatments
duplicates tag  NombrePignorante fecha_inicial , gen(tg)
duplicates tag  NombrePignorante fecha_inicial suc, gen(tg1)

*different branches (different treatment assignment)
gen difbr = tg==1 & tg1==0
by NombrePignorante : egen estos1 = max(difbr)
drop if estos1==1

keep if inlist(visit_number,1,2)
sort NombrePignorante fecha_inicial
*Identify individuals with multiple contracts the first time
gen aux_count1 = (visit_number==1)
by NombrePignorante : egen multiple_first = sum(aux_count1)
bysort NombrePignorante fecha_inicial t_prod multiple_first : gen obs_n1 = _n

*Identify individuals with multiple visit the second time
gen aux_count2 = (visit_number==2)
by NombrePignorante : egen multiple_second = sum(aux_count2)

drop if multiple_second==2 | obs_n1==2


sort NombrePignorante fecha_inicial
*Identify subsequent contract (Hard commitment)
by NombrePignorante : gen next_t = prod[_n+1] if visit_number==1 & visit_number[_n+1]==2
by NombrePignorante : gen t2_prod = t_prod[_n+1] if visit_number==1 & visit_number[_n+1]==2

*Identify periods where individual had option to choose next period
by NombrePignorante : gen option_choose = inlist(t2_prod,4,5) if !missing(t2_prod)
by NombrePignorante : gen option_choose_fee = inlist(t2_prod,4) if !missing(t2_prod)
by NombrePignorante : gen option_choose_promise = inlist(t2_prod,5) if !missing(t2_prod)

*Identify what they chose (conditional on having experienced treatment)
by NombrePignorante : gen choose_nsq_exp = inlist(next_t,5,7) if option_choose==1
by NombrePignorante : gen choose_nsq_fee_exp = inlist(next_t,5) if option_choose_fee==1
by NombrePignorante : gen choose_nsq_promise_exp = inlist(next_t,7) if option_choose_promise==1

*Identify what they chose next (=0 if either does not chose or does not have subsequent treatment)
by NombrePignorante : gen choose_nsq = inlist(next_t,5,7) 
by NombrePignorante : gen choose_nsq_fee = inlist(next_t,5) 
by NombrePignorante : gen choose_nsq_promise = inlist(next_t,7) 



********************************************************
*			      LEARNING REGRESSIONS				   *
********************************************************

eststo clear
eststo : reg choose_nsq_fee_exp i.t_prod if inlist(t_prod,1,2,4) & visit_number==1, vce(cluster suc_x_dia)
su choose_nsq_fee_exp if e(sample) 
estadd scalar DepVarMean = `r(mean)'

eststo : reg choose_nsq_fee i.t_prod if inlist(t_prod,1,2,4) & visit_number==1, vce(cluster suc_x_dia)
su choose_nsq_fee if e(sample) 
estadd scalar DepVarMean = `r(mean)'

	*Save results	
esttab using "$directorio/Tables/reg_results/learning_exp.csv", se r2 ${star} b(a2) scalars("DepVarMean DepVarMean") keep(2.t_producto 4.t_producto) replace 