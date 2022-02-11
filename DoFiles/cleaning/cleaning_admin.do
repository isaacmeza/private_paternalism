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
rename NúmPrenda prenda
rename MontoPréstamo prestamo
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
	104 "San Simon"    


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


*Days passed between movement date and initial date
gen dias_inicio = fecha_movimiento - fecha_inicial
su fecha_movimiento
drop if fecha_inicial>`r(max)'-230
drop if dias_inicio>230 | dias_inicio<0
label var dias_inicio  "Days passed between movement date and initial date"
*Days of first payment
gen dpp = dias_inicio if clave_movimiento!=4

*Variable of loan amount
sort prenda fecha_movimiento HoraMovimiento
bysort prenda: gen prestamo_real = prestamo if clave_movimiento==4
bysort prenda: replace prestamo_real = prestamo_real[_n-1] if missing(prestamo_real)
replace prestamo = prestamo_real
drop prestamo_real

gen log_prestamo = log(prestamo)

*Drop negative pledges
bysort prenda: egen aux=min(MontoPréstamoActualizado)
bysort prenda importe: drop if(importe[_n-1]<0)
drop if importe<0
drop aux

*Drop pawns with 'duplicated' un-pledges
sort prenda fecha_movimiento HoraMovimiento
by prenda : gen uno = clave_movimiento==3
by prenda : egen dup = sum(uno)
by prenda : gen pd = sum(uno)
drop if pd==uno & dup==2
drop uno dup pd

*Auxiliar dataset for number of pawns by branch-day
preserve
*Number of pledges by suc and day
bysort fecha_inicial suc : gen aux_uno=1 if clave_movimiento == 4 
bysort fecha_inicial suc : gen num_empenio_sucdia=sum(aux_uno) if clave_movimiento == 4 
bysort fecha_inicial suc : egen aux_num_emp=sum(aux_uno) if clave_movimiento == 4 
bysort fecha_inicial suc : replace num_empenio_sucdia=. if num_empenio_sucdia!=aux_num_emp &  clave_movimiento == 4 

keep if !missing(num_empenio_sucdia)
keep fecha_inicial  suc num_empenio prenda
save "$directorio/_aux/num_pawns_suc_dia.dta", replace 
restore

*Auxiliar dataset for timeline
preserve 
collapse (min) min_fecha_suc = fecha_inicial /// 
(max) max_fecha_suc = fecha_movimiento max_fecha2 = fecha_inicial, by(suc)
save "$directorio/_aux/time_line_aux.dta", replace
restore


*pre-randomization date
preserve
keep if fecha_inicial<date("06/09/2012","DMY")  
bysort suc fecha_inicial: keep if _n==1

merge 1:1 suc fecha_inicial using "$directorio/_aux/num_pawns_suc_dia.dta", nogen keep(1 3)
rename num_empenio_sucdia num_empenio

*Number of pledges by suc and day
gen dow=dow(fecha_inicial)
gen weekday=inlist(dow,1,2,3,4,5)

keep fecha_inicial suc prestamo weekday num_empenio
save "$directorio/_aux/pre_experiment_admin.dta", replace

restore

*Start of randomization
keep if  fecha_inicial>=date("06/09/2012","DMY")  

						
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

*Choose commitment variable
gen choose_commitment =  (producto==5 | producto==7) if inlist(producto, 4, 5, 6, 7)
		

*Verify if loan remains constant in the voucher
bysort prenda: gen aux = 1 if prestamo[_n]~=prestamo[_n-1]
bysort prenda: replace aux = 0 if _n==1
bysort prenda : egen drp = max(aux)
drop if drp==1 
drop drp aux


*Variable creation

sort prenda fecha_movimiento HoraMovimiento
*'pagos' indicate deposits from the customers, i.e. refrendo, desempeno, venta con billete, abono al capital.
*Filter those that indicate payments
gen pagos=importe if inlist(clave_movimiento, 1,3,5)
replace pagos=0 if pagos==.
label var pagos "Client deposits"

*Payed interests
gen intereses = importe if inlist(clave_movimiento, 5)
sort prenda fecha_mov
by prenda : egen spagos = sum(pagos)
by prenda : egen sint = sum(intereses)
replace intereses = spagos-sint-prestamo if clave_movimiento==3
drop spagos sint
label var intereses "Interests"

*Credit has ended, meaning either 'desempeno' or 'pase al moneda'
gen concluyo = inlist(clave_movimiento,3,6)
bysort prenda : egen concluyo_c = max(concluyo)

*Incurred interests/fee
preserve
drop if clave_movimiento==2
collapse (mean) prestamo (sum) importe (mean) dias_inicio (mean) concluyo_c (mean) producto, by(prenda fecha_movimiento)
sort prenda fecha_movimiento 

gen double incurred_int = .
gen double fee_strong = .
gen capital = prestamo 
bysort prenda : gen num_mov = _N
su num_mov
forvalues i = 2/`r(max)' {
	*Interests (7%)
	bysort prenda : replace incurred_int = capital[_n-1]*((1+0.002257833358012379025857)^(dias_inicio-dias_inicio[_n-1])-1) if _n==`i'
	*Fee
	bysort prenda : replace fee_strong = .02*capital[_n-1]/3*(ceil(dias_inicio/30)-ceil(dias_inicio[_n-1]/30)-1+(importe<=capital/3)) if _n==`i'
	bysort prenda : replace capital = capital[_n-1] - (importe-incurred_int-fee_strong) if _n==`i'
	}	
bysort prenda : replace incurred_int = incurred_int + capital*((1+0.002257833358012379025857)^(230-dias_inicio)-1) if concluyo_c==0 & _n==_N

keep prenda fecha_movimiento incurred_int fee_strong capital
tempfile temp_int
save `temp_int'
restore

