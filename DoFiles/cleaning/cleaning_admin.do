/*******************************************************************************
This do file cleans the admin data & generates relevant variables for analysis -
which is a panel recording all transactions
of a given pawn. 
*******************************************************************************/

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
*bysort suc: egen min_fecha_suc = min(fecha_inicial)
*bysort suc: egen max_fecha_suc = max(fecha_movimiento)

collapse (min) min_fecha_suc = fecha_inicial /// 
(max) max_fecha_suc = fecha_movimiento max_fecha2 = fecha_inicial, by(suc)

save "$directorio/_aux/time_line_aux.dta", replace
restore

*Days passed between movement date and initial date
gen dias_inicio = fecha_movimiento - fecha_inicial
drop if dias_inicio>230 | dias_inicio<0
label var dias_inicio  "Days passed between movement date and initial date"
*Days of first payment
gen dpp = dias_inicio if clave_movimiento!=4

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
	
*Treatment arms vs control
forvalues i = 2/5 {
	gen pro_`i' = (t_producto == `i') 
	replace pro_`i' = . if (t_producto!=`i' & t_producto!=1)
	}

forvalues i = 6/9 {
	gen pro_`i' = (producto == `i'-2) 
	replace pro_`i' = . if (producto!=`i'-2 & producto!=1)
	}
	
label var pro_2 "NC-Fee"	
label var pro_3 "NC-Promise"	
label var pro_4 "C-Fee"	
label var pro_5 "C-Promise"	
label var pro_6 "C-Fee-SQ"	
label var pro_7 "C-Fee-NSQ"	
label var pro_8 "C-Promise-SQ"	
label var pro_9 "C-Promise-NSQ"				

*Verify if loan remains constant in the voucher
bysort prenda: gen aux = 1 if prestamo[_n]~=prestamo[_n-1]
bysort prenda: replace aux = 0 if _n==1
bysort prenda : egen drp = max(aux)
drop if drp==1 
drop drp aux


*Variable creation

sort prenda fecha_movimiento
*'pagos' indicate deposits from the customers, i.e. refrendo, desempeno, venta con billete, abono al capital.
gen pagos=importe if clave_movimiento <= 3 | clave_movimiento==5
replace pagos=0 if pagos==.

label var pagos "Client deposits"

*'pagos' indicate deposits from the customers, i.e. refrendo, desempeno, venta con billete, abono al capital.
* DISCOUNTED with daily interest rate equivalent to a 7% monthly rate.
gen pagos_disc=importe/((1+0.00225783)^dias_inicio) if clave_movimiento <= 3 | clave_movimiento==5
replace pagos_disc=0 if pagos_disc==.

label var pagos_disc "Client deposits (discounted)"

*'porc_pagos' is the percentage of payments wrt the loan
gen porc_pagos=pagos/prestamo
su  porc_pagos
su  porc_pagos if clave_movimiento!=3 , d 

label var porc_pagos "Payment percentage wrt to loan"

*'sum_p' is the cumulative sum of payments
sort prenda fecha_movimiento
by prenda: gen sum_p=sum(pagos)

label var sum_p "Cumulative sum of payments"

*'sum_p_disc' is the cumulative discounted sum of payments
sort prenda fecha_movimiento
by prenda: gen sum_p_disc=sum(pagos_disc)

label var sum_p_disc "Cumulative discounted sum of payments"

*'sum_porc_p' is the percentage of the cumulative sum of the payments wrt to the loan
sort prenda fecha_movimiento
by prenda: gen sum_porc_p=sum_p/prestamo

label var sum_porc_p "Percentage of the cumulative sum of payments"

*Number of payments at current date
gen dum_pago=(pagos!=0 & pagos!=.)
sort prenda fecha_movimiento
by prenda: gen sum_np= sum(dum_pago)
by prenda : replace dum_pago = . if fecha_movimiento[_n]==fecha_movimiento[_n-1]
by prenda: gen sum_visit= sum(dum_pago)

drop dum_pago

label var sum_np "Number of payments at current date"
label var sum_visit "Number of visits at current date"

*Dummy indicating if a fee was charged (late payment)		
	*Payment in each cylce
bysort prenda : gen ppc = inrange(fecha_movimiento, fecha_inicial, fecha_inicial+30) if pagos>0
bysort prenda : egen pago_primer_ciclo = max(ppc) 
replace pago_primer_ciclo = 0 if missing(pago_primer_ciclo)
bysort prenda : gen psc = inrange(fecha_movimiento, fecha_inicial+31, fecha_inicial+60) if pagos>0
bysort prenda : egen pago_seg_ciclo = max(psc) 
replace pago_seg_ciclo = 0 if missing(pago_seg_ciclo)
bysort prenda : gen ptc = inrange(fecha_movimiento, fecha_inicial+61, fecha_inicial+90) if pagos>0
bysort prenda : egen pago_ter_ciclo = max(ptc) 
replace pago_ter_ciclo = 0 if missing(pago_ter_ciclo)
	*Fee dummy (late payment)
