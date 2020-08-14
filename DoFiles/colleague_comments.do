* Referee comments

use "$directorio/DB/Master.dta", clear


*De los que les toco frequent payment y luego fueron a empeñar de nuevo y les tocó choice: (a) cuántos son? (b) que % escogió frequent payment?
preserve
duplicates drop NombrePignorante fecha_ini, force
drop if missing(producto)

keep NombrePignorante fecha_ini producto t_producto

br NombrePignorante producto
gen bueno=producto==5

*en algun momento tuvieron eleccion
bysort NombrePignorante: gen aux_ch = t_producto==4
bysort NombrePignorante: egen ch = max(aux_ch)

*en algun momento tuvieron sq o fee
bysort NombrePignorante: gen aux_sq = t_producto==1
bysort NombrePignorante: egen sq = max(aux_sq)

bysort NombrePignorante: gen aux_fee = t_producto==2
bysort NombrePignorante: egen fee = max(aux_fee)


keep if ch==1 
su bueno
keep if sq==1 | fee==1

su bueno
bysort NombrePignorante: gen nvals=_N
restore


*dummy de si refrendó la prenda del experimento antes de 90 dias y ver si hay efecto de fee forcing vs control
*Andrei dice que nuestro efecto de repeat business es porque al hacerlos pagar rápido necesitan otro préstamo. Yo quiero argumentar que no, que si hubieran necesitado otro prestamo podrían refrendar. Y que no refrendan más

reg ref_90_c pro_2 ${C0}, r cluster(suc_x_dia)
preserve
collapse reincidence reincidence_rec reincidence_bef* prestamo $C1  pro_2 ///
	, by(NombrePignorante fecha_inicial)

*Analyze reincidence for the FIRST treatment arm
sort NombrePignorante fecha_inicial
bysort NombrePignorante : keep if _n==1

reg reincidence pro_2 ${C1} , r 
reg reincidence_rec pro_2 ${C1} , r 

*Si fuera verdad que necesitan otro credito para su emergencia, porque esperan 2 meses en sacarlo? Que pasaria si defines el outcome de repeat purchase como sacar otro empenio ANTES DE 30 DIAS? Habria effecto?
reg reincidence_bef30 pro_2 ${C1} , r 
reg reincidence_bef60 pro_2 ${C1} , r 
reg reincidence_bef75 pro_2 ${C1} , r 
restore



