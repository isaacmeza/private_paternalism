
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: March. 21, 2021 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: 

*******************************************************************************/
*/

*import delimited "${directorio}\Raw\basedatos_seira.csv", clear
use "${directorio}\Raw\basedatos_seira.dta", clear

foreach var of varlist  sexo totaldeuda estadovta fechavta estadocva fechacva {
	replace `var' = "" if `var'=="NULL"
	}
	
label define sexo 1 "F" 0 "M"	
encode sexo, gen(sex) label(sexo)	
drop sexo
rename sex sexo

foreach var of varlist fecha* {
	split `var', p(" ")
	drop `var'
	drop `var'2
	gen `var' = date(`var'1, "YMD")
	drop `var'1
	}
format fecha* %td

destring totaldeuda, replace force
destring preciovta, replace force
replace preciovta = . if preciovta==0 
destring diferenciavta, replace force
replace diferenciavta = . if preciovta==. 

order idcliente idsucursal nrooperacion sexo fechanacimiento dircodpostal numoperaciones importecapital importeinteres valuacion porcvaluacion plazoprestamo importepercibido totaldeuda fechamov estadodetalle fechaaltadelultimodetalle estadovta fechavta preciovta diferenciavta estadocva fechacva idrubro linea idlinea estadocredito fechaaltadelprestamo fechavencimiento valortasafija tipooperacion
compress


*Cleaning of producto (linea)
drop idlinea
split linea, p("/")
keep if linea1=="Tradicional " | linea1=="Pagos Fijos "
label define pago_fijo 1 "Pagos Fijos " 0 "Tradicional "	
encode linea1, gen(pago_fijo) label(pago_fijo)
encode linea4, gen(periodicidad) 

*Filter valid dates
su fechaaltadelprestamo
drop if fechavencimiento>`r(max)'
drop if fechaaltadelultimodetalle>fechavencimiento

*Default
gen def_vta = !missing(fechavta) 
gen def_cva = !missing(fechacva)
gen def = def_cva
replace def = 1 if def_vta==1 & def_cva==0

*Not refrendums
gen nref = (tipooperacion=="ALT")


save  "${directorio}\DB\base_expansion.dta", replace