gen fee = 1-(pago_primer_ciclo & pago_seg_ciclo & pago_ter_ciclo)	
replace fee = 0 if prod==1
replace fee = . if !inlist(prod,2,5)
label var fee "Charged late fee - dummy"

*Var correction (desempeno)
bysort prenda: replace clave_movimiento=5 if clave_movimiento==3 & sum_p<prestamo


*Dummy variables indicating the type of movement
gen desempeno=(clave_movimiento==3)
gen abono=(clave_movimiento==1)
gen refrendo=(clave_movimiento==5)
gen ventabillete=(clave_movimiento==2)
gen pasealmoneda=(clave_movimiento==6)

*Recidivism
preserve
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial
*Number of visits to pawn 
bysort NombrePignorante: gen visit_number = _n
qui su visit_number, d
local tr99 = `r(p99)'
replace visit_number = `tr99' if visit_number>=`tr99'

*Dummy indicating if customer received more than one treatment arm
bysort NombrePignorante t_prod : gen unique_arms = _n==1
replace unique_arms = 0 if missing(t_prod)
bysort NombrePignorante : egen num_arms = sum(unique_arms)
gen more_one_arm = (num_arms>1)

*Dummy indicating if customer returned after first visit (WHEN FIRST TREATED)
sort NombrePignorante fecha_inicial
bysort NombrePignorante: gen first_visit = fecha_inicial[1]
bysort NombrePignorante: gen first_product = t_producto[1]
bysort NombrePignorante: gen first_prenda = prenda[1]
gen aux_reincidence = (fecha_inicial >	first_visit + 75) if !missing(first_product)	
bysort NombrePignorante : egen reincidence = max(aux_reincidence)

*Dummy indicating if customer received same treatment in reincidence (compared to first visit)
sort NombrePignorante fecha_inicial
bysort NombrePignorante : gen aux_re_product = t_prod ///
					if aux_reincidence==1 & aux_reincidence[_n-1]==0
bysort NombrePignorante : egen reincidence_product = max(aux_re_product) 
bysort NombrePignorante : gen same_prod_reincidence = (first_product==reincidence_product) ///
					if !missing(reincidence)


keep NombrePignorante fecha_inicial reincidence visit_number num_arms ///
		more_one_arm same_prod_reincidence first_prenda
tempfile temp_rec
save  `temp_rec'
restore


* Number of visits and treatment arms in first 75 days
preserve
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial
bysort NombrePignorante: gen first_visit = fecha_inicial[1]
keep if (fecha_inicial <= first_visit + 75)
bysort NombrePignorante: gen visit_number_75 = _N
replace visit_number_75 = `tr99' if visit_number_75>=`tr99'
bysort NombrePignorante t_prod : gen unique_arms = _n==1
replace unique_arms = 0 if missing(t_prod)
bysort NombrePignorante : egen num_arms_75 = sum(unique_arms)
gen more_one_arm_75 = (num_arms_75>1)
keep NombrePignorante visit_number_75 num_arms_75 more_one_arm_75
duplicates drop
tempfile temp_rec75
save  `temp_rec75'
restore

*Dummy indicating if in choice arm, customer selected same product as before
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


merge m:1 NombrePignorante fecha_inicial using `temp_rec', nogen
merge m:1 NombrePignorante using `temp_rec75', nogen
merge m:1 NombrePignorante fecha_inicial using `temp_choose', nogen
replace choose_same = 2 if missing(choose_same)

*The next variables indicate if the movement exists in the voucher.
*e.g.
*'sum_p_c' is the maximum cumulative payment 
*'sum_porcp_c'is the maximum percentage of payment
*'num_p' is the number of payments 
bysort prenda: egen des_c=max(desempeno)
gen def_c = 1-des_c
bysort prenda: egen ref_c=max(refrendo)
bysort prenda: egen abo_c=max(abono)
bysort prenda: egen vbi_c = max(ventabillete)
bysort prenda: egen sum_p_c=max(sum_p)
bysort prenda: gen pays_c=(sum_p_c>0) if !missing(sum_p_c)
bysort prenda: egen sum_pdisc_c=max(sum_p_disc)
bysort prenda: egen mn_p_c=mean(sum_p)
bysort prenda: egen mn_pdisc_c=mean(sum_p_disc)
bysort prenda: egen sum_porcp_c=max(sum_porc_p)
bysort prenda: egen num_p=max(sum_np)
bysort prenda: egen num_v=max(sum_visit)
bysort prenda: egen pam_c=max(pasealmoneda)
bysort prenda: egen dias_primer_pago = min(dpp)
bysort prenda: egen dias_ultimo_mov = max(dias_inicio)
gen dias_inicio_d=dias_inicio if des_c
bysort prenda: egen dias_al_desempenyo=max(dias_inicio_d)
replace dias_al_desempenyo = 1 if dias_al_desempenyo==0
replace dias_inicio = 1 if dias_inicio==0 & des_c==1
cap drop dias_inicio_d

