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

save  "${directorio}\DB\base_expansion.dta", replace
