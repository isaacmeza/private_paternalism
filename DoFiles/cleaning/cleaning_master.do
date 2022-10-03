
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: Sept. 26, 2022
* Modifications: Redefinition of main outcomes.
* Files used:     
		- 
* Files created:  

* Purpose: This do file cleans the survey data, generates relevant variables for analysis, and
meges it with the admin data. 

*******************************************************************************/
*/

clear all
set more off

use "$directorio/Raw/Base_Encuestas_Basales_24_05_2013.dta", clear

destring Enc, replace force

foreach var of varlist _all {
if "`var'"!="prenda"{
	bysort prenda: egen aux=max(`var')
	replace `var'=aux
	drop aux
	
	}
}

*Variable elimination
drop prod regalo pres_fundacion ledara AW AX question_miss question_miss1 question_miss2 Mprep

*How many people repeat the survey?
bysort prenda: gen aux = _N

*Encuestas repetidas 446+6+10: 462
*Personas que repitieron encuesta: 227

bysort prenda: keep if _n==1	
merge 1:1 prenda using "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", keep(2 3) nogen


*Impute/recover some answers of survey answers for 'Pignorante' who has several 'prendas'
foreach var of varlist  genero edad edo_civil trabajo educacion fam_pide f_estres ///
	pres_antes cont_fam plan_gasto c_trans t_llegar tempt{
	cap drop aux1
	bysort NombrePignorante: egen aux1=max(`var')
	replace `var'=aux1
	}

*Response elimination
replace trabajo = . if inlist(trabajo,6,7,8)
replace cont_fam = . if inlist(cont_fam,0)

*Variable creation

*Wizorise at 99th percentile
replace val_pren = prestamo_i if val_pren<prestamo_i & !missing(val_pren)
egen val_pren99 = pctile(val_pren) , p(99)
replace val_pren = val_pren99 if val_pren>val_pren99 & val_pren~=.
drop *99

*Imputation
replace val_pren = 1.5/0.7*prestamo_i if val_pren>1.5/0.7*prestamo_i & !missing(val_pren)
reg val_pren prestamo_i i.prenda_tipo i.razon, r
predict val_pren_pr
replace val_pren = val_pren_pr if missing(val_pren)
replace val_pren = prestamo_i if val_pren<prestamo_i & !missing(val_pren)
su val_pren_pr 
gen val_pren_std = (val_pren_pr-r(mean))/r(sd)

********************************************************************************
*							Measures of cost								   *
********************************************************************************

*Financial cost
	*survey fc
gen double fc_i_survey = .
	*Only fees and interest for recovered pawns
replace fc_i_survey = sum_int_c + sum_pay_fee_c if des_i_c==1
	*All payments + appraised value when default
replace fc_i_survey = sum_p_c + val_pren if def_i_c==1
	*Not ended at the end of observation period - only fees and interest
replace fc_i_survey = sum_int_c + sum_pay_fee_c if def_i_c==0 & des_i_c==0	

gen log_fc_i_survey = log(1+fc_i_survey)
label var fc_i_survey "Financial cost (subjective value)"

gen double apr_i_survey  = .
replace apr_i_survey = (1 + (fc_i_survey/prestamo_i)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_i_c==1
replace apr_i_survey = (1 + (fc_i_survey/prestamo_i)/dias_al_default)^dias_al_default - 1  if def_i_c==1
replace apr_i_survey = (1 + (fc_i_survey/prestamo_i)/dias_ultimo_mov)^dias_ultimo_mov - 1  if def_i_c==0 & des_i_c==0

***************************************

*APR + tc
	*travel cost
su c_trans
replace c_trans = `r(mean)' if missing(c_trans)
gen trans_cost = (c_trans + 62.33)*num_v	

gen double fc_i_tc = .
	*Only fees and interest for recovered pawns
replace fc_i_tc = sum_int_c + sum_pay_fee_c + trans_cost if des_i_c==1
	*All payments + appraised value when default
replace fc_i_tc = sum_p_c + prestamo_i/(0.7) + trans_cost if def_i_c==1
	*Not ended at the end of observation period - only fees and interest
replace fc_i_tc = sum_int_c + sum_pay_fee_c + trans_cost if def_i_c==0 & des_i_c==0	

gen double apr_i_tc  = .
replace apr_i_tc = (1 + (fc_i_tc/prestamo_i)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_i_c==1
replace apr_i_tc = (1 + (fc_i_tc/prestamo_i)/dias_al_default)^dias_al_default - 1  if def_i_c==1
replace apr_i_tc = (1 + (fc_i_tc/prestamo_i)/dias_ultimo_mov)^dias_ultimo_mov - 1  if def_i_c==0 & des_i_c==0

***************************************

*APR subjective + tc
gen double fc_i_survey_tc = .
	*Only fees and interest for recovered pawns
replace fc_i_survey_tc = sum_int_c + sum_pay_fee_c + trans_cost if des_i_c==1
	*All payments + appraised value when default
replace fc_i_survey_tc = sum_p_c + val_pren + trans_cost if def_i_c==1
	*Not ended at the end of observation period - only fees and interest
replace fc_i_survey_tc = sum_int_c + sum_pay_fee_c + trans_cost if def_i_c==0 & des_i_c==0	

gen double apr_i_survey_tc  = .
replace apr_i_survey_tc = (1 + (fc_i_survey_tc/prestamo_i)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_i_c==1
replace apr_i_survey_tc = (1 + (fc_i_survey_tc/prestamo_i)/dias_al_default)^dias_al_default - 1  if def_i_c==1
replace apr_i_survey_tc = (1 + (fc_i_survey_tc/prestamo_i)/dias_ultimo_mov)^dias_ultimo_mov - 1  if def_i_c==0 & des_i_c==0

***************************************

*APR fully adjusted (subj + tc - int)
gen double fc_i_fa = .
	*Only fees and interest for recovered pawns
replace fc_i_fa = sum_pay_fee_c + trans_cost if des_i_c==1
	*All payments + appraised value when default
replace fc_i_fa = sum_p_c + val_pren + trans_cost - sum_int_c if def_i_c==1
	*Not ended at the end of observation period - only fees and interest
replace fc_i_fa = sum_pay_fee_c + trans_cost if def_i_c==0 & des_i_c==0	

gen double apr_i_fa  = .
replace apr_i_fa = (1 + (fc_i_fa/prestamo_i)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_i_c==1
replace apr_i_fa = (1 + (fc_i_fa/prestamo_i)/dias_al_default)^dias_al_default - 1  if def_i_c==1
replace apr_i_fa = (1 + (fc_i_fa/prestamo_i)/dias_ultimo_mov)^dias_ultimo_mov - 1  if def_i_c==0 & des_i_c==0

********************************************************************************

gen masqueprepa=(educacion>=3) if educacion!=.
gen estresado_seguido=(f_estres<3) if f_estres!=.
gen log_val_pren = log(val_pren)
gen plan_gasto_bin = (plan_gasto>1) if !missing(plan_gasto)

gen pb=(t_consis1==0 & t_consis2==1) if t_consis2!=. & t_consis1!=.
gen fb=(t_consis1==1 & t_consis2==0) if t_consis2!=. & t_consis1!=.

egen faltas = rowtotal(renta comida medicina luz gas telefono agua) 
egen report = rownonmiss(renta comida medicina luz gas telefono agua) 
replace faltas = faltas/report

gen hace_presupuesto=(plan_gasto==2) if plan_gasto!=.
gen tentado=(tempt>=2) if tempt!=.
		 
sum c_trans, d
gen low_cost=(c_trans<=r(p50)) if c_trans!=.
sum t_llegar, d
gen low_time=(t_llegar<=r(p50)) if t_llegar!=.


*Aux Dummies (Fixed effects)
tab num_arms, gen(num_arms_d)
tab visit_number, gen(visit_number_d)

foreach var of varlist dow suc  {
	tab `var', gen(dummy_`var')
	}

drop num_arms_d1 num_arms_d2 visit_number_d1

*Overconfidence
	*Cross-validation LASSO
cvlasso des_i_c prenda_tipo val_pren prestamo_i genero edad educacion pres_antes ///
	plan_gasto ahorros cta_tanda tent rec_cel faltas , lopt seed(823) 
*lopt = the lambda that minimizes MSPE.
local lambda_opt=e(lopt)
*Variable selection
lasso2 des_i_c prenda_tipo val_pren prestamo_i genero edad educacion pres_antes ///
	plan_gasto ahorros cta_tanda tent rec_cel faltas , lambda( `lambda_opt'  ) 
*Variable selection
local vrs=e(selected)
local regressors  `regressors' `vrs'
logit des_i_c `regressors'
predict pr_prob
replace pr_prob = pr_prob*100
*Overconfident
gen OC = (pr_recup>pr_prob) if (!missing(pr_recup) & !missing(pr_prob))
gen cont_OC = pr_recup-pr_prob if (!missing(pr_recup) & !missing(pr_prob))

compress

save "$directorio/_aux/preMaster.dta", replace	

*Define main outcomes 
gen des_c = des_i_c
gen def_c = def_i_c
gen fc_admin = fc_i_admin
gen apr = apr_i
gen prestamo = prestamo_i

gen fc_survey = fc_i_survey
gen apr_survey = apr_i_survey

gen fc_tc = fc_i_tc
gen apr_tc = apr_i_tc

gen fc_survey_tc = fc_i_survey_tc
gen apr_survey_tc = apr_i_survey_tc

gen fc_fa = fc_i_fa
gen apr_fa = apr_i_fa

*Wizorise at 99th percentile
foreach var of varlist apr_survey apr_survey_tc apr_fa {
	egen `var'99 = pctile(`var') , p(99)
	replace `var' = `var'99 if `var'>`var'99 & `var'~=.
	drop *99
}


*Keep only first visit
keep if visit_number==1

save "$directorio/DB/Master.dta", replace	
export delimited using "$directorio/DB/Master.csv", replace quote nolabel