* `Naiveness' variables (item-level)
bysort prenda: gen ref_default = (1-des_c)*ref_c
bysort prenda: gen pos_pay_default = (1-des_c)*(sum_porcp_c>0) if !missing(sum_porcp_c)
bysort prenda: gen pay_30_default = (1-des_c)*(sum_porcp_c>=.30) if !missing(sum_porcp_c)
gen def_120 = def_c
replace def_120 = 0 if dias_al_desempenyo <= 120 & !missing(dias_al_desempenyo)
bysort prenda: gen zero_pay_default = (1-des_c)*(sum_porcp_c==0) if !missing(sum_porcp_c)
gen pos_pay_120_default = (1-des_c)*(pagos>0 & dias_inicio>120) 
bysort prenda: egen pos_pay_120_def_c = max(pos_pay_120_default)

* Naiveness (person-level)
sort NombrePignorante fecha_movimiento HoraMovimiento
by NombrePignorante : gen primer_prenda = (prenda==prenda[1])
by NombrePignorante : gen primer_producto = producto[1]
by NombrePignorante : egen primera_fecha_aux = min(fecha_movimiento) if primer_prenda==1
by NombrePignorante : egen primera_fecha = min(primera_fecha_aux)
by NombrePignorante : egen ultima_fecha_aux = max(fecha_movimiento) if primer_prenda==1
by NombrePignorante : egen ultima_fecha = min(ultima_fecha_aux)

drop primera_fecha_aux ultima_fecha_aux
format primera_fecha ultima_fecha %td 

by NombrePignorante : gen naiveness_1_aux = ref_c if primer_prenda==1
by NombrePignorante : gen naiveness_2_aux = ref_default if primer_prenda==1
by NombrePignorante : gen naiveness_3_aux = pos_pay_default if primer_prenda==1
by NombrePignorante : gen naiveness_4_aux = pay_30_default if primer_prenda==1

forvalues i=1/4 {
	by NombrePignorante : egen naiveness_`i' = min(naiveness_`i'_aux)
	drop naiveness_`i'_aux
	}
* Valid items to interact naiveness w/treatment effect to measure its intensity 
by NombrePignorante : gen valid_item = (fecha_inicial>=ultima_fecha & (primer_producto==1 | primer_producto==.))

label var des_c "Un-pledge"
label var def_c "Default"
label var def_120 "Default (120)"
label var ref_c "Refrendum"
label var abo_c "Payment to principal"
label var vbi_c "Venta con Billete"
label var sum_p_c "Cum (total) payments"
label var pays_c "Dummy of payment>0"
label var sum_pdisc_c "Cum (total)(discounted) payments"
label var mn_p_c "Mean of payments"
label var mn_pdisc_c "Mean of (discounted) payments"
label var sum_porcp_c "Percentage of payment"
label var num_p "Number of payment"
label var num_p "Number of visits"
label var pam_c "Pase al moneda"
label var ref_default "Refrendum but default"
label var pos_pay_default "Positive payment but default"
label var pos_pay_120_def_c "Positive payment (after 120dd) but default"
label var zero_pay_default "Selled pawn"
label var pay_30_default "Payment of at least 30pp but default"


*Trimming
foreach var of varlist sum_porcp_c sum_p_c sum_pdisc_c {
	xtile perc_`var' = `var' , nq(100)
	replace `var'= . if perc_`var'>99
	drop perc_`var'
	}

*Financial cost
gen fc_admin = sum_p_c
replace fc_admin = fc_admin + prestamo/0.7 if des_c != 1
gen log_fc_admin = log(1+fc_admin)
	*discounted
gen fc_admin_disc = sum_pdisc_c
replace fc_admin_disc = fc_admin_disc + prestamo/0.7 if des_c != 1
gen log_fc_admin_disc = log(1+fc_admin_disc)

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
*Panel data
save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2", replace

bysort prenda fecha_inicial: keep if _n==1
*Final Cross-section
save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", replace
	
