
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: January. 15, 2023
* Modifications: Dataset with only first visit sample
	- Simplify dofile, remove soft arms and include survey response rate per question
* Files used:     
		- 
* Files created:  

* Purpose: Summary statistics - balance table & attrition table

*******************************************************************************/
*/

clear all
set more off


********************************************************************************

*Master data
use "$directorio/DB/Master.dta", clear

* Number of distinct suc-dia by treatment arms
by t_prod suc_x_dia, sort: gen nvals = _n == 1 
by t_prod: replace nvals = sum(nvals)
by t_prod: replace nvals = nvals[_N] 

drop if missing(t_prod)

**************************************SS ADMIN**********************************

orth_out prestamo weekday if inlist(t_prod,1,2,4) , by(t_prod) overall count se  vce(cluster suc_x_dia) bdec(2) 

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify	
qui putexcel B2=matrix(r(matrix)) 

qui putexcel set "$directorio\Tables\consort.xlsx", sheet("exp_arms") modify	
*Count number of obs
local j = 1
foreach t in 1 2 4  {
	count if  t_prod==`t' 
	local obs = `r(N)'
	local Col=substr(c(ALPHA),2*`j'+1,1)	
	qui putexcel `Col'16=matrix(`obs')  	
	local j = `j'+1
	}

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify	
	
local i = 2	
foreach var of varlist prestamo weekday  {
	qui reg `var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val')  
	local i = `i'+2
	}
	
******************* Balance conditional on survey subsample
gen sample_cov = !missing(f_encuesta)

orth_out prestamo weekday if inlist(t_prod,1,2,4) & sample_cov==1, by(t_prod) overall count se  vce(cluster suc_x_dia) bdec(2) 

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_admin_survey") modify	
qui putexcel B2=matrix(r(matrix)) 

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_admin_survey") modify	
	
local i = 2	
foreach var of varlist prestamo weekday  {
	qui reg `var' ibn.t_prod if inlist(t_prod,1,2,4) & sample_cov==1, nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val')  
	local i = `i'+2
	}	
	
	
	
*********************************Conditional on pawning*************************

orth_out val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprepa ///
	if inlist(t_prod,1,2,4), by(t_prod) overall se count vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify	
qui putexcel B2=matrix(r(matrix))  

* Response rate per question
foreach var of varlist val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprepa {
	gen rr_`var' = !missing(`var')
}

replace rr_pb = 0 if missing(pb) & !missing(fb) 
orth_out rr_val_pren_orig rr_faltas rr_pb rr_hace_presupuesto rr_pr_recup rr_pres_antes rr_edad rr_genero rr_masqueprepa ///
	if inlist(t_prod,1,2,4), by(t_prod) overall se count vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS.xlsx", sheet("survey_response_rate") modify	
qui putexcel B2=matrix(r(matrix))  


*Count number of surveys
local j = 1
foreach t in 1 2 4 {
	qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify	
	count if !missing(f_encuesta) & t_prod==`t' 
	local obs = `r(N)'
	local Col = substr(c(ALPHA),2*`j'+1,1)
	qui putexcel `Col'23=matrix(`obs')  
	qui putexcel set "$directorio\Tables\consort.xlsx", sheet("exp_arms") modify		
	qui putexcel `Col'17=matrix(`obs')  	
	local j = `j'+1
	}

	*F-tests
local i = 2	
foreach var of varlist val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprep {
	qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify	
	qui reg `var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val') 
	
	*Response rate per question
	qui putexcel set "$directorio\Tables\SS.xlsx", sheet("survey_response_rate") modify	
	qui reg rr_`var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val') 
	local i = `i'+2
	}
	
qui putexcel set "$directorio\Tables\SS.xlsx", sheet("survey_response_rate") modify		
egen answered = rownonmiss(val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprepa)
tab answered if inlist(t_prod,1,2,4) & sample_cov==1, matcell(tab_ans)
qui putexcel O2=matrix(tab_ans)  
	
