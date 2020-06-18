clear all
set more off


********************************************************************************

*ADMIN DATA
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", clear
tab producto	

* Number of distinct suc-dia by treatment arms
by t_prod suc_x_dia, sort: gen nvals = _n == 1 
by t_prod: replace nvals = sum(nvals)
by t_prod: replace nvals = nvals[_N] 


*Trimming	
xtile perc = prestamo, nq(100)
replace prestamo=. if perc>=99

orth_out prestamo monday num_empenio nvals, by(t_prod) count se  vce(cluster suc_x_dia) pcompare ///
	 bdec(2) stars
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify
	
local i = 2	
foreach var of varlist prestamo monday num_empenio {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_admin") modify
	local i = `i'+2
	}

********************************************************************************
	
*SURVEY DATA (BASAL)

use "$directorio/DB/master.dta", clear
*Trimming
xtile perc = val_pren, nq(100)
replace val_pren=. if perc>=99

*Response survey dummy
gen response = !missing(genero)

*Reasons
label define reasons 0 "Lost Job" 1 "Sickness" 2 "Urgent Expense" 3 "No Urgent Expense"
label values razon reasons

preserve
drop if missing(razon)

bysort razon: gen razones = _N
gen total_obs = _N

gen propor = 100*razones/total_obs

graph hbar propor, over(razon) ///
 graphregion(color(white)) scheme(s2mono) ///
 ytitle("") ylabel(0 "0" 20 "20%" 40 "40%" 60 "60%" 80 "80%")
 
graph export "$directorio/Figuras/reasons_pawn.pdf", replace

restore


orth_out genero edad  val_pren pres_antes pr_recup masqueprepa response, by(t_prod) se  vce(cluster suc_x_dia) ///
	 bdec(2) stars pcompare
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify

*Count number of surveys

forvalues t = 1/5 {
	count if !missing(genero) & t_prod==`t'
	local obs = `r(N)'
	local Col=substr(c(ALPHA),2*`t'+1,1)
	qui putexcel `Col'16=matrix(`obs') using "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify
	}

local i = 2	
foreach var of varlist genero edad  val_pren pres_antes pr_recup masqueprepa response {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_survey") modify
	local i = `i'+2
	}
		
********************************************************************************

*SURVEY DATA (EXIT)

import excel "$directorio\Raw\EncuestasSatisfaccion.xlsx", sheet("Hoja1") firstrow clear

rename Boleta prenda
keep prenda contrataria satisfaccion sit_econ optaria_mensual si no
duplicates drop prenda, force

merge 1:m prenda using "$directorio/DB/master.dta", keep(3) nogen

*Variables
gen satisfied_esquema_pago = (satisfaccion == 3)
gen sit_econ_mejor = (sit_econ == 1)

*** GRAPH REINCIDENCIA **

/* Si contenstó que sí
A) Los pagos mensuales me ayudan a organizar mis gastos
B) b.	Los pagos mensuales me ayudan para evitar gastos que no debo hacer 
C) c.	Con los pagos mensuales, es más fácil no prestarle dinero a familiares o amigos 
D) d.	Me cobran menos intereses que pagando al final del préstamo 

Si contestó que no:
a.	No puedo comenzar a pagar en un mes después del préstamo ______
b.	Me cuesta demasiado tiempo y dinero venir cada mes a pagar ______ 
c.	Me parece que me cobran más con los pagos mensuales, por eso prefiero un solo pago al final del préstamo ____


*/

label define si 1 "A"  2 "B" ///
	3 "C" 4 "D" 5 "AB" 6 "AC" /// 
	7 "AD"  8 "BC" 9 "BD"  ///
	10 "CD" 11 "ABC" 12 "ADC" ///
	13 "BDC" 14 "Todas"            

label define no 1 "A" 2 "B" ///
	3 "C" 4 "AB" 5 "AC" ///
	6 "BC" 7 "Todas"              

lab values si si
lab values no no

keep prenda si no

*Por separado

*SÍ
gen A = si == 1 | si == 5 | si == 6 | si == 7 | si == 11 ///
| si == 12 | si == 14 

gen B = si == 2 | si == 5 | si == 8 | si == 9 | si == 11 ///
| si == 13 | si == 14 

gen C = si == 3 | si == 6 | si == 8 | si == 10 | si == 11 ///
| si == 12 | si == 13 | si == 14 

gen D = si == 4 | si == 7 | si == 9 | si == 10 | si == 12 ///
| si == 13 | si == 14 

*NO 
gen A_n = no == 1 | no == 4 | no == 5 | no == 7
gen B_n = no == 2 | no == 4 | no == 6 | no == 7
gen C_n = no == 3 | no == 5 | no == 6 | no == 7

gen respuesta = 1 if A == 1
replace respuesta = 2 if B == 1
replace respuesta = 3 if C == 1
replace respuesta = 4 if D == 1

gen respuesta_n = 1 if A_n == 1
replace respuesta_n = 2 if B_n == 1
replace respuesta_n = 3 if C_n == 1

bysort respuesta: gen contador = _N
gen aux = 1 if si != .  
egen total_respuesta = sum(aux)
replace contador = contador/total_respuesta

bysort respuesta_n: gen contador_n = _N
gen aux_n = 1 if no != .  
egen total_respuesta_n = sum(aux_n)
replace contador_n = contador_n/total_respuesta_n

label define sii 1 "Help me to organize better" /// 
2 "I avoid unnecesary expenses" /// 
3 "I avoid lend money to family" ///
 4 "I pay less interest at the end"
label values  respuesta sii

label define noo 1 "Cannot pay a month after" /// 
2 "Too much time and money to come to pay" /// 
3 "Charges are higher" 
label values  respuesta_n noo

graph hbar contador, over(respuesta) ///
 graphregion(color(white)) scheme(s2mono)  ///
 ytitle("") ylabel(0 "0" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%")

graph export "$directorio/Figuras/razones_si.pdf", replace


graph hbar contador_n, over(respuesta_n) ///
 graphregion(color(white)) scheme(s2mono) ///
 ytitle("") ylabel(0 "0" .1 "10%" .2 "20%" .3 "30%" .4 "40%")

graph export "$directorio/Figuras/razones_no.pdf", replace

*Trimming
xtile perc = val_pren, nq(100)
replace val_pren=. if perc>=99
cap drop perc
xtile perc = prestamo, nq(100)
replace prestamo=. if perc>=99

orth_out contrataria satisfied_esquema_pago sit_econ_mejor optaria_mensual ///
	prestamo genero edad  val_pren pres_antes pr_recup masqueprepa , by(t_prod) count se  vce(cluster suc_x_dia) ///
	 bdec(2) stars pcompare
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\SS.xlsx", sheet("SS_survey_exit") modify


local i = 2	
foreach var of varlist contrataria satisfied_esquema_pago sit_econ_mejor optaria_mensual ///
	prestamo genero edad  val_pren pres_antes pr_recup masqueprepa {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\SS.xlsx", sheet("SS_survey_exit") modify
	local i = `i'+2
	}	
