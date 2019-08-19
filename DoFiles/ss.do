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


*Trimming	
xtile perc = prestamo, nq(100)
replace prestamo=. if perc>=99

orth_out prestamo monday num_empenio nvals, by(t_prod) count se  vce(cluster suc_x_dia) pcompare ///
	 bdec(2) stars
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify
	
local i = 2	
foreach var of varlist prestamo monday num_empenio {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify
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

orth_out genero edad  val_pren pres_antes pr_recup masqueprepa response, by(t_prod) se  vce(cluster suc_x_dia) ///
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
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify
	local i = `i'+2
	}
		
********************************************************************************

*SURVEY DATA (EXIT)

import excel "$directorio\Raw\EncuestasSatisfaccion.xlsx", sheet("Hoja1") firstrow clear

rename Boleta prenda
keep prenda contrataria satisfaccion sit_econ optaria_mensual si no
duplicates drop prenda, force

merge 1:1 prenda using "$directorio/DB/master.dta", keep(3) nogen

*Variables
gen satisfied_esquema_pago = (satisfaccion == 3)
gen sit_econ_mejor = (sit_econ == 1)


*Trimming
xtile perc = val_pren, nq(100)
replace val_pren=. if perc>=99
cap drop perc
xtile perc = prestamo, nq(100)
replace prestamo=. if perc>=99

orth_out contrataria satisfied_esquema_pago sit_econ_mejor optaria_mensual ///
	prestamo genero edad  val_pren pres_antes pr_recup masqueprepa , by(t_prod) count se  vce(cluster suc_x_dia) ///
	 bdec(2) stars pcompare
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_survey_exit") modify


local i = 2	
foreach var of varlist contrataria satisfied_esquema_pago sit_econ_mejor optaria_mensual ///
	prestamo genero edad  val_pren pres_antes pr_recup masqueprepa {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_survey_exit") modify
	local i = `i'+2
	}	
