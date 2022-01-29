/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: January. 28, 2022
* Modifications: 
* Files used:     
		- num_pawns_suc_dia.dta 
* Files created:  

* Purpose: To this end we estimated the regression\footnote{We cluster the standard errors by branch.} $Pawns \: per \: day_{jt} = \alpha_j + \gamma f(t) + \beta_b \mathbbm{1}(t \in MB)_{t} +\beta_a \mathbbm{1}(t \in MA)_{t}$

*******************************************************************************/
*/

use "$directorio/_aux/num_pawns_suc_dia.dta", clear


gen before = inrange(fecha_inicial,date("08/05/2012","MDY"),date("09/05/2012","MDY"))
replace before = . if fecha_inicial<date("08/05/2012","MDY")

gen after = .

replace after = inrange(fecha_inicial,date("09/30/2012","MDY"),date("10/30/2012","MDY")) ///
	if suc==3 & fecha_inicial<=date("10/30/2012","MDY")

replace after = inrange(fecha_inicial,date("10/2/2012","MDY"),date("11/2/2012","MDY")) ///
	if suc==5 & fecha_inicial<=date("11/2/2012","MDY")
	
replace after = inrange(fecha_inicial,date("12/23/2012","MDY"),date("1/23/2013","MDY")) ///
	if suc==42 & fecha_inicial<=date("1/23/2013","MDY")
	
replace after = inrange(fecha_inicial,date("12/25/2012","MDY"),date("1/25/2013","MDY")) ///
	if suc==78 & fecha_inicial<=date("1/25/2013","MDY")
	
replace after = inrange(fecha_inicial,date("12/25/2012","MDY"),date("1/25/2013","MDY")) ///
	if suc==80 & fecha_inicial<=date("1/25/2013","MDY")
	
replace after = inrange(fecha_inicial,date("12/25/2012","MDY"),date("1/25/2013","MDY")) ///
	if suc==104 & fecha_inicial<=date("1/25/2013","MDY")

*

eststo clear
	
eststo : reg num_empenio_sucdia before after  i.suc, cluster(suc)
eststo : reg num_empenio_sucdia before after c.fecha_inicial  i.suc, cluster(suc)
eststo : reg num_empenio_sucdia before after c.fecha_inicial##c.fecha_inicial i.suc , cluster(suc)
eststo : reg num_empenio_sucdia before after c.fecha_inicial##c.fecha_inicial##c.fecha_inicial i.suc , cluster(suc)

esttab using "$directorio/Tables/reg_results/num_pawns_bal.csv", se r2 ${star} b(a2)  replace 
