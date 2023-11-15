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
drop if suc==3 & fecha_inicial==date("02/19/2013","MDY")
collapse (sum) num* (min) t_prod, by(suc fecha_inicial)


sort suc fecha_inicial, stable

by suc : gen aft_ = missing(t_producto) & !missing(t_producto[_n-1]) 
by suc : gen after = sum(aft_)
by suc : gen before = (after==0 & missing(t_producto))
gen exp = !missing(t_prod)

by suc : egen mx = max(num_pawns)
by suc : egen mn = min(num_pawns)

by suc : gen experiment_area = mx if after==0 & before==0
by suc : replace experiment_area = mn if missing(experiment)

by suc : egen fd = min(fecha_inicial) if !missing(t_prod)
by suc : egen first_date = min(fd)
format first_date %td
by suc : egen ld = max(fecha_inicial) if !missing(t_prod)
by suc : egen last_date = min(ld)
format last_date %td

gen running_before = fecha_inicial - first_date
gen running_after = fecha_inicial - last_date
********************************************************************************


twoway (area experiment_area fecha_inicial if exp==1, fcolor(gs10%50) lcolor(gs12%90)) (line num_pawns fecha_inicial, color(navy)) (line num_borrowers fecha_inicial, color(maroon)), by(suc, cols(3) note("")) xlabel(,angle(vertical)) xtitle("") legend(order(2 "# pawns" 3 "# borrowers") rows(1))
graph export "$directorio/Figuras/after_before_bal.pdf", replace

rd_plot num_pawns running_before, cutoff(0) p(1) q(2) kernel(triangular) bwselect(mserd) vce(nncluster suc 5) level(99) xtitle("Days after experiment start") ytitle("# pawns")
graph export "$directorio/Figuras/rd_before_pawns.pdf", replace

rd_plot num_pawns running_after, cutoff(0) p(1) q(2) kernel(triangular) bwselect(mserd) vce(nncluster suc 5) level(99) xtitle("Days after experiment ends") 
graph export "$directorio/Figuras/rd_after_pawns.pdf", replace

rd_plot num_borrowers running_before, cutoff(0) p(1) q(2) kernel(triangular) bwselect(mserd) vce(nncluster suc 5) level(99) xtitle("Days after experiment start") ytitle("# borrowers") 
graph export "$directorio/Figuras/rd_before_borr.pdf", replace

rd_plot num_borrowers running_after, cutoff(0) p(1) q(2) kernel(triangular) bwselect(mserd) vce(nncluster suc 5) level(99) xtitle("Days after experiment ends") 
graph export "$directorio/Figuras/rd_after_borr.pdf", replace


eststo clear
foreach var of varlist num_pawns num_borrowers {
	eststo : reg `var' before after c.fecha_inicial  i.suc, cluster(suc)
	eststo : reg `var' before after c.fecha_inicial##c.fecha_inicial i.suc , cluster(suc)
	eststo : reg `var' before after c.fecha_inicial##c.fecha_inicial##c.fecha_inicial i.suc , cluster(suc)
}

esttab using "$directorio/Tables/reg_results/num_pawns_bal.csv", se r2 ${star} b(a2)  replace 
