
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: May. 23, 2024
* Modifications: Dataset with only first visit sample
	- Simplify dofile, remove soft arms and include survey response rate per question
	- Only survey variables
* Files used:     
		- 
* Files created:  

* Purpose: Summary statistics - balance table (survey variables)

*******************************************************************************/
*/

*Master data
use "$directorio/DB/Master.dta", clear


**************************************SS ADMIN**********************************
*********************************Conditional on pawning*************************

orth_out val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprepa ///
	if inlist(t_prod,1,2,4), by(t_prod) overall se count vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS_balance.xlsx", sheet("SS_survey") modify	
qui putexcel B2=matrix(r(matrix))  

* Response rate per question
foreach var of varlist val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprepa {
	gen rr_`var' = !missing(`var')
}

replace rr_pb = 0 if missing(pb) & !missing(fb) 
orth_out rr_val_pren_orig rr_faltas rr_pb rr_hace_presupuesto rr_pr_recup rr_pres_antes rr_edad rr_genero rr_masqueprepa ///
	if inlist(t_prod,1,2,4), by(t_prod) overall se count vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS_balance.xlsx", sheet("survey_response_rate") modify	
qui putexcel B2=matrix(r(matrix))  


*Count number of surveys
local j = 1
foreach t in 1 2 4 {
	qui putexcel set "$directorio\Tables\SS_balance.xlsx", sheet("SS_survey") modify	
	count if !missing(f_encuesta) & t_prod==`t' 
	local obs = `r(N)'
	local Col = substr(c(ALPHA),2*`j'+1,1)
	qui putexcel `Col'23=matrix(`obs')   	
	local j = `j'+1
	}

	*F-tests
local i = 2	
foreach var of varlist val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprep {
	qui putexcel set "$directorio\Tables\SS_balance.xlsx", sheet("SS_survey") modify	
	qui reg `var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val') 
	
	*Response rate per question
	qui putexcel set "$directorio\Tables\SS_balance.xlsx", sheet("survey_response_rate") modify	
	qui reg rr_`var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val') 
	local i = `i'+2
	}
	
qui putexcel set "$directorio\Tables\SS_balance.xlsx", sheet("survey_response_rate") modify		
egen answered = rownonmiss(val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprepa)
tab answered if inlist(t_prod,1,2,4) & sample_cov==1, matcell(tab_ans)
qui putexcel O2=matrix(tab_ans)  
	
