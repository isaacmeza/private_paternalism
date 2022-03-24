
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

* Purpose: Treatment effect of FP over default with observational data

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



********************************************
*				REGRESSIONS				   *
********************************************
duplicates drop idcliente idsucursal date_opening pf_suc pago_fijo, force

********************************************
eststo clear

*FS 
eststo: reghdfe pago_fijo pf_suc ,   absorb(date_opening) vce(cluster idcliente)
su pago_fijo if e(sample) 
estadd scalar DepVarMean = `r(mean)'

cap drop esample
gen esample = e(sample)
cap drop pr
predict pr
cap drop residual
gen residual = pago_fijo - pr 

*IV -OLS
eststo: reghdfe def pago_fijo residual  if esample, absorb(date_opening) vce(cluster idcliente)
su def if e(sample) 
estadd scalar DepVarMean = `r(mean)'

eststo: reghdfe def  pago_fijo , absorb(date_opening) vce(cluster idcliente)
su def if e(sample) 
estadd scalar DepVarMean = `r(mean)'
	
*Save results	
esttab using "$directorio/Tables/reg_results/def_te_obs.csv", se r2 ${star} b(a2) ///
			scalars("DepVarMean DepVarMean") replace 
	
	