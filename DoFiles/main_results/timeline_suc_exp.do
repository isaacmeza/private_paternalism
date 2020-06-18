/*
Timeline of the experiment
*/

use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", clear

*Only empenios
keep if !missing(producto)
keep if clave_movimiento == 4

*Get min/max dates of the experiment
collapse (min) min_fecha = fecha_inicial  (max) max_fecha = fecha_inicial, by(suc)

*Extended time line
merge 1:1 suc using "$directorio/_aux/time_line_aux.dta"

gen id = _n

twoway (pcarrow id min_fecha_suc id max_fecha_suc, lcolor(gs3)  lwidth(vvthick) msize(vhuge) mcolor(gs3)  barbsize(medlarge)) /// 
(pcarrow id min_fecha id max_fecha, lcolor(gs9) lwidth(vvvthick) msize(vvhuge) mcolor(gs9) barbsize(large)), ///
	graphregion(color(white)) ytitle("Branch") ///
	ylabel(1 "1" 2 "2" 3 "3" 4 "4" ///
	5 "5" 6 "6", angle(horizontal)) ///
	xtitle("") 	legend(off)
	
graph export "$directorio\Figuras\timeline_suc_exp_extended.pdf", replace
