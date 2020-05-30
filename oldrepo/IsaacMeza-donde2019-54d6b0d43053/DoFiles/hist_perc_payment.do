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

*Add choice and no choice without divisions
preserve 

gen choice = 8 if producto == 4 | producto == 5 
replace choice = 9 if producto == 6 | producto == 7

drop if missing(choice)

drop dias_inicio producto t_producto _fillin prenda 
rename choice producto
tempfile temp

save `temp'
restore
append using `temp'

xtile perc = sum_porc_p , nq(100)

*Original
/*
label define product 1 "Control" 2 "No Choice/Fee" 3 "No Choice/Promise" ///
 4 "Choice/Fee - SQ" 5 "Choice/Fee - NSQ" 6 "Choice/Promise - SQ" ///
 7 "No Choice/Promise - NSQ" 8 "Choice/Fee" 9 "Choice/Promise"
 label values producto product
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

twoway (hist sum_porc_p if perc<=99, percent  w(0.1) by(producto,  legend(off) note("") graphregion(color(white)))) ///
	, ///
	scheme(s2mono) ///
	graphregion(color(white))  ///
	xtitle("Payment percentage") ytitle("%") xlabel(0(0.25)1.25) 
graph export "$directorio/Figuras/hist_perc_payment.pdf", replace
	
*Conditional on positive payment and loosing 
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   

*Dummy for desempeno
bysort prend: egen aux = max(desempeno)

keep if aux == 0
drop aux

*Dummy for positive payment 
*gen dummy_importe = ImporteCapital > 0 | ImporteInters > 0
*bysort prenda: egen aux2 = max(dummy_importe)

*keep if aux2 == 1
keep if sum_p_c>0

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

*Add choice and no choice without divisions
preserve 

gen choice = 8 if producto == 4 | producto == 5 
replace choice = 9 if producto == 6 | producto == 7

drop if missing(choice)

drop dias_inicio producto t_producto _fillin prenda 
rename choice producto
tempfile temp

save `temp'
restore

append using `temp'

xtile perc = sum_porc_p , nq(100)

label define product 1 "Control" 2 "No Choice/Fee" 3 "No Choice/Promise" ///
 4 "Choice/Fee - SQ" 5 "Choice/Fee - NSQ" 6 "Choice/Promise - SQ" ///
 7 "Choice/Promise - NSQ" 8 "Choice/Fee" 9 "Choice/Promise"
 label values producto product

*zero bin
sum sum_porc_p if sum_porc_p == 0
disp `r(N)'

gen zero = sum_porc_p == 0
bysort producto: gen aux = _N
bysort producto: egen aux2 = sum(zero)
gen aux3 = aux2/aux

set obs `=_N+9'

local j = 1
forvalues i = 5823/5831{
	replace producto = `j' if _n == `i'
	local j = `j'+1
}


replace zero = 0 if zero == .
replace aux3 = 0 if aux3 == .
 
replace aux3 = aux3*100
gen aux4 = aux3
drop zero_e
gen zero_e = 0.01

twoway (line aux3 zero if zero==0, lwidth(thick)  graphregion(color(white)) by(producto,  note("")) legend(off) graphregion(color(white))) /// 
(hist sum_porc_p if sum_porc_p > 0 & perc<=99, ///
 percent scheme(s2mono) w(0.1) by(producto,graphregion(color(white)) legend(off) note(""))), graphregion(color(white)) ///
 xtitle("Payment percentage") ytitle("%") xlabel(0(0.25)1.25) legend(off) graphregion(color(white))
 
graph export "$directorio/Figuras/hist_perc_payment_conditional.pdf", replace
