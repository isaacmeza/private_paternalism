/*Tab of number of pawns per person & # of different arms */

use "$directorio/DB/Master.dta", clear

keep Nombre prenda t_prod clave_movimiento
*Keep first movement
keep if clave_movimiento == 4
duplicates drop prenda, force

sort Nombre prenda
*Number of pawns per person
bysort Nombre : gen num_pawns = _N

forvalues i=1/5 {
	gen arm_`i' = t_producto==`i'
	*Number of treatment arms per person
	bysort Nombre : egen num_arm_`i' = sum(arm_`i')
	}
	
duplicates drop Nombre, force


su num_pawns, meanonly

local k = 6
forvalues j = 0/`r(max)' {
	local i = 3
	foreach var of varlist num_pawns num_arm_* {
		local Col=substr(c(ALPHA),2*(`i')-1,1)
		count if `var' ==`j'
		qui putexcel `Col'`k'=matrix(`r(N)') using "$directorio\Tables\tab_num_arms_pawns.xlsx", sheet("tab_num_arms_pawns") modify
		local i = `i' + 2
		}
	local k = `k' + 1
	}