merge m:1 prenda fecha_movimiento using `temp_int', nogen
*Drop duplicates by prenda-date
foreach var of varlist incurred_int fee_strong {
	bysort prenda fecha_mov : replace `var' = . if _n!=1
	}
	
*Payed fees
gen payed_fees = fee_strong if pagos>0 & inlist(producto,2,5)
	
label var incurred_int "Incurred interests"
label var fee_strong "Incurred fees"
label var payed_fees "Payed fees"

	
*'sum_p' is the cumulative sum of payments
sort prenda fecha_movimiento HoraMovimiento
*Add fees
replace pagos = pagos + payed_fees if !missing(payed_fees)
by prenda: gen sum_p=sum(pagos)
label var sum_p "Cumulative sum of payments"

*'sum_int' is the cumulative sum of interest
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_int=sum(intereses)
label var sum_int "Cumulative sum of interests"

*'sum_incurred_int' is the cumulative sum of incurred interest
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_inc_int=sum(incurred_int)
label var sum_inc_int "Cumulative sum of incurred interests"

*'sum_incurred_fee' is the cumulative sum of incurred fees
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_inc_fee=sum(fee_strong)
label var sum_inc_fee "Cumulative sum of incurred fees"

*'sum_pay_fee' is the cumulative sum of payed fees
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_pay_fee=sum(payed_fees)
label var sum_pay_fee "Cumulative sum of payed fees"

*Var correction (desempeno)
bysort prenda: replace clave_movimiento=5 if clave_movimiento==3 & sum_p-sum_int-sum_pay_fee<prestamo - 1

*'pagos_disc' indicate deposits from the customers, i.e. refrendo, desempeno, venta con billete, abono al capital.
* DISCOUNTED with daily interest rate equivalent to a 7% monthly rate.
save "$directorio/_aux/pre_admin.dta", replace /*save for discounted_noeffect.do*/	
gen pagos_disc=importe/((1+0.002257833358012379025857)^dias_inicio) if clave_movimiento <= 3 | clave_movimiento==5
replace pagos_disc=0 if pagos_disc==.
label var pagos_disc "Client deposits (discounted)"

*'porc_pagos' is the percentage of payments wrt the loan
gen porc_pagos=pagos/prestamo
su  porc_pagos
su  porc_pagos if clave_movimiento!=3 , d 
label var porc_pagos "Payment percentage wrt to loan"

*'porc_int' is the percentage of interest wrt the loan
gen porc_int=intereses/prestamo
label var porc_int "Interest percentage wrt to loan"

