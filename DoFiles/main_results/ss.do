/*
Summary statistics and balance table 
*/

clear all
set more off


********************************************************************************

*ADMIN DATA
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", clear
tab producto	

* Number of distinct suc-dia by treatment arms
by t_prod suc_x_dia, sort: gen nvals = _n == 1 
by t_prod: replace nvals = sum(nvals)
by t_prod: replace nvals = nvals[_N] 


drop if missing(t_prod)
orth_out prestamo monday num_empenio nvals, by(t_prod) overall count se  vce(cluster suc_x_dia) pcompare ///
	 bdec(2) stars
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify
	
local i = 2	
foreach var of varlist prestamo monday num_empenio {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel R`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify
	local i = `i'+2
	}

********************************************************************************
	
*SURVEY DATA (BASAL)

use "$directorio/DB/master.dta", clear
*Trimming
xtile perc = val_pren, nq(100)
replace val_pren=. if perc>=99

*Response survey dummy
gen response = !missing(genero)

*Reasons
label define reasons 0 "Lost Job" 1 "Sickness" 2 "Urgent Expense" 3 "No Urgent Expense"
label values razon reasons

preserve
drop if missing(razon)

bysort razon: gen razones = _N
gen total_obs = _N

gen propor = 100*razones/total_obs

graph hbar propor, over(razon) ///
 graphregion(color(white)) scheme(s2mono) ///
 ytitle("") ylabel(0 "0" 20 "20%" 40 "40%" 60 "60%" 80 "80%")
 
graph export "$directorio/Figuras/reasons_pawn.pdf", replace
restore

drop if missing(t_prod)
orth_out genero edad  val_pren pres_antes pr_recup masqueprepa response, by(t_prod) overall se  vce(cluster suc_x_dia) ///
	 bdec(2) stars pcompare
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify

*Count number of surveys

forvalues t = 1/5 {
	count if !missing(genero) & t_prod==`t'
	local obs = `r(N)'
	local Col=substr(c(ALPHA),2*`t'+1,1)
	qui putexcel `Col'16=matrix(`obs') using "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify
	}

local i = 2	
foreach var of varlist genero edad  val_pren pres_antes pr_recup masqueprepa response {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel R`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify
	local i = `i'+2
	}
	
*Complete responses

tab prenda_tipo, matcell(freq)
qui putexcel I3=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
	
local j = 9	
foreach var of varlist  pr_recup val_pren genero edad {
su `var'
qui putexcel I`j'=matrix(`r(mean)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel J`j'=matrix(`r(sd)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel K`j'=matrix(`r(N)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
local j = `j' + 2
}

tab edo_civil, matcell(freq)
qui putexcel I17=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab trabajo, matcell(freq)
qui putexcel I22=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab educacion, matcell(freq)
qui putexcel I29=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

su fam_pide
qui putexcel I35=matrix(`r(mean)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel J35=matrix(`r(sd)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel K35=matrix(`r(N)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab t_consis1, matcell(freq)
qui putexcel I37=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab f_estres, matcell(freq)
qui putexcel I40=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab razon, matcell(freq)
qui putexcel I45=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab r_estress, matcell(freq)
qui putexcel I50=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab s_fin_mes, matcell(freq)
qui putexcel I55=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

su pres_antes
qui putexcel I59=matrix(`r(mean)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel J59=matrix(`r(sd)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel K59=matrix(`r(N)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab cont_fam, matcell(freq)
qui putexcel I61=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

tab plan_gasto, matcell(freq)
qui putexcel I67=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

local j = 71	
foreach var of varlist  otra_prenda ahorros cta_tanda fam_comun c_trans t_llegar gasto_fam ahorro_fam {
su `var'
qui putexcel I`j'=matrix(`r(mean)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel J`j'=matrix(`r(sd)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel K`j'=matrix(`r(N)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
local j = `j' + 2
}

tab tempt, matcell(freq)
qui putexcel I87=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

local j = 92	
foreach var of varlist  renta comida medicina luz gas telefono agua {
su `var'
qui putexcel I`j'=matrix(`r(mean)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel J`j'=matrix(`r(sd)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel K`j'=matrix(`r(N)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
local j = `j' + 2
}

tab t_consis2, matcell(freq)
qui putexcel I100=matrix(freq) using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify

su rec_cel
qui putexcel I103=matrix(`r(mean)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel J103=matrix(`r(sd)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify
qui putexcel K103=matrix(`r(N)') using "$directorio\Tables\baseline_survey.xlsx", sheet("baseline_survey") modify


	
********************************************************************************

*SURVEY DATA (EXIT)

import excel "$directorio\Raw\EncuestasSatisfaccion.xlsx", sheet("Hoja1") firstrow clear

rename Boleta prenda
keep prenda contrataria satisfaccion sit_econ optaria_mensual si no
duplicates drop prenda, force

merge 1:m prenda using "$directorio/DB/master.dta", keep(3) nogen

*Variables
gen satisfied_esquema_pago = (satisfaccion == 3)
gen sit_econ_mejor = (sit_econ == 1)


*Trimming
xtile perc = val_pren, nq(100)
replace val_pren=. if perc>=99
cap drop perc
xtile perc = prestamo, nq(100)
replace prestamo=. if perc>=99

drop if missing(t_prod)
orth_out contrataria satisfied_esquema_pago sit_econ_mejor optaria_mensual ///
	prestamo genero edad  val_pren pres_antes pr_recup masqueprepa , by(t_prod) overall count se  vce(cluster suc_x_dia) ///
	 bdec(2) stars pcompare
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_survey_exit") modify


local i = 2	
foreach var of varlist contrataria satisfied_esquema_pago sit_econ_mejor optaria_mensual ///
	prestamo genero edad  val_pren pres_antes pr_recup masqueprepa {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel R`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_survey_exit") modify
	local i = `i'+2
	}	
