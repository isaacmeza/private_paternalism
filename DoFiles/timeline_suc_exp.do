*Timeline of the experiment

use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", clear

*Only empenios
keep if !missing(producto)
keep if clave_movimiento == 4


*Get min/max dates of the experiment
collapse (min) min_fecha = fecha_inicial  (max) max_fecha = fecha_inicial, by(suc)

gen id = _n
twoway pcarrow id min_fecha id max_fecha, lwidth(thick) msize(huge)  barbsize(medlarge) ///
	scheme(s2mono) graphregion(color(white)) ytitle("Branch") ///
	ylabel(1 "Calzada" 2 "Congreso" 3 "Insurgentes" 4 "Jose Martí" 5 "San Cosme" 6 "San Simon", angle(horizontal)) ///
	xtitle("") 
graph export "$directorio\Figuras\timeline_suc_exp.pdf", replace
