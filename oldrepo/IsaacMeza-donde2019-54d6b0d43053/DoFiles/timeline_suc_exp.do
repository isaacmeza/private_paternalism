*Timeline of the experiment

*use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", clear

use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", clear

*Only empenios
keep if !missing(producto)
keep if clave_movimiento == 4

*Get min/max dates of the experiment
collapse (min) min_fecha = fecha_inicial  (max) max_fecha = fecha_inicial, by(suc)

*Extended time line
merge 1:1 suc using "$directorio/DB/time_line_aux"

gen id = _n

twoway (pcarrow id min_fecha_suc id max_fecha_suc, lcolor(gs3) lwidth(vvthick) msize(vhuge) mcolor(gs3)  barbsize(medlarge)) /// 
(pcarrow id min_fecha id max_fecha, lcolor(gs12) lwidth(thick) msize(medium) mcolor(gs12) barbsize(medlarge)), ///
	graphregion(color(white) margin(5 10 10 10)) ytitle("Branch", margin(medium)) ysize(2.5) scale(2) ///
	ylabel(1 "Calzada" 2 "Congreso" 3 "Insurgentes" 4 "José Martí" ///
	5 "San Cosme" 6 "San Simón", angle(horizontal)) ///
	xtitle("") 	legend(order(1 "Observed Brand" 2 "Experiment"))
	
graph export "$directorio\Figuras\timeline_suc_exp_extended.pdf", replace
