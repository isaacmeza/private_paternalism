use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2", clear


*Compute APR (with r=0)
gen vpp=pagos/((1+0)^dias_inicio) if dias_inicio!=0
replace vpp=pagos if dias_inicio==0 
cap drop sum_vpp
bysort prenda : egen sum_vpp=sum(vpp)  
gen apr_eq = sum_vpp + (def_c)*prestamo/(1+0)^dias_ultimo_mov - prestamo 
su apr_eq
gen apr = apr_eq

preserve
keep if apr==0
duplicates drop prenda, force
tempfile temp_aprsell
save `temp_aprsell'
restore

*Keep obs that did not sell the piece. (APR is only relevant for this obs)
keep if apr!=0

*To loop for every `prenda' obs
sort prenda
egen group = group(prenda)
su group, d
local mx = `r(max)'
 
 
forvalues i = 1/`mx' {
di "`i'"
local low = 0.0
local high = 0.1
local err = 1
qui {
	*Bisection 
	while  (`err'>0.0001){
		local mid = (`high'+`low')/2

		* APR 'mid'
		replace vpp=pagos/((1+`mid')^dias_inicio) if dias_inicio!=0 & group==`i'
		replace vpp=pagos if dias_inicio==0 & group==`i'
		cap drop sum_vpp
		bysort prenda : egen sum_vpp=sum(vpp)  if group==`i'
		replace apr_eq = sum_vpp + (def_c)*prestamo/(1+`mid')^dias_ultimo_mov - prestamo  if group==`i'
		su apr_eq if group==`i'

		if `r(mean)'== 0 {
			break
			}

		if `r(mean)'<0 {
			local high = `mid'
			}

		else {
			local low = `mid'
			}	

		local err = abs(`high'-`low')

		}
	replace apr = `mid' if group==`i'
	 
	}
	}

duplicates drop prenda, force
append using `temp_aprsell'
*keep prenda apr* group vpp sum_vpp pagos dias_inicio dias_ult prestamo def_c
keep prenda apr apr_eq
* (%)
replace apr = apr*100
save "$directorio/_aux/apr.dta", replace	
 
