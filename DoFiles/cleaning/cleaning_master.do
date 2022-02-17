/*******************************************************************************
This do file cleans the survey data, generates relevant variables for analysis, and
meges it with the admin data.
*******************************************************************************/


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
egen val_pren99 = pctile(val_pren) , p(99)
replace val_pren = val_pren99 if val_pren>val_pren99 & val_pren~=.
drop *99

*Imputation
replace val_pren = 3*prestamo if val_pren>3*prestamo & !missing(val_pren)
reg val_pren prestamo i.prenda_tipo i.razon, r
predict val_pren_pr
replace val_pren = val_pren_pr if missing(val_pren)
su val_pren_pr 
gen val_pren_std = (val_pren_pr-r(mean))/r(sd)

********************************************************************************
*							Measures of cost								   *
********************************************************************************

*Financial cost
	*survey fc
gen fc_survey = sum_p_c
replace fc_survey = fc_survey + val_pren if des_c != 1
gen log_fc_survey = log(1+fc_survey)
label var fc_survey "Financial cost (subjective value)"


	*travel cost
su c_trans
replace c_trans = `r(mean)' if missing(c_trans)
gen trans_cost = (c_trans + 62.33)*num_p	


*APR subjective
gen double apr_survey = sum_porcp_c 
replace apr_survey = apr_survey + val_pren/prestamo if des_c != 1
	*annualize *solution to : apr/3 = x(1+x)^3/((1+x)^3-1)
replace apr_survey = apr_survey/3
gen double sqrt3 =  (2*apr_survey^3 + 9*apr_survey^2 + 3*sqrt(3)*sqrt(3*apr_survey^4 + 14*apr_survey^3 + 27*apr_survey^2) + 27*apr_survey)^(1/3)
replace apr_survey = sqrt3/(3*2^(1/3)) - (2^(1/3)*(-apr_survey^2 - 3*apr_survey))/(3*sqrt3) + (apr_survey - 3)/3
replace apr_survey = apr_survey*12*100
drop sqrt3
label var apr_survey "APR (subjective value)"

*APR + tc
gen double apr_tc = sum_porcp_c + trans_cost/prestamo
replace apr_tc = apr_tc + 1/0.7 if des_c != 1

	*annualize *solution to : apr/3 = x(1+x)^3/((1+x)^3-1)
replace apr_tc = apr_tc/3
gen double sqrt3 =  (2*apr_tc^3 + 9*apr_tc^2 + 3*sqrt(3)*sqrt(3*apr_tc^4 + 14*apr_tc^3 + 27*apr_tc^2) + 27*apr_tc)^(1/3)
replace apr_tc = sqrt3/(3*2^(1/3)) - (2^(1/3)*(-apr_tc^2 - 3*apr_tc))/(3*sqrt3) + (apr_tc - 3)/3
replace apr_tc = apr_tc*12*100
drop sqrt3
label var apr_tc "APR (appraised) + tc"

*APR subjective + tc
gen double apr_s_tc = sum_porcp_c + trans_cost/prestamo
replace apr_s_tc = apr_s_tc + val_pren/prestamo if des_c != 1

	*annualize *solution to : apr/3 = x(1+x)^3/((1+x)^3-1)
replace apr_s_tc = apr_s_tc/3
gen double sqrt3 =  (2*apr_s_tc^3 + 9*apr_s_tc^2 + 3*sqrt(3)*sqrt(3*apr_s_tc^4 + 14*apr_s_tc^3 + 27*apr_s_tc^2) + 27*apr_s_tc)^(1/3)
replace apr_s_tc = sqrt3/(3*2^(1/3)) - (2^(1/3)*(-apr_s_tc^2 - 3*apr_s_tc))/(3*sqrt3) + (apr_s_tc - 3)/3
replace apr_s_tc = apr_s_tc*12*100
drop sqrt3
label var apr_s_tc "APR (subjective) + tc"

*APR fully adjusted (subj + tc - int)
gen double apr_fa = sum_porcp_c + trans_cost/prestamo - sum_porc_int_c
replace apr_fa = apr_fa + val_pren/prestamo if des_c != 1

	*annualize *solution to : apr/3 = x(1+x)^3/((1+x)^3-1)
replace apr_fa = apr_fa/3
gen double sqrt3 =  (2*apr_fa^3 + 9*apr_fa^2 + 3*sqrt(3)*sqrt(3*apr_fa^4 + 14*apr_fa^3 + 27*apr_fa^2) + 27*apr_fa)^(1/3)
replace apr_fa = sqrt3/(3*2^(1/3)) - (2^(1/3)*(-apr_fa^2 - 3*apr_fa))/(3*sqrt3) + (apr_fa - 3)/3
replace apr_fa = apr_fa*12*100
drop sqrt3
label var apr_fa "APR (fully adjusted)"

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
tab num_arms_75, gen(num_arms_75_d)
tab visit_number_75, gen(visit_number_75_d)
foreach var of varlist dow suc /*prenda_tipo edo_civil choose_same trabajo*/  {
	tab `var', gen(dummy_`var')
	}
	*for grf
foreach var of varlist prenda_tipo edo_civil choose_same trabajo  {
	tab `var', gen(grf_dummy_`var')
	}	
drop num_arms_d1 num_arms_d2 visit_number_d1
drop num_arms_75_d1 num_arms_75_d2  visit_number_75_d1

*Overconfidence
	*Cross-validation LASSO
cvlasso des_c prenda_tipo val_pren prestamo genero edad educacion pres_antes ///
	plan_gasto ahorros cta_tanda tent rec_cel faltas , lopt seed(823) 
*lopt = the lambda that minimizes MSPE.
local lambda_opt=e(lopt)
*Variable selection
lasso2 des_c prenda_tipo val_pren prestamo genero edad educacion pres_antes ///
	plan_gasto ahorros cta_tanda tent rec_cel faltas , lambda( `lambda_opt'  ) 
*Variable selection
local vrs=e(selected)
local regressors  `regressors' `vrs'
logit des_c `regressors'
predict pr_prob
replace pr_prob = pr_prob*100
*Overconfident
gen OC = (pr_recup>pr_prob) if (!missing(pr_recup) & !missing(pr_prob))
gen cont_OC = pr_recup-pr_prob if (!missing(pr_recup) & !missing(pr_prob))


save "$directorio/DB/Master.dta", replace	
export delimited using "$directorio/DB/Master.csv", replace quote nolabel
