
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: October. 20, 2023
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Number per arms for consort figure

*******************************************************************************/
*/

*Master data
use "$directorio/DB/Master.dta", clear

* Number of distinct suc-dia by treatment arms
by t_prod suc_x_dia, sort: gen nvals = _n == 1 
by t_prod: replace nvals = sum(nvals)
by t_prod: replace nvals = nvals[_N] 

drop if missing(t_prod)

**************************************EXP ARMS**********************************

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

	
*********************************Conditional on pawning*************************


*Count number of surveys
local j = 1
foreach t in 1 2 4 {
	count if !missing(f_encuesta) & t_prod==`t' 
	local obs = `r(N)'
	local Col = substr(c(ALPHA),2*`j'+1,1) 
	qui putexcel set "$directorio\Tables\consort.xlsx", sheet("exp_arms") modify		
	qui putexcel `Col'17=matrix(`obs')  	
	local j = `j'+1
	}

	
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

	
	
