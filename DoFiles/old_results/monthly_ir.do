set more off
*ADMIN DATA
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", clear

gen diferencia = fecha_movimiento - fecha_inicial
gen auxiliar = diferencia == 30
keep if auxiliar == 1

keep if clave_movimiento == 3

gen monthly_ir = 100*ImporteInters/pagos

gen month = mofd(date(string(month(fecha_movimiento))+"/"+string(year(fecha_movimiento)),"MY"))

format month %tm

estpost tabstat monthly_ir, by(month)
est store tabla
esttab tabla using "$directorio/Tables/monthly_ir.tex", ///
 cells("mean") nonote label noobs replace 
  
 