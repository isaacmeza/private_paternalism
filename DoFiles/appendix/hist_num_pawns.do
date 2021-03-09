use  "${directorio}\DB\base_expansion.dta", clear
keep if linea2==" Alhajas "

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


hist num_pawns, discrete percent scheme(s2mono) graphregion(color(white)) ///
	xtitle("Number of pawns")
graph export "$directorio\Figuras\hist_num_pawns.pdf", replace	
	
