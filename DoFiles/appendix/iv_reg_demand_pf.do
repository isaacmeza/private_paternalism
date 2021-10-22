/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification:  October. 19, 2021 
* Modifications: Changed FE regression with command reghdfe		
* Files used:     
		- 
* Files created:  

* Purpose: What types of contracts the client chooses later conditional on pawning (learning that they like FP contracts) - IV Regressions

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

*Clients that have single purchases in a date
sort idcliente date_opening
by idcliente date_opening, sort: egen spi = mean(pago_fijo)
gen flag = spi!=0 & spi!=1
by idcliente: egen multiple_purchase = max(flag)
tab multiple_purchase if f_idcliente==1
keep if multiple_purchase==0

*Number of pledges by person IN THE LAST 52 weeks
sort idcliente date_opening
preserve
duplicates drop idcliente date_opening, force
keep idcliente date_opening 
xtset idcliente date_opening
gen uno = 1
forvalues t=1/52 {
	qui gen l`t' = l`t'.uno
	}
egen num_pawns_52 = rowtotal(l1-l52)
keep idcliente date_opening num_pawns_52
tempfile tempnum
save `tempnum'
restore	
merge m:1 idcliente date_opening using `tempnum', keep(3) nogen


*Demand FP `wk' weeks in the past (explanatory variable)

	*Delay : weeks in advance for demand in the past
local delay = 0

gsort idcliente fechaaltadelprestamo fechavencimiento -pago_fijo

preserve
collapse (max) pf_client = pago_fijo, by(idcliente date_opening date_closing)
*keep last closing date when there are more than one for an opening date
bysort idcliente date_opening : egen mx_date = max(date_closing)
keep if date_closing == mx_date
xtset idcliente date_opening

bysort idcliente : gen three_months_apart = (date_opening-12 <= date_closing[_n-1])
bysort idcliente: gen num_pawns = _N
bysort idcliente: gen f_idcliente = (_n==1)
gen flag_aux = (num_pawns>=2 & three==1)


foreach wk in  2 4 6 8 10 12 15 {
gen visit_past`wk' = 0
forvalues t=1/`wk' {
	replace visit_past`wk' = 1 if !missing(l`t'.pf_client)
	}	
	
*Demand FP in the (immediate+delay) weeks in the past
by idcliente: gen demand_past_imm`wk' = (pf_client[_n-1]==1 & ///
		inrange(date_opening, date_opening[_n-1]+`delay', date_opening[_n-1]+`wk'))
by idcliente: replace demand_past_imm`wk' = . if inrange(date_opening, date_opening[_n-1], date_opening[_n-1]+`delay'-1) & _n!=1
	
*Drop first observations by client as there is no past at that time	
by idcliente: replace demand_past_imm`wk' = . if _n==1

}
	
*Demand in the immediate past (independent of time)
by idcliente: gen demand_past_immn = (pf_client[_n-1]==1)
by idcliente: replace demand_past_immn = . if _n==1
	

sort idcliente date_opening date_closing

*Dummy variable identifying opening of credit after having the past one closed after `wkc' weeks
by idcliente: gen previous_credit_closed_n = 1
by idcliente: replace previous_credit_closed_n = . if _n==1

foreach wkc in 0 1 2 3 4 {
	by idcliente: gen previous_credit_closed_`wkc' = (date_opening>=date_closing[_n-1]+`wkc') if date_opening>date_opening[_n-1]
	by idcliente: replace previous_credit_closed_`wkc' = . if _n==1
	}
by idcliente : gen date_closing_last =  date_closing[_n-1]	
	
tempfile tempclientdem
save `tempclientdem'
restore	

merge m:1 idcliente date_opening using `tempclientdem', keep(3) nogen

*Difference between last closed and current opening
gen difference_btw_pawns =  date_opening-date_closing_last

*FP contract was active in the past (instrument)
preserve
collapse (max) pf_suc = pago_fijo, by(idsuc date_opening)
sort idsuc date_opening
xtset idsuc date_opening

*Adjacent weeks from "event" where FP was activated/deactivated
bysort idsuc : gen event1 = (pf_suc!=l.pf_suc | pf_suc!=f.pf_suc)
gen event2 = 0
forvalues i = 1/2 {
bysort idsuc : replace event2 = 1 if (pf_suc!=l`i'.pf_suc | pf_suc!=f`i'.pf_suc)
}