*'porc_inc_int' is the percentage of incurred interest wrt the loan
gen porc_inc_int=incurred_int/prestamo
label var porc_inc_int "Incurred interest percentage wrt to loan"

*'porc_inc_fee' is the percentage of incurred fee wrt the loan
gen porc_inc_fee=fee_strong/prestamo
label var porc_inc_fee "Incurred fee percentage wrt to loan"

*'porc_pay_fee' is the percentage of payed fee wrt the loan
gen porc_pay_fee=payed_fees/prestamo
label var porc_pay_fee "Payed fee percentage wrt to loan"

*'sum_p_disc' is the cumulative discounted sum of payments
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_p_disc=sum(pagos_disc)
label var sum_p_disc "Cumulative discounted sum of payments"

*'sum_porc_p' is the percentage of the cumulative sum of the payments wrt to the loan
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_porc_p=sum_p/prestamo
label var sum_porc_p "Percentage of the cumulative sum of payments"

*'sum_porc_int' is the percentage of the cumulative sum of the interest wrt to the loan
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_porc_int=sum_int/prestamo
label var sum_porc_int "Percentage of the cumulative sum of interest"

*'sum_porc_inc_int' is the percentage of the cumulative sum of the incurred interest wrt to the loan
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_porc_inc_int=sum_inc_int/prestamo
label var sum_porc_inc_int "Percentage of the cumulative sum of incurred interest"

*'sum_porc_inc_fee' is the percentage of the cumulative sum of the incurred fee wrt to the loan
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_porc_inc_fee=sum_inc_fee/prestamo
label var sum_porc_inc_fee "Percentage of the cumulative sum of incurred fee"

*'sum_porc_pay_fee' is the percentage of the cumulative sum of the payed fee wrt to the loan
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_porc_pay_fee=sum_pay_fee/prestamo
label var sum_porc_pay_fee "Percentage of the cumulative sum of payed fee"

*Number of payments at current date
gen dum_pago=(pagos!=0 & pagos!=.)
sort prenda fecha_movimiento HoraMovimiento
by prenda: gen sum_np= sum(dum_pago)
by prenda : replace dum_pago = . if fecha_movimiento[_n]==fecha_movimiento[_n-1]
by prenda: gen sum_visit= sum(dum_pago)

drop dum_pago

label var sum_np "Number of payments at current date"
label var sum_visit "Number of visits at current date"


*Dummy variables indicating the type of movement
gen desempeno=(clave_movimiento==3)
gen abono=(clave_movimiento==1)
gen refrendo=(clave_movimiento==5)
gen refrendo_90=(clave_movimiento==5 & dias_inicio<=90)
gen ventabillete=(clave_movimiento==2)
gen pasealmoneda=(clave_movimiento==6)

*Recidivism
preserve
bysort prenda: egen des_c=max(desempeno)
bysort prenda: egen dias_ultimo_mov = max(dias_inicio)
gen dias_inicio_d=dias_inicio if des_c
bysort prenda: egen dias_al_desempenyo=max(dias_inicio_d)
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
bysort NombrePignorante: gen first_loan_value = prestamo[1]
bysort NombrePignorante: gen first_dias_des = dias_al_desempenyo[1] if !missing(des_c)
gen aux_reincidence_uncond = (fecha_inicial >	first_visit + 75) if !missing(first_product)	
bysort NombrePignorante : egen reincidence_uncond = max(aux_reincidence_uncond)

*Dummy indicating if customer returned after first visit to pawn ANOTHER piece
gen aux_reincidence = (fecha_inicial >	first_visit + 75 & ///
	(inrange(prestamo,first_loan_value*0.975,first_loan_value*1.025)!=1 | first_dias_des>=75)) ///
	if !missing(first_product)	
bysort NombrePignorante : egen reincidence = max(aux_reincidence)

*Dummy indicating if customer returned after first visit BEFORE 30/60/75 days
foreach dy in 30 60 75 {
gen aux_reincidence_bef`dy' = inrange(fecha_inicial, first_visit + 1, first_visit + `dy') ///
	if !missing(first_product)	
bysort NombrePignorante : egen reincidence_bef`dy' = max(aux_reincidence_bef`dy')
}

