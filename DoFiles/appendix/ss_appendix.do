/*
Summary statistics and balance table 
*/

clear all
set more off


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


	
**********************************CONDITIONAL on pawning************************

orth_out genero edad  val_pren pres_antes pr_recup masqueprepa response ///
	if inlist(_merge,2,3) & inlist(t_prod,1,2,3,4,5) , by(t_prod)  overall se  vce(cluster suc_x_dia) ///
	bdec(2) 
	
qui putexcel set "$directorio\Tables\SS_appendix.xlsx", sheet("SS_survey") modify
qui putexcel B2=matrix(r(matrix))  

*Count number of surveys
forvalues t = 1/5 {
	count if !missing(f_encuesta) & t_prod==`t' & inlist(_merge,2,3)
	local obs = `r(N)'
	local Col=substr(c(ALPHA),2*`t'+1,1)
	qui putexcel set "$directorio\Tables\SS_appendix.xlsx", sheet("SS_survey") modify
	qui putexcel `Col'16=matrix(`obs')  
	}

	*F-tests
local i = 2	
foreach var of varlist genero edad  val_pren pres_antes pr_recup masqueprepa response {
	qui reg `var' i.t_prod if inlist(_merge,2,3) & inlist(t_prod,1,2,3,4,5), r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel set "$directorio\Tables\SS_appendix.xlsx", sheet("SS_survey") modify
	qui putexcel I`i'=matrix(`p_val')  
	local i = `i'+2
	}