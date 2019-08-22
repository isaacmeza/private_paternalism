
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   

label define product 1 "Control" 2 "No Choice/Fee" 3 "No Choice/Promise" ///
 4 "Choice/Fee - SQ" 5 "Choice/Fee - NSQ" 6 "Choice/Promise - SQ" ///
 7 "Choice/Promise - NSQ"
 label values producto product

*Histogram of payments by product
twoway ( hist dias_inicio if inrange(dias_inicio, 1,120) , ///
		xlabel(0(30)120) scheme(s2mono) graphregion(color(white)) percent by(producto, note(" ") legend(off)  graphregion(color(white)))) ///
	(scatteri 0 30 40 30 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	(scatteri 0 60 40 60 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	(scatteri 0 90 40 90 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	(scatteri 0 120 40 120 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	, graphregion(color(white))  ///
	xtitle("Elapsed days between initial date and current movement") ///
	ytitle("Percent")
graph export "$directorio/Figuras/hist_payments.pdf", replace



