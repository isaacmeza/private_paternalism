
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   

preserve 

gen choice = 8 if producto == 4 | producto == 5 
replace choice = 9 if producto == 6 | producto == 7

drop if missing(choice)

drop  producto 
rename choice producto
tempfile temp

save `temp'
restore
append using `temp'

*Original
/*
label define product 1 "Control" 2 "No Choice/Fee" 3 "No Choice/Promise" ///
 4 "Choice/Fee - SQ" 5 "Choice/Fee - NSQ" 6 "Choice/Promise - SQ" ///
 7 "Choice/Promise - NSQ"
 */
 
 *Cambios de formato:
replace producto = 11 if producto == 1
replace producto = 12 if producto == 2
replace producto = 13 if producto == 3
replace producto = 14 if producto == 8
replace producto = 15 if producto == 9
replace producto = 16 if producto == 4
replace producto = 17 if producto == 5
replace producto = 18 if producto == 6
replace producto = 19 if producto == 7

label define product 11 "Control" 12 "No Choice/Fee" 13 "No Choice/Promise" ///
14 "Choice/Fee" 15 "Choice/Promise" 16 "Choice/Fee - SQ" ///
 17 "Choice/Fee - NSQ" 18 "Choice/Promise - SQ" ///
 19 "Choice/Promise - NSQ"
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



