/*
Balance table for those who answer and not answer the survey
*/

clear all
set more off

********************************************************************************
	
*SURVEY DATA (BASAL)

use "$directorio/DB/master.dta", clear

*Response survey dummy
gen response = !missing(f_encuesta) if !missing(t_prod)

*by response
drop if missing(t_prod)
orth_out prestamo monday num_empenio , by(response) overall count se  vce(cluster suc_x_dia) pcompare ///
	 bdec(2) stars
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\balance_response.xlsx", sheet("basal") modify

reg response i.suc , r
	test 3.suc==5.suc==42.suc==78.suc==80.suc==104.suc
	
	
********************************************************************************

*SURVEY DATA (EXIT)

import excel "$directorio\Raw\EncuestasSatisfaccion.xlsx", sheet("Hoja1") firstrow clear
drop producto
rename Boleta prenda
duplicates drop prenda, force

merge 1:m prenda using "$directorio/DB/master.dta", keep(2 3)

*Response survey dummy
gen response = (_merge==3)

*by response
drop if missing(t_prod)
orth_out prestamo monday num_empenio , by(response) overall count se  vce(cluster suc_x_dia) pcompare ///
	 bdec(2) stars
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\balance_response.xlsx", sheet("exit") modify

reg response i.suc , r cluster(suc_x_dia)
	test 3.suc==5.suc==42.suc==78.suc==80.suc==104.suc
	
