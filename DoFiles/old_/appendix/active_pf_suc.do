
use  "${directorio}\DB\base_expansion.dta", clear
keep if linea2==" Alhajas "

*Monthly date
gen mes = month(fechamov)
gen year = year(fechamov)
tostring mes, replace
tostring year, replace
gen date = monthly(mes+"-"+year,"MY")
format date %tm

/*
Grafica de "existe contrato pagos fijos" en el tiempo, separados por sucursal (y={0,1})
*/
collapse (max) pf_suc = pago_fijo, by(idsuc date)
bysort idsuc : egen pf = mean(pf_suc)
bysort idsuc : gen always_pf = (pf==1) if _n==1
bysort idsuc : gen never_pf = (pf==0) if _n==1
bysort idsuc : gen both = (pf!=1 & pf!=0) if _n==1 
su always_pf never_pf both
xtset  idsuc date

*Select random sample of 20
preserve
duplicates drop idsuc, force
keep idsuc
sample 20, count
gen sampl = 1
tempfile temp
save `temp'
restore

merge m:1 idsuc using `temp', nogen

tsline pf_suc if sampl==1, by(idsuc, note("") title("") graphregion(color(white)))  graphregion(color(white)) ///
	xtitle("Date") ytitle("Exists FP contract") ///
	yla(0 1) xla(, format(%tmCY) angle(vertical) )
graph export "$directorio\Figuras\active_pf_suc.pdf", replace	

