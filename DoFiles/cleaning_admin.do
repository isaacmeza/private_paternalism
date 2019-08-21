				
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

*import excel "$directorio/Raw/20131014Consilidacion_Agosto_2013.xlsx", sheet("Hoja1") firstrow clear
*save "$directorio/Raw/20131014Consilidacion_Agosto_2013.dta",	replace

use "$directorio/Raw/20131014Consilidacion_Agosto_2013.dta",	clear


*Recoding of variables
rename Sucursal suc
rename ClaveMovimiento clave_movimiento
rename Valuador valuador
rename FechaMovimiento fecha_movimiento
rename FechaIngreso fecha_inicial
rename NmPrenda prenda
rename MontoPrstamo prestamo
rename ImporteMovimiento importe


foreach X of varlist valuador clave_movimiento { 
encode `X', gen(`X'_)
drop `X'
rename `X'_ `X' 
} 

*Reduce memory size
qui compress


*Definition of labels

label define lab_suc ///
	3 "Calzada"      ///
	5 "Congreso"     ///  
	42 "Insurgentes"  ///
	78 "Jose Marti"   ///
	80 "San Cosme"    ///
	104 "San Simon"    ///


label define lab_mov      ///
	1 "Abono a Capital"   ///
	2 "Venta con Billete" ///
	3 "Desempeno"         ///
	4 "Empeno"            ///
	5 "Refrendo"          ///
	6 "Pase al Moneda"    
	
	
label var suc "Branch"
label var valuador "Appraiser"
label var clave_movimiento "Movement type"

label values suc lab_suc
label values clave_movimiento lab_mov

*Base Auxiliar para la linea de tiempo*
preserve
bysort suc: egen min_fecha_suc = min(fecha_inicial)
bysort suc: egen max_fecha_suc = max(fecha_inicial)

collapse (min) min_fecha_suc = fecha_inicial /// 
(max) max_fecha_suc = fecha_inicial, by(suc)

saveold "$directorio/DB/time_line_aux", replace
restore

*Days passed between movement date and initial date
gen dias_inicio = fecha_movimiento - fecha_inicial
drop if dias_inicio>230 | dias_inicio<0
label var dias_inicio  "Days passed between movement date and initial date"


*Variable of loan amount
sort prenda fecha_movimiento
bysort prenda: gen prestamo_real = prestamo if clave_movimiento==4
bysort prenda: replace prestamo_real = prestamo_real[_n-1] if missing(prestamo_real)
replace prestamo= prestamo_real
drop prestamo_real

gen log_prestamo = log(prestamo)

*Start of randomization
keep if  fecha_inicial>=date("06/09/2012","DMY")  



*Drop negative pledges
bysort prenda: egen aux=min(MontoPrstamoActualizado)
bysort prenda importe: drop if(importe[_n-1]<0)
drop if importe<0
drop aux

						
*Identify type of product
merge m:1 prenda using "$directorio/Raw/db_product.dta", ///
	keepusing(producto t_producto) nogen keep(3)
	

*Verify if loan remains constant in the voucher
bysort prenda: gen aux = 1 if prestamo[_n]~=prestamo[_n-1]
bysort prenda: replace aux = 0 if _n==1
bysort prenda : egen drp = max(aux)
drop if drp==1 
drop drp aux


*Variable creation

sort prenda fecha_movimiento
*'pagos' indicate deposits from the pignorantes, i.e. refrendo, desempeno, venta con billete, abono al capital.
gen pagos=importe if clave_movimiento <= 3 | clave_movimiento==5
replace pagos=0 if pagos==.

label var pagos "Client deposits"

*'porc_pagos' is the percentage of payments wrt the loan
gen porc_pagos=pagos/prestamo
su  porc_pagos
su  porc_pagos if clave_movimiento!=3 , d 

label var porc_pagos "Payment percentage wrt to loan"

*'sum_p' is the cumulative sum of payments
bysort prenda: gen sum_p=sum(pagos)

label var sum_p "Cumulative sum of payments"

