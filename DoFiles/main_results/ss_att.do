/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: January. 26, 2022
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Summary statistics - balance table & attrition table

*******************************************************************************/
*/

clear all
set more off


********************************************************************************

*ADMIN DATA 
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", clear
tab producto	
append using "$directorio/_aux/pre_experiment_admin.dta"
replace t_prod = 6 if fecha_inicial<date("06/09/2012","DMY")  

cap drop suc_x_dia 
egen suc_x_dia = group(fecha_inicial suc)

* Number of distinct suc-dia by treatment arms
by t_prod suc_x_dia, sort: gen nvals = _n == 1 
by t_prod: replace nvals = sum(nvals)
by t_prod: replace nvals = nvals[_N] 

*Re-weight pre-experiment by number of relative days
foreach var of varlist  monday num_empenio {
	replace `var' = `var'*6*.0515971 if suc == 3 & t_prod==6 & !missing(`var')
	replace `var' = `var'*6*.0540541 if suc == 5 & t_prod==6 & !missing(`var')
	replace `var' = `var'*6*.2211302 if suc == 42 & t_prod==6 & !missing(`var')
	replace `var' = `var'*6*.2235872 if suc == 78 & t_prod==6 & !missing(`var')
	replace `var' = `var'*6*.2260442 if suc == 80 & t_prod==6 & !missing(`var')
	replace `var' = `var'*6*.2235872 if suc == 104 & t_prod==6 & !missing(`var')
	}


drop if missing(t_prod)

**************************************SS ADMIN**********************************

orth_out prestamo monday if inlist(t_prod,1,2,3,4,5,6) , by(t_prod) overall count se  vce(cluster suc_x_dia) bdec(2) 

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify	
qui putexcel B2=matrix(r(matrix)) 

qui putexcel set "$directorio\Tables\exp_arms.xlsx", sheet("exp_arms") modify	
*Count number of obs
foreach t in 1 2 3 4 5  {
	count if  t_prod==`t' 
	local obs = `r(N)'
	local Col=substr(c(ALPHA),2*`t'+1,1)	
	qui putexcel `Col'16=matrix(`obs')  	
	}

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify	
	
local i = 2	
foreach var of varlist prestamo monday  {
	qui reg `var' i.t_prod if inlist(t_prod,1,2,3,4,5), r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel J`i'=matrix(`p_val')  
	local i = `i'+2
	}
	
local i = 2		
*Test overall with pre-experiment
gen overall = inlist(t_prod,1,2,3,4,5) if !missing(t_prod)	
foreach var of varlist prestamo monday  {
	qui reg `var' i.overall, r cluster(suc_x_dia)
	test 1.overall
	local p_val = `r(p)'
	qui putexcel K`i'=matrix(`p_val')  
	local i = `i'+2
	}
	
**************************************ATTRITION*********************************
	
orth_out num_empenio nvals if inlist(t_prod,1,2,3,4,5,6), by(t_prod) overall count se  vce(cluster suc_x_dia) bdec(2) 	

qui putexcel set  "$directorio\Tables\SS.xlsx", sheet("SS_att") modify	
qui putexcel B2=matrix(r(matrix)) 
	
local i = 2	
foreach var of varlist num_empenio  {
	qui reg `var' i.t_prod if inlist(t_prod,1,2,3,4,5), r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel J`i'=matrix(`p_val')  
	local i = `i'+2
	}