**************************************EXP ARMS**********************************
preserve
*Dates of experiment
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2fv.dta", clear

*Only empenios
keep if !missing(producto)
keep if clave_movimiento == 4

*Get min/max dates of the experiment
collapse (min) min_fecha = fecha_inicial  (max) max_fecha = fecha_inicial, by(suc)

*Extended time line
merge 1:1 suc using "$directorio/_aux/time_line_aux.dta", nogen keepusing(min_fecha_suc max_fecha_suc)

gsort -max_fecha -max_fecha_suc
keep if _n==1

mkmat min_fecha max_fecha min_fecha_suc max_fecha_suc, matrix(timeline) 
qui putexcel set  "$directorio\Tables\consort.xlsx", sheet("exp_arms") modify	
qui putexcel B23=matrix(timeline) 

*Dates of observational data
use  "${directorio}\DB\base_expansion.dta", clear
keep fechaaltadelprestamo
su fechaaltadelprestamo
qui putexcel set  "$directorio\Tables\consort.xlsx", sheet("exp_arms") modify	
qui putexcel F23=`r(min)'
qui putexcel G23=`r(max)'
restore

orth_out nvals if inlist(t_prod,1,2,4), by(t_prod)  bdec(2) 	
qui putexcel set  "$directorio\Tables\consort.xlsx", sheet("exp_arms") modify	
qui putexcel B15=matrix(r(matrix)) 

**************************************ATTRITION*********************************
	
orth_out num_empenio if inlist(t_prod,1,2,4), by(t_prod) overall count se  vce(cluster suc_x_dia) bdec(2) 	

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_att") modify	
qui putexcel B2=matrix(r(matrix)) 
	
local i = 2	
foreach var of varlist num_empenio  {
	qui reg `var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val')  
	local i = `i'+2
	}

	
********************************************************************************
	
*SURVEY DATA (ENTRY) 
import excel "$directorio\Raw\Muestra Aleatoria en Excel con nombres de sucursales.xlsx", ///
	sheet("Muestra Aleatoria2") cellrange(A2:G93) firstrow clear
	
reshape long t_prod, i(fecha) j(sucursal)
rename fecha f_encuesta

tempfile randomization
save `randomization'

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

bysort prenda: keep if _n==1
merge m:1 sucursal f_encuesta using `randomization', nogen keep(1 3)
merge 1:1 prenda using "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta"
keep if visit_number==1 | visit_number==.

*Treatment for non-takers
replace t_producto = t_prod if _merge==1
replace t_producto = 6 if f_encuesta<date("9/6/2012","MDY")
drop t_prod

*Branch-day cluster
replace fecha_inicial = f_encuesta if _merge==1
replace suc = sucursal if _merge==1
drop suc_x_dia
egen suc_x_dia = group(fecha_inicial suc)

*Response survey dummy
gen response = !missing(f_encuesta) 

*Take-up treatment
gen takeup = (_merge==3) if inlist(_merge,1,3)

* Drop irrelevant observations  (important for correct # obs count)
drop if missing(t_prod)


**************************************ATTRITION*********************************

orth_out takeup if inlist(t_prod,1,2,4), by(t_prod) bdec(2) 
qui putexcel set  "$directorio\Tables\consort.xlsx", sheet("exp_arms") modify	
qui putexcel B18=matrix(r(matrix))  	

orth_out takeup response ///
	if inlist(_merge,1,2,3) & inlist(t_prod,1,2,4), by(t_prod) overall se vce(cluster suc_x_dia) ///
	bdec(2) 
qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_att") modify	
qui putexcel B8=matrix(r(matrix))  

	*F-tests
local i = 8	
foreach var of varlist takeup response {
	qui reg `var' ibn.t_prod if inlist(_merge,1,2,3) & inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val')  
	local i = `i'+2
	} 
	
	
