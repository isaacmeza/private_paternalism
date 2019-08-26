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

*bysort prenda: keep if _n==1
	
*merge 1:1 prenda using "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", keep(2 3) nogen

merge m:1 prenda using "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", keep(2 3) nogen


*Impute/recover some answers of survey answers for 'Pignorante' who has several 'prendas'
foreach var of varlist  genero edad edo_civil trabajo educacion fam_pide f_estres ///
	pres_antes cont_fam plan_gasto c_trans t_llegar tempt{
	cap drop aux1
	bysort NombrePignorante: egen aux1=max(`var')
	replace `var'=aux1
	}


*Variable creation
gen masqueprepa=(educacion>=3) if educacion!=.
gen estresado_seguido=(f_estres<3) if f_estres!=.
gen log_val_pren = log(val_pren)

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


*save "$directorio/DB/Master.dta", replace	
save "$directorio/DB/Master_with_duplicates.dta", replace
