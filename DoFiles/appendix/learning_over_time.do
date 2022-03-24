
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	March. 21, 2022
* Last date of modification: 
* Files used:     
		- 
* Files created:  

* Purpose: Learning graph over time

*******************************************************************************/
*/

clear all

use  "${directorio}\DB\base_expansion.dta", clear
keep if linea2==" Alhajas "

*Monthly date
gen mes = month(fechaaltadelprestamo)
gen year = year(fechaaltadelprestamo)
tostring mes, replace
tostring year, replace
gen month = monthly(mes+"-"+year,"MY")
format month %tm

*Weekly date (opening date)
gen week = week(fechaaltadelprestamo)
tostring week, replace
gen date_opening = weekly(week+"-"+year,"wY")
format date_opening %tw

*Weekly date (closing date)
gen week_c = week(fechavencimiento)
gen year_c = year(fechavencimiento)
tostring year_c, replace
tostring week_c, replace
gen date_closing = weekly(week_c+"-"+year_c,"wY")
format date_closing %tw


*Number of branch per person
bysort idcliente idsucursal: gen nvals = _n == 1 
bysort idcliente: egen num_suc = sum(nvals)
tab num_suc
keep if num_suc==1

*Number of pledges by person
bysort idcliente: gen num_pawns = _N
bysort idcliente: gen f_idcliente = (_n==1)
tab num_pawns if f_idcliente==1
keep if num_pawns<=60

*Clients that have single contracts (purchase) in a date
sort idcliente date_opening
by idcliente date_opening, sort: egen sci = mean(pago_fijo)
gen flag = sci!=0 & sci!=1
by idcliente: egen multiple_contracts = max(flag)
tab multiple_contracts if f_idcliente==1
keep if multiple_contracts==0

*FP contract was active in the branch
preserve
collapse (max) pf_suc = pago_fijo, by(idsuc date_opening)
sort idsuc date_opening
xtset idsuc date_opening

tempfile tempsuc
save `tempsuc'
restore
merge m:1 idsuc date_opening using `tempsuc', keep(3) nogen


*Collapse same day-contract per client
sort idcliente fechaaltadelprestamo
collapse (mean) def (count) num = def , by(idcliente fechaaltadelprestamo pf_suc pago_fijo)
replace num = 1 if inlist(def,0,1)!=1
expand num

*Weekly date (opening date)
gen week = week(fechaaltadelprestamo)
tostring week, replace
gen year = year(fechaaltadelprestamo)
tostring year, replace
gen date_opening = weekly(week+"-"+year,"wY")
format date_opening %tw

*# of time borrower has the option to choose
sort idcliente fechaaltadelprestamo
by idcliente : gen option_choose = sum(pf_suc)
replace option_choose = . if pf_suc!=1
replace option_choose = 17 if option_choose>=17 & !missing(option_choose)

*Choosers vs nonchoosers by "time gets to choose"
matrix def_beta = J(17,2,.)
matrix def_sd = J(17,2,.)

replace def = def*100
reg def i.option_choose##i.pago_fijo, vce(cluster idcliente)
	*Non-Choosers
matrix def_beta[1,1] = _b[_cons]
matrix def_sd[1,1] = sqrt(e(V)[54,54])
forvalues optc = 2/17 {
	matrix def_beta[`optc',1] = _b[_cons] + _b[`optc'.option_choose]
	matrix def_sd[`optc',1] = sqrt(e(V)[54,54] + e(V)[`optc',`optc'] + 2*e(V)[54, `optc'])
}
	*Choosers
matrix def_beta[1,2] = _b[_cons] + _b[1.pago_fijo]
matrix def_sd[1,2] = sqrt(e(V)[54,54] + e(V)[19,19] + 2*e(V)[54,19]) 
forvalues optc = 2/17 {
	matrix def_beta[`optc',2] = _b[_cons] + _b[1.pago_fijo] + _b[`optc'.option_choose] + _b[`optc'.option_choose#1.pago_fijo] 
	matrix def_sd[`optc',2] = sqrt(e(V)[54,54] + e(V)[19,19] + e(V)[`optc',`optc'] + e(V)[`=19+(2*`optc')',`=19+(2*`optc')'] + 2*e(V)[54,19] + 2*e(V)[54,`optc'] + 2*e(V)[54,`=19+(2*`optc')'] + 2*e(V)[19,`optc'] + 2*e(V)[19,`=19+(2*`optc')'] + 2*e(V)[`optc',`=19+(2*`optc')'])
}

svmat def_beta
svmat def_sd
gen optc = _n if _n<=17

*CI
gen hi1_5 = def_beta1 + invnormal(0.975)*def_sd1
gen hi1_10 = def_beta1 + invnormal(0.95)*def_sd1
gen hi2_5 = def_beta2 + invnormal(0.975)*def_sd2
gen hi2_10 = def_beta2 + invnormal(0.95)*def_sd2

gen lo1_5 = def_beta1 - invnormal(0.975)*def_sd1
gen lo1_10 = def_beta1 - invnormal(0.95)*def_sd1
gen lo2_5 = def_beta2 - invnormal(0.975)*def_sd2
gen lo2_10 = def_beta2 - invnormal(0.95)*def_sd2


*Learning Graph
twoway (rarea hi1_5 lo1_5 optc, color(maroon%15)) ///
	(rarea hi1_10 lo1_10 optc, color(maroon%30)) ///
	(rarea hi2_5 lo2_5 optc, color(navy%15)) ///
	(rarea hi2_10 lo2_10 optc, color(navy%30)) ///
	(line def_beta1 optc, color(maroon) lwidth(medthick)) ///
	(line def_beta2 optc, color(navy) lwidth(medthick)) ///
	, xlabel(1(2)18) ytitle("% Default") xtitle("Number of times exposed to FP") graphregion(color(white)) ///
	legend(order( 6 "Choosers" 5 "Non-Choosers") size(small)) 
	

foreach var of varlist def_beta1 def_beta2 hi* lo* {
	lpoly `var' optc, deg(2) bw(2) gen(optc_`var' `var'_) nograph
}	
	
twoway (rarea hi1_5_ lo1_5_ optc_hi1_5, color(maroon%15)) ///
	(rarea hi1_10_ lo1_10_ optc_hi1_10, color(maroon%30)) ///
	(rarea hi2_5_ lo2_5_ optc_hi2_5, color(navy%15)) ///
	(rarea hi2_10_ lo2_10_ optc_hi2_10, color(navy%30)) ///
	(line def_beta1_ optc_def_beta1, color(maroon) lwidth(medthick)) ///
	(line def_beta2_ optc_def_beta2, color(navy) lwidth(medthick)) ///
	, xlabel(1(2)18) ytitle("% Default") xtitle("Number of times exposed to FP") graphregion(color(white)) ///
	legend(order( 6 "Choosers" 5 "Non-Choosers") size(small)) 	
graph export "$directorio\Figuras\learning_over_time.pdf", replace
	