local i = 2		
*Test overall with pre-experiment
foreach var of varlist num_empenio  {
	qui reg `var' i.overall, r cluster(suc)
	test 1.overall
	local p_val = `r(p)'
	qui putexcel K`i'=matrix(`p_val')  
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
merge 1:1 prenda using "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2"


*Impute/recover some answers of survey answers for 'Pignorante' who has several 'prendas'
foreach var of varlist  genero edad educacion pres_antes {
	cap drop aux1
	bysort NombrePignorante: egen aux1=max(`var') if _merge!=1
	replace `var'=aux1 if _merge!=1
	}
	
*Treatment for non-takers
replace t_producto = t_prod if _merge==1
replace t_producto = 6 if f_encuesta<date("9/6/2012","MDY")
drop t_prod

*Branch-day cluster
replace fecha_inicial = f_encuesta if _merge==1
replace suc = sucursal if _merge==1
drop suc_x_dia
egen suc_x_dia = group(fecha_inicial suc)

*Wizorise at 99th percentile
egen val_pren99 = pctile(val_pren) , p(99)
replace val_pren = val_pren99 if val_pren>val_pren99 & val_pren~=.
drop *99

*Imputation
replace val_pren = 3*prestamo if val_pren>3*prestamo & !missing(val_pren)
reg val_pren prestamo i.prenda_tipo i.razon, r
predict val_pren_pr
replace val_pren = val_pren_pr if missing(val_pren)

*Trimming
xtile perc = val_pren, nq(100)
replace val_pren=. if perc>=95

*High-School variable  
gen masqueprepa=(educacion>=3) if !missing(educacion)

*Response survey dummy
gen response = !missing(f_encuesta) if inlist(_merge,2,3)

*Take-up treatment
gen takeup = (_merge==3) if inlist(_merge,1,3)

* Drop irrelevant observations  (important for correct # obs count)
drop if missing(t_prod)


	
*********************************UN-CONDITIONAL sample**************************

orth_out genero edad  val_pren pres_antes pr_recup masqueprepa  ///
	if inlist(_merge,1,2,3) & inlist(t_prod,1,2,3,4,5,6), by(t_prod) overall se count vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_survey_uncond") modify	
qui putexcel B2=matrix(r(matrix))  

*Count number of surveys
foreach t in 1 2 3 4 5 6 {
	count if !missing(f_encuesta) & t_prod==`t' & inlist(_merge,1,2,3)
	local obs = `r(N)'
	local Col=substr(c(ALPHA),2*`t'+1,1)
	qui putexcel `Col'16=matrix(`obs')  
	qui putexcel set "$directorio\Tables\exp_arms.xlsx", sheet("exp_arms") modify		
	qui putexcel `Col'17=matrix(`obs')  	
	qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_survey_uncond") modify	
	}

	*F-tests
local i = 2	
foreach var of varlist genero edad  val_pren pres_antes pr_recup masqueprepa  {
	qui reg `var' i.t_prod if inlist(_merge,1,2,3) & inlist(t_prod,1,2,3,4,5), r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel J`i'=matrix(`p_val')  
	local i = `i'+2
	}
	
local i = 2		
*Test overall with pre-experiment
cap drop overall 
gen overall = inlist(t_prod,1,2,3,4,5) if !missing(t_prod) & inlist(_merge,1,2,3)
foreach var of varlist genero edad  val_pren pres_antes pr_recup masqueprepa  {
	qui reg `var' i.overall, r cluster(suc_x_dia)
	test 1.overall
	local p_val = `r(p)'
	qui putexcel K`i'=matrix(`p_val')  
	local i = `i'+2
	}	
**************************************ATTRITION*********************************

orth_out takeup response ///
	if inlist(_merge,1,2,3) & inlist(t_prod,1,2,3,4,5), by(t_prod) overall se vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_att") modify	
qui putexcel B8=matrix(r(matrix))  


	*F-tests
local i = 8	
foreach var of varlist takeup response {
	qui reg `var' i.t_prod if inlist(_merge,1,2,3) & inlist(t_prod,1,2,3,4,5), r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel J`i'=matrix(`p_val')  
	local i = `i'+2
	} 
	
	
**********************************CONDITIONAL on pawning************************

orth_out genero edad  val_pren pres_antes pr_recup masqueprepa  ///
	if inlist(_merge,2,3) & inlist(t_prod,1,2,3,4,5) , by(t_prod)  overall se count vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify
qui putexcel B2=matrix(r(matrix))  

*Count number of surveys
foreach t in 1 2 3 4 5 {
	count if !missing(f_encuesta) & t_prod==`t' & inlist(_merge,2,3)
	local obs = `r(N)'
	local Col=substr(c(ALPHA),2*`t'+1,1)
	qui putexcel `Col'16=matrix(`obs')  
	qui putexcel set "$directorio\Tables\exp_arms.xlsx", sheet("exp_arms") modify		
	qui putexcel `Col'18=matrix(`obs')  	
	qui putexcel set "$directorio\Tables\SS.xlsx", sheet("SS_survey_uncond") modify		
	}

	*F-tests
local i = 2	
foreach var of varlist genero edad  val_pren pres_antes pr_recup masqueprepa {
	qui reg `var' i.t_prod if inlist(_merge,2,3) & inlist(t_prod,1,2,3,4,5), r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel J`i'=matrix(`p_val')  
	local i = `i'+2
	}	
	
