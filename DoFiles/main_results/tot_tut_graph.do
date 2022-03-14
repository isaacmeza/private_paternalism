
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	March. 14, 2022
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: ToT-TuT figure

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)
local rep = 10000

* Rescale to positive scale (benefits)
gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr des_c eff_cost_loan pay_default choose_commitment t_prod suc_x_dia $C0

********************************************************************************
	*Outcomes
su apr if t_prod==1
gen EY0 = `r(mean)'
su apr if t_prod==2
gen EY1 = `r(mean)'
su apr if t_prod==4
gen EY2 = `r(mean)'

	*Choosers rate
su choose_commitment	
local p = `r(mean)'

	*Treated outcome on Choosers
su apr if t_prod==4 & choose_commitment==1
gen ToC = `r(mean)'
	*Untreated outcome on Choosers
su apr if t_prod==4 & choose_commitment==0
gen UoC = (EY0-`r(mean)'*(1-`p'))/`p'
	*Treated outcome on Non-Choosers
su apr if t_prod==4 & choose_commitment==1
gen ToNC = (EY1-`r(mean)'*`p')/(1-`p')
	*Untreated outcome on Non-Choosers
su apr if t_prod==4 & choose_commitment==0
gen UoNC = `r(mean)'

local p = round(`p',.01)
********************************************************************************
*TOT-TUT graph

* Aux graph vars
gen choosers = _n/100 if inrange(_n,1,`p'*100)
gen nchoosers = _n/100 if inrange(_n,`p'*100,101)
gen nn = _n/100 if inrange(_n,1,`p'*200) 

	*location
gen tot = .05 if _n==5
gen tut = .90 if _n==90

	*selection bias location
gen sb = -.01 if _n==5
	*selection heterogeneity location
gen sh = .17 if _n==17


twoway (scatter ToC choosers if !inrange(_n,4,6), msymbol(X) mcolor(navy)) ///
	(scatter UoC choosers if !inrange(_n,4,6), msymbol(Oh) mcolor(maroon)) ///
	(scatter ToNC nchoosers if !inrange(_n,89,91) & !inrange(_n,16,18), msymbol(+) mcolor(navy)) ///
	(scatter UoNC nchoosers if !inrange(_n,89,91), msymbol(Sh) mcolor(maroon)) ///
	(line EY0 nn, color(maroon%75)) ///
	(line EY1 nn, color(navy%75)) ///
	(line EY2 nn, color(black%75)) ///
	(scatteri `=(ToC+UoC)/2' .06 "ToT = `=round(ToC-UoC)'" `=(ToNC+UoNC)/2' .91 "TuT = `=round(ToNC-UoNC)'", msymbol(i) mlabcolor(black)) ///
	(scatteri `=(ToC+ToNC)/2' .17 (3) "SH = `=round(ToC-ToNC)'" `=(UoC+UoNC)/2' -.01 (9) "SB = `=round(UoNC-UoC)'", msymbol(i) mlabcolor(black) msize(tiny)) ///	
	(rcap ToC UoC tot, color(black)) ///
	(rcap ToNC UoNC tut, color(black)) ///
	(rcap ToC ToNC sh, color(gs10) xaxis(2)) ///
	(rcap UoC UoNC sb, color(gs10)) ///
	, xlabel(-.135 " " 0 "0" `p' "p = `p'" 1, axis(1)) /// 
	 xlabel(-.135 " " 0 " " `=`p'/2' "Choosers" `p' " " 0.75 "Non-choosers" 1 " ", axis(2)) /// 
	 xtitle(" ", axis(2)) ///
	graphregion(color(white)) legend(order(1 "E[Y{subscript:1} | C=1]" 2 "E[Y{subscript:0} | C=1]" 3 "E[Y{subscript:1} | C=0]" 4 "E[Y{subscript:0} | C=0]" 5 "E[Y | Z{subscript:0}]" ///
	6 "E[Y | Z{subscript:1}]" 7 "E[Y | Z{subscript:2}]") rows(2) size(small)) ///
	ytitle("APR (benefit)" " ") 
graph export "$directorio\Figuras\tot_tut_apr.pdf", replace	
	