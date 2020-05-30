
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   


*Labels

*1 "Control" 
gen pro_1 = (pro_2==0)
/*
2 "No Choice/Fee" 
3 "No Choice/Promise" 
4 "Choice/Fee"
5 "Choice/Promise"
6 "Choice/Fee - SQ" 
7 "Choice/Fee - NSQ" 
8 "Choice/Promise - SQ" 
9 "Choice/Promise - NSQ"
*/


foreach arm of varlist pro_* {
*Histogram of payments by product
twoway ( hist dias_inicio if inrange(dias_inicio, 1,120) & `arm'==1, w(5) percent) ///
	(scatteri 0 30 30 30 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	(scatteri 0 60 30 60 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	(scatteri 0 90 30 90 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	(scatteri 0 120 30 120 , c(l) m(i) color(red)  graphregion(color(white)) ) ///
	, xlabel(0(30)120) legend(off) scheme(s2mono) graphregion(color(white))  ///
	ytitle("Percent")
graph export "$directorio/Figuras/hist_payments_`arm'.pdf", replace

*Histogram of % payment by product
twoway ( hist sum_porcp_c if inrange(sum_porcp_c, 0,1.25) & `arm'==1, w(0.1) percent) ///
	, xlabel(0(0.25)1.25) legend(off) scheme(s2mono) graphregion(color(white))  ///
	ytitle("Percent") 
graph export "$directorio/Figuras/hist_porc_pay_`arm'.pdf", replace


*Histogram of % payment | to positive payment and not recovery by product
twoway ( hist sum_porcp_c if inrange(sum_porcp_c, 0,1.25) & `arm'==1 & def_c==1 & sum_porcp_c>0, w(0.1) percent) ///
	, xlabel(0(0.25)1.25) legend(off) scheme(s2mono) graphregion(color(white))  ///
	ytitle("Percent") 
graph export "$directorio/Figuras/hist_porc_pay_cond_`arm'.pdf", replace

}

