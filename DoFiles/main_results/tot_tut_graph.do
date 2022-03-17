
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
gen EY0_l = 11
gen EY0_c = 13
gen EY0_h = 15
su apr if t_prod==2
gen EY1 = `r(mean)'
gen EY1_l = 29
gen EY1_c = 31
gen EY1_h = 33
su apr if t_prod==4
gen EY2 = `r(mean)'
gen EY2_l = 1
gen EY2_c = 3
gen EY2_h = 5 
	*Choosers rate
su choose_commitment	
local p = `r(mean)'

	*Treated outcome on Choosers
su apr if t_prod==4 & choose_commitment==1
gen ToC = `r(mean)'
	*Auxiliar variables to graph
gen ToC_ = 42
	*Untreated outcome on Choosers
su apr if t_prod==4 & choose_commitment==0
gen UoC = (EY0-`r(mean)'*(1-`p'))/`p'
gen UoC_ = 79
	*Treated outcome on Non-Choosers
su apr if t_prod==4 & choose_commitment==1
gen ToNC = (EY1-`r(mean)'*`p')/(1-`p')
gen ToNC_ = 28.7
	*Untreated outcome on Non-Choosers
su apr if t_prod==4 & choose_commitment==0
gen UoNC = `r(mean)'
gen UoNC_ = 0

local p_ = .25
********************************************************************************
*TOT-TUT graph

* Aux graph vars
gen choosers = _n/100 if inrange(_n,1,`p_'*100)
gen nchoosers = _n/100 if inrange(_n,`p_'*100,101)
gen nn = _n/100 if inrange(_n,1,101) 
gen nn_ = _n/100 if inrange(_n,1,`p_'*100) 

	*location
gen tot = .05 if _n==1
gen tot_hl = .01
gen tot_hh = `p_'-.01
gen tot_a = 16

gen tut = .90 if _n==1
gen tut_hl = `p_'+.01
gen tut_hh = .99
gen tut_a = 6

gen itt_f = -.025 if _n==1
gen itt_c = -.05 if _n==1


twoway (scatter ToC_ choosers if !inrange(_n,3,7), msymbol(+) msize(medium) mcolor(navy)) ///
	(scatter UoC_ choosers if !inrange(_n,3,7), msymbol(Sh) msize(small) mcolor(gs5)) ///
	(scatter ToNC_ nchoosers if !inrange(_n,88,92), msymbol(X) msize(medium) mcolor(navy)) ///
	(scatter UoNC_ nchoosers if !inrange(_n,88,92), msymbol(Oh) msize(small) mcolor(gs5)) ///
	(rarea EY0_h EY0_l nn, fcolor(gs15%30) lcolor(black) lwidth(medthick)) ///
	(rarea EY0_h EY0_l nn_, fcolor(gs15%30) lcolor(black) lwidth(medthick)) ///
	(rarea EY1_h EY1_l nn, fcolor(navy%30) lcolor(navy) lwidth(medthick)) ///
	(rarea EY1_h EY1_l nn_, fcolor(navy%30) lcolor(navy) lwidth(medthick)) ///	
	(rarea EY2_h EY2_l nn, fcolor(gs16%30) lcolor(maroon) lwidth(medthick)) ///
	(rarea EY2_h EY2_l nn_, fcolor(maroon%30) lcolor(maroon) lwidth(medthick)) ///
	(rcap ToC_ UoC_ tot, color(black%75)) ///
	(rcap ToNC_ UoNC_ tut, color(black%75)) ///
	(rcap tut_hl tut_hh tut_a, color(black%75) lpattern(dash) horizontal) ///
	(rcap tot_hl tot_hh tot_a, color(black%75) lpattern(dash) horizontal xaxis(2)) ///
	(rcap EY0_c EY2_c itt_c, color(black%75)) ///
	(rcap EY1_c EY0_c itt_f, color(black%75)) ///
	(scatteri 70 .06 "ToT = `=round(ToC-UoC)'" 20 .91 "TuT = `=round(ToNC-UoNC)'", msymbol(i) mlabcolor(gs5)) ///
	(scatteri 19 0 "ToT = ITT{superscript:C}/p" 8 .4 "TuT = (ITT{superscript:F} - ITT{superscript:C})/(1-p)", msymbol(i) mlabcolor(black)) ///
	(scatteri `=(EY2_c+EY0_c)/2' `=itt_c' (9) "ITT{superscript:C} = `=round(EY2-EY0,0.1)'" `=(EY1_c+EY0_c)/2' `=itt_f' (9) "ITT{superscript:F} = `=round(EY1-EY0,0.1)'", msymbol(i) mlabcolor(black)) ///
	, xlabel(-.25 " " 0 "0" `p_' "p = `=round(`p',0.1)'" 1, axis(1)) /// 
	 xlabel(-.25 " " 0 " " `=`p_'/2' "Choosers" `p_' " " 0.75 "Non-choosers" 1 " ", axis(2)) /// 
	 xtitle(" ", axis(2)) ///
	 ylabel(`=UoNC_' "`=round(UoNC)'" `=EY2_c' "`=round(EY2)'" ///
		`=EY0_c' "`=round(EY0)'" `=ToNC_' "`=round(ToNC)'" `=EY1_c' "`=round(EY1)'" ///
		`=ToC_' "`=round(ToC)'" `=UoC_' "`=round(UoC)'" , angle(horizontal) labsize(vsmall) ) ///
	graphregion(color(white)) legend(order(1 "E[Y{subscript:1} | C=1]" 2 "E[Y{subscript:0} | C=1]" 3 "E[Y{subscript:1} | C=0]" 4 "E[Y{subscript:0} | C=0]" ///
	5 "E[Y | Z{subscript:0}]" 8 "E[Y | Z{subscript:1}]" 10 "E[Y | Z{subscript:2}]") rows(2) size(small)) ///
	ytitle("APR (benefit)" " ") 
graph export "C:\Users\isaac\Dropbox\Apps\ShareLaTeX\Donde2020\Figuras\tot_tut_apr.eps", as(eps)  preview(off) replace
