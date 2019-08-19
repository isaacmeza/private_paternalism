use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   
	   
keep prenda dias_inicio producto t_producto sum_porc_p  
drop if missing(producto)
sort prenda dias_inicio producto t_producto
fillin prenda dias_inicio

sort prenda dias_inicio

bysort prenda : replace producto = producto[_n-1] if missing(producto)
bysort prenda : replace t_producto = t_producto[_n-1] if missing(t_producto)
bysort prenda : replace sum_porc_p = sum_porc_p[_n-1] if missing(sum_porc_p)

*Histogram of percentage of payment/un-pledge at 115 days
keep if dias_inicio == 115

xtile perc = sum_porc_p , nq(100)

twoway (hist sum_porc_p if perc<=99, percent  w(0.1) by(producto,  legend(off) note("") graphregion(color(white)))) ///
	, ///
	scheme(s2mono) ///
	graphregion(color(white))  ///
	xtitle("Payment percentage") ytitle("%") xlabel(0(0.25)1.25) 
graph export "$directorio/Figuras/hist_perc_payment.pdf", replace
	