*Dummy indicating if customer returned after first visit & having recovered first piece
gen aux_reincidence_rec = (fecha_inicial >	first_visit + first_dias_des & ///
	first_dias_des<75) ///
	if !missing(first_product)	
bysort NombrePignorante : egen reincidence_rec = max(aux_reincidence_rec)

*Dummy indicating if customer returned after first visit to pawn second piece
*when first one is NOT recovered yet
gen aux_reincidence_fnr = (fecha_inicial >	first_visit + 75 & ///
	first_dias_des>=75 ) if !missing(first_product)	
bysort NombrePignorante : egen reincidence_fnr = max(aux_reincidence_fnr)


*Dummy indicating if customer received same treatment in reincidence (compared to first visit)
sort NombrePignorante fecha_inicial					
bysort NombrePignorante : gen aux_re_product = t_prod ///
					if aux_reincidence_uncond==1 & aux_reincidence_uncond[_n-1]==0
bysort NombrePignorante : egen reincidence_product = max(aux_re_product) 
bysort NombrePignorante : gen same_prod_reincidence = (first_product==reincidence_product) ///
					if !missing(reincidence)


keep NombrePignorante fecha_inicial reincidence* visit_number num_arms ///
		more_one_arm same_prod_reincidence* first_prenda
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
*'sum_p_c' is the maximum/last cumulative payment 
*'sum_porcp_c'is the maximum/last percentage of payment
*'num_p' is the number of payments 
sort prenda fecha_movimiento HoraMovimiento


by prenda: gen des_c=desempeno[_N]
gen def_c = 1-des_c
by prenda: gen ref_c=refrendo[_N]
by prenda: gen ref_90_c=refrendo_90[_N]
by prenda: gen abo_c=abono[_N]
by prenda: gen vbi_c = ventabillete[_N]
by prenda: gen sum_p_c=sum_p[_N]
by prenda: gen sum_int_c=sum_int[_N]
by prenda: gen sum_inc_int_c=sum_inc_int[_N]
by prenda: gen sum_inc_fee_c=sum_inc_fee[_N]
by prenda: gen sum_pay_fee_c=sum_pay_fee[_N]
by prenda: gen pays_c=(sum_p_c>0) if !missing(sum_p_c)
by prenda: gen sum_pdisc_c=sum_p_disc[_N]
by prenda: egen mn_p_c=mean(sum_p)
by prenda: egen mn_pdisc_c=mean(sum_p_disc)
by prenda: gen sum_porcp_c=sum_porc_p[_N]
by prenda: gen sum_porc_int_c=sum_porc_int[_N]
by prenda: gen sum_porc_inc_int_c=sum_porc_inc_int[_N]
by prenda: gen sum_porc_inc_fee_c=sum_porc_inc_fee[_N]
by prenda: gen sum_porc_pay_fee_c=sum_porc_pay_fee[_N]
by prenda: gen num_p=sum_np[_N]
by prenda: gen num_v=sum_visit[_N]
by prenda: gen pam_c=pasealmoneda[_N]
by prenda: gen dias_primer_pago = dpp[1]
by prenda: gen dias_ultimo_mov = dias_inicio[_N]
gen dias_inicio_d=dias_inicio if des_c
by prenda: gen dias_al_desempenyo=dias_inicio_d[_N]
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
label var ref_90_c "Refrendum 90 days"
label var abo_c "Payment to principal"
label var vbi_c "Venta con Billete"
label var sum_p_c "Cum (total) payments"
label var sum_int_c "Cum (total) interest"
label var sum_inc_int_c "Cum (total) incurred interest"
label var sum_inc_fee_c "Cum (total) incurred fees"
label var sum_pay_fee_c "Cum (total) payed fees"
label var pays_c "Dummy of payment>0"
label var sum_pdisc_c "Cum (total)(discounted) payments"
label var mn_p_c "Mean of payments"
label var mn_pdisc_c "Mean of (discounted) payments"
label var sum_porcp_c "Percentage of payment"
label var sum_porc_int_c "Percentage of interest"
label var sum_porc_inc_int_c "Percentage of incurred interest"
label var sum_porc_inc_fee_c "Percentage of incurred fees"
label var sum_porc_pay_fee_c "Percentage of payed fees"
label var num_p "Number of payment"
label var pam_c "Pase al moneda"
label var ref_default "Refrendum but default"
label var pos_pay_default "Positive payment but default"
label var pos_pay_120_def_c "Positive payment (after 120dd) but default"
label var zero_pay_default "Selled pawn"
label var pay_30_default "Payment of at least 30pp but default"


	*Fee dummy 
