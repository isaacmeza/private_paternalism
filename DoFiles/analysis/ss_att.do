
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

* Purpose: Summary statistics - attrition table 

*******************************************************************************/
*/

use "$directorio/_aux/num_pawns_suc_dia.dta", clear
egen suc_x_dia = group(suc fecha_inicial) 	

foreach var of varlist num_pawns num_borrowers {
	su `var' if t_prod==4, d
	replace `var' = . if t_prod==4 & `var'>`r(p99)'
}

**************************************ATTRITION*********************************

local i = 2	
qui putexcel set  "$directorio\Tables\SS_att.xlsx", sheet("SS_att") modify	

foreach var of varlist num_pawns num_borrowers {
	
	orth_out `var' if inlist(t_prod,1,2,4), by(t_prod) overall count se  vce(cluster suc) bdec(2) 	
	qui putexcel B`i'=matrix(r(matrix)) 
	
	qui reg `var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val')  
	local i = `i'+2

	qreg `var' i.t_prod if inlist(t_prod,1,2,4), q(0.5) 
	qui putexcel B`i'=matrix(_b[_cons]) 
	qui putexcel C`i'=matrix(_b[_cons]+_b[2.t_prod]) 
	qui putexcel D`i'=matrix(_b[_cons]+_b[4.t_prod]) 
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val') 
	local i = `i'+1
}

orth_out num_pawns if inlist(t_prod,1,2,4), by(t_prod) count
qui putexcel B17=matrix(r(matrix)) 

gen arm = t_prod
replace arm = 2.5 if t_prod==2
stripplot num_pawns if inlist(t_prod,1,2,4), cumul cumprob box iqr centre over(arm) refline vertical xsize(3) xlabel(1 "Control" 2.5 "Forced Commitment" 4 "Choice commitment") ytitle("Number of pawns") xtitle("")
graph export "$directorio/Figuras/box_plot_num_pawns.pdf", replace

stripplot num_borrowers if inlist(t_prod,1,2,4), cumul cumprob box iqr centre over(arm) refline vertical xsize(3) xlabel(1 "Control" 2.5 "Forced Commitment" 4 "Choice commitment") ytitle("Number of borrowers") xtitle("")
graph export "$directorio/Figuras/box_plot_num_borrowers.pdf", replace


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

orth_out takeup response ///
	if inlist(_merge,1,2,3) & inlist(t_prod,1,2,4), by(t_prod) overall se vce(cluster suc_x_dia) ///
	bdec(2) 
qui putexcel set "$directorio\Tables\SS_att.xlsx", sheet("SS_att") modify	
qui putexcel B10=matrix(r(matrix))  

	*F-tests
local i = 10	
foreach var of varlist takeup response {
	qui reg `var' ibn.t_prod if inlist(_merge,1,2,3) & inlist(t_prod,1,2,4), nocons r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val')  
	local i = `i'+2
	} 
	
	
*Correct # of observations
use "$directorio/DB/Master.dta", clear

count if t_prod==1
qui putexcel B14=matrix(`r(N)') 

count if t_prod==2
qui putexcel C14=matrix(`r(N)') 

count if t_prod==4
qui putexcel D14=matrix(`r(N)') 

