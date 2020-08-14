*What types of contracts the client chooses later conditional on pawning (learning that they like FP contracts)
*IV Regressions

use  "${directorio}\DB\base_expansion.dta", clear
keep if linea2==" Alhajas "

*Monthly date
gen mes = month(fechamov)
gen year = year(fechamov)
tostring mes, replace
tostring year, replace
gen month = monthly(mes+"-"+year,"MY")
format month %tm

*Weekly date
gen week = week(fechamov)
tostring week, replace
gen date = weekly(week+"-"+year,"wY")
format date %tw


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
sort idcliente date
by idcliente date, sort: egen spi = mean(pago_fijo)
gen flag = spi!=0 & spi!=1
by idcliente: egen multiple_purchase = max(flag)
tab multiple_purchase if f_idcliente==1
keep if multiple_purchase==0

*Number of pledges by person IN THE LAST 52 weeks
sort idcliente date
preserve
duplicates drop idcliente date, force
keep idcliente date 
xtset idcliente date
gen uno = 1
forvalues t=1/52 {
	qui gen l`t' = l`t'.uno
	}
egen num_pawns_52 = rowtotal(l1-l52)
keep idcliente date num_pawns_52
tempfile tempnum
save `tempnum'
restore	
merge m:1 idcliente date using `tempnum', keep(3) nogen


*Demand FP `wk' days in the past (explanatory variable)
gsort idcliente fechamov -pago_fijo

preserve
collapse (max) pf_client = pago_fijo, by(idcliente date)
xtset idcliente date

bysort idcliente : gen tree_months_apart = (date-12 <= date[_n-1])
bysort idcliente: gen num_pawns = _N
bysort idcliente: gen f_idcliente = (_n==1)
gen flag_aux = (num_pawns>=2 & tree==1)


foreach wk in  6 12 {
gen visit_past`wk' = 0
forvalues t=1/`wk' {
	replace visit_past`wk' = 1 if !missing(l`t'.pf_client)
	}	

*Demand FP in the (immediate) past
by idcliente: gen demand_past_imm`wk' = (pf_client[_n-1]==1 & ///
		inrange(date, date[_n-1]+1, date[_n-1]+`wk'))

*Drop first observations by client as there is no past at that time	
by idcliente: replace demand_past_imm`wk' = . if _n==1

}
	
tempfile tempclient
save `tempclient'
restore	
merge m:1 idcliente date using `tempclient', keep(3) nogen


*FP contract was active in the past (instrument)
preserve
collapse (max) pf_suc = pago_fijo, by(idsuc date)
xtset idsuc date

*Adjacent weeks from "event" where FP was activated/deactivated
bysort idsuc : gen event1 = (pf_suc!=l.pf_suc | pf_suc!=f.pf_suc)
gen event2 = 0
forvalues i = 1/2 {
bysort idsuc : replace event2 = 1 if (pf_suc!=l`i'.pf_suc | pf_suc!=f`i'.pf_suc)
}

foreach wk in  6 12 {
gen active_past`wk' = 0
forvalues t=1/`wk' {
	replace active_past`wk' = 1 if l`t'.pf_suc==1
	}
	
*Drop first (week) observations by branch as there is no past at that time	
sort idsuc date	
by idsuc: replace active_past`wk' = . if _n==1
}

tempfile tempsuc
save `tempsuc'
restore
merge m:1 idsuc date using `tempsuc', keep(3) nogen


*We have xxx clients that got two loans within 3 or less months from each other, and for xxx% of those clients the first sequentially preceding loan was taken when the branch had FP available.
bysort idcliente: egen num_clients_3m = max(flag_aux)
tab num_clients_3m if f_idcliente==1
sort idcliente date
by idcliente : gen porc_clients_ppf_aux = (flag_aux==1 & pf_suc[_n-1]==1)
bysort idcliente: egen porc_clients_ppf = max(porc_clients_ppf_aux)
tab porc_clients_ppf if f_idcliente==1 & num_clients_3m==1


********************************************
*				REGRESSIONS				   *
********************************************

eststo clear
********************************************

*2SLS (IV)
foreach wk in 6  12 {

*OLS-FE
eststo: areg pago_fijo demand_past_imm`wk' visit_past`wk' i.num_pawns_52 i.month if pf_suc==1 & event2==1, absorb(idcliente) vce(robust)
su pago_fijo if e(sample) 
estadd scalar DepVarMean = `r(mean)'


	*FS
eststo: areg demand_past_imm`wk' active_past`wk' visit_past`wk' i.num_pawns_52 i.month if pf_suc==1 & event2==1, absorb(idcliente) vce(robust)
su demand_past_imm`wk' if e(sample) 
estadd scalar DepVarMean = `r(mean)'

cap drop pr
predict pr 
	*IV
eststo: areg pago_fijo pr visit_past`wk' i.num_pawns_52 i.month if e(sample), absorb(idcliente) vce(robust)
su pago_fijo if e(sample) 
estadd scalar DepVarMean = `r(mean)'

}


esttab using "$directorio/Tables/reg_results/iv_reg_demand_pf.csv", se r2 ${star} b(a2) ///
		scalars("DepVarMean DepVarMean") replace 