foreach wk in 2 4 6 /*8 10 12 15 */ {
gen active_past`wk' = 0
forvalues t=1/`wk' {
	replace active_past`wk' = 1 if l`t'.pf_suc==1
	}
	
*Drop first (week) observations by branch as there is no past at that time	
sort idsuc date_opening	
by idsuc: replace active_past`wk' = . if _n==1
}

tempfile tempsuc
save `tempsuc'
restore
merge m:1 idsuc date_opening using `tempsuc', keep(3) nogen

preserve
collapse (max) pf_suc, by(idcliente date_opening)
sort idcliente date_opening
by idcliente : gen active_pastn = (pf_suc[_n-1]==1)
by idcliente : replace active_pastn = . if _n==1
drop pf_suc
tempfile tempactivepast
save `tempactivepast'
restore
merge m:1 idcliente date_opening using `tempactivepast', keep(3) nogen


*We have xxx clients that got two loans within 3 or less months from each other, and for xxx% of those clients the first sequentially preceding loan was taken when the branch had FP available.
bysort idcliente: egen num_clients_3m = max(flag_aux)
tab num_clients_3m if f_idcliente==1
sort idcliente date_opening
by idcliente : gen porc_clients_ppf_aux = (flag_aux==1 & pf_suc[_n-1]==1)
bysort idcliente: egen porc_clients_ppf = max(porc_clients_ppf_aux)
tab porc_clients_ppf if f_idcliente==1 & num_clients_3m==1


********************************************
*				REGRESSIONS				   *
********************************************

eststo clear
********************************************

*2SLS (IV)
foreach wk in n /*2 4 6 8 10 12 15*/ {
	foreach wkc in  0 1  {
	
		*FS 
	eststo: reghdfe demand_past_imm`wk' active_past`wk'    ///
		if pf_suc==1 & previous_credit_closed_`wkc'==1 , absorb(date_opening) vce(cluster idcliente)
	cap drop esample
	gen esample = e(sample)
	su demand_past_imm`wk' if e(sample) 
	estadd scalar DepVarMean = `r(mean)'
	
	cap drop pr
	predict pr
	cap drop residual
	gen residual = demand_past_imm`wk' - pr 

		*IV -OLS
	eststo: reghdfe pago_fijo demand_past_imm`wk' residual  if esample, absorb(date_opening) vce(cluster idcliente)
	su pago_fijo if e(sample) 
	estadd scalar DepVarMean = `r(mean)'

*-----------------------------------------------------------	
	
		*FS -FE
	eststo: reghdfe demand_past_imm`wk' active_past`wk'    ///
		if pf_suc==1 & previous_credit_closed_`wkc'==1 , absorb(idcliente date_opening) vce(cluster idcliente)
	cap drop esample
	gen esample = e(sample)
	su demand_past_imm`wk' if e(sample) 
	estadd scalar DepVarMean = `r(mean)'

	cap drop pr
	predict pr
	cap drop residual
	gen residual = demand_past_imm`wk' - pr 

		*IV
	eststo: reghdfe pago_fijo demand_past_imm`wk' residual   if esample, absorb(idcliente date_opening) vce(cluster idcliente)
	su pago_fijo if e(sample) 
	estadd scalar DepVarMean = `r(mean)'

	}
}
	
	
*Save results	
esttab using "$directorio/Tables/reg_results/iv_reg_demand_pf.csv", se r2 ${star} b(a2) ///
		scalars("DepVarMean DepVarMean") replace 