*'sum_porc_p' is the percentage of the cumulative sum of the payments wrt to the loan
bysort prenda: gen sum_porc_p=sum_p/prestamo

label var sum_porc_p "Percentage of the cumulative sum of payments"

*Number of payments at current date

gen dum_pago=(pagos!=0 & pagos!=.)
bysort prenda: gen sum_np= sum(dum_pago)
drop dum_pago

label var sum_np "Number of payments at current date"


*Dummy variables indicating the type of movement
gen desempeno=(clave_movimiento==3)
gen abono=(clave_movimiento==1)
gen refrendo=( clave_movimiento==5)
gen ventabillete=( clave_movimiento==2)
gen pasealmoneda=(clave_movimiento==6)

*Recidivism
preserve
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial
*Number of visits to pawn 
bysort NombrePignorante: gen visit_number = _n


*Dummy indicating if customer returned after first visit (WHEN FIRST TREATED)
bysort NombrePignorante: gen first_visit = fecha_inicial[1]
gen aux_reincidence = (fecha_inicial >	first_visit + 75)		
bysort NombrePignorante : egen reincidence = max(aux_reincidence)

keep NombrePignorante fecha_inicial reincidence visit_number
tempfile temp_rec
save  `temp_rec'
restore
merge m:1 NombrePignorante fecha_inicial using `temp_rec', nogen

preserve
keep if inlist(t_producto,4,5)
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial
bysort NombrePignorante: gen visit_number_2 = _n
bysort NombrePignorante: gen choose_same = (producto[_n]==producto[_n-1])
replace choose_same = . if visit_number_2==1
keep choose_same NombrePignorante fecha_inicial
tempfile temp_choose
save  `temp_choose'
restore
merge m:1 NombrePignorante fecha_inicial using `temp_choose', nogen
replace choose_same = 2 if missing(choose_same)

*The next variables indicate if the movement exists in the voucher.
*e.g.
*'sum_p_c' is the maximum cumulative payment 
*'sum_porcp_c'is the maximum percentage of payment
*'num_p' is the number of payments 
bysort prenda: egen des_c=max(desempeno)
bysort prenda: egen ref_c=max(refrendo)
bysort prenda: egen abo_c=max(abono)
bysort prenda: egen vbi_c = max(ventabillete)
bysort prenda: egen sum_p_c=max(sum_p)
bysort prenda: egen sum_porcp_c=max(sum_porc_p)
bysort prenda: egen num_p=sum(sum_np)
bysort prenda: egen pam_c=max(pasealmoneda)
bysort prenda: egen dias_ultimo_mov = max(dias_inicio)
gen dias_inicio_d=dias_inicio if des_c
bysort prenda: egen dias_al_desempenyo=max(dias_inicio_d)
cap drop dias_inicio_d

label var des_c "Se desempeno la prenda"
label var ref_c "Refrendo"
label var abo_c "Se hizo algun Abono a Capital"
label var vbi_c "Se hizo una Venta con Billete"
label var sum_p_c "Maximo de pagos acumulados"
label var sum_porcp_c "Maximo de porcentajes de pagos"
label var num_p "Numero de Pagos"
label var pam_c "Pase al moneda"

*Profit
gen ganancia=(sum_p_c-prestamo)/prestamo

*Suc by day
egen suc_x_dia=group(suc fecha_inicial)

*Number of pledges by suc and day
gen dow=dow(fecha_inicial)
gen monday_tuesday=(dow==1)
preserve
*Pledges only
keep if clave_movimiento == 4 
duplicates drop prenda, force
bysort suc_x_dia t_prod: gen num=_n
bysort suc_x_dia t_prod: egen num_empenio=max(num)
bysort suc_x_dia t_prod: replace num_empenio=. if num!=num_empenio

keep num_empenio prenda 
tempfile temp_emp
save `temp_emp'
restore

merge m:1 prenda using `temp_emp', nogen



*******************************************************************

save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2", replace

bysort prenda fecha_inicial: keep if _n==1

save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", replace
	