gen fee = (sum_porc_pay_fee_c>0) if inlist(producto,2,5)
label var fee "Charged late fee - dummy"


********************************************************************************
*							Measures of cost								   *
********************************************************************************
	
*Financial cost
gen fc_admin = sum_p_c + prestamo/(0.7)
replace fc_admin = fc_admin - prestamo/(0.7) if des_c == 1
gen log_fc_admin = log(1+fc_admin)
label var fc_admin "Financial cost (appraised value)"

	*cost of losing pawn
gen cost_losing_pawn = prestamo/(0.7)
replace cost_losing_pawn = cost_losing_pawn - prestamo/(0.7) if des_c == 1

	*discounted 
gen fc_admin_disc = sum_pdisc_c + prestamo/(0.7)
replace fc_admin_disc = fc_admin_disc - prestamo/(0.7*(1+0.002257833358012379025857)^dias_al_desempenyo) if des_c == 1
gen log_fc_admin_disc = log(1+fc_admin_disc)


*APR
gen double apr = sum_porcp_c + 1/0.7
replace apr = apr - 1/0.7 if des_c == 1
	*annualize *solution to : apr/3 = x(1+x)^3/((1+x)^3-1)
replace apr = apr/3
gen double sqrt3 =  (2*apr^3 + 9*apr^2 + 3*sqrt(3)*sqrt(3*apr^4 + 14*apr^3 + 27*apr^2) + 27*apr)^(1/3)
replace apr = sqrt3/(3*2^(1/3)) - (2^(1/3)*(-apr^2 - 3*apr))/(3*sqrt3) + (apr - 3)/3
replace apr = apr*12*100
drop if missing(apr)
drop sqrt3
label var apr "APR (appraised value)"

*Calculate a version of this that doesn't include the interest that is mechanically saved by paying early since this is the piece of the forced-fee contract that has a foregone liquidity cost for the borrower.
gen apr_noint = sum_porcp_c - sum_porc_int_c + 1/0.7
replace apr_noint = apr_noint - 1/0.7 if des_c == 1
	*annualize
replace apr_noint = apr_noint/3
gen double sqrt3 =  (2*apr_noint^3 + 9*apr_noint^2 + 3*sqrt(3)*sqrt(3*apr_noint^4 + 14*apr_noint^3 + 27*apr_noint^2) + 27*apr_noint)^(1/3)
replace apr_noint = sqrt3/(3*2^(1/3)) - (2^(1/3)*(-apr_noint^2 - 3*apr_noint))/(3*sqrt3) + (apr_noint - 3)/3
replace apr_noint = apr_noint*12*100
drop sqrt3
label var apr_noint "APR without interests"


********************************************************************************

*Suc by day
egen suc_x_dia=group(suc fecha_inicial)

*Number of pledges by suc and day
gen dow=dow(fecha_inicial)
gen weekday=inlist(dow,1,2,3,4,5)
preserve
*Pledges only
keep if clave_movimiento == 4 
duplicates drop prenda, force
bysort suc_x_dia t_prod: gen num=_n
bysort suc_x_dia t_prod: egen num_empenio=max(num)
*# pawns at the item level
gen num_empenio_prenda = num_empenio
bysort suc_x_dia t_prod: replace num_empenio=. if num!=num_empenio

keep num_empenio num_empenio_prenda prenda 
tempfile temp_emp
save `temp_emp'
restore

merge m:1 prenda using `temp_emp', nogen



*******************************************************************
*Panel data
save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2", replace
sort prenda fecha_inicial fecha_movimiento t_prod
by prenda fecha_inicial: keep if _n==1
*Final Cross-section
save "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", replace
	
