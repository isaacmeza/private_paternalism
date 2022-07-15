
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: May. 09, 2022
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: ToT-TuT analysis 

*******************************************************************************/
*/
clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

*keep if visit_number==1


* Rescale to positive scale (benefits)
gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr des_c eff_cost_loan pay_default choose_commitment t_prod prod suc_x_dia $C0
********************************************************************************

* TOT-TUT using LATE approach
*IV
gen choice_nsq = (prod==5) /*z=2, t=1*/
gen choice_vs_control = (t_prod==4) if inlist(t_prod,1,4) 
gen choice_nonsq = (prod!=4) /*z!=2, t!=0*/
gen forced_fee_vs_choice = (t_prod==2) if inlist(t_prod,2,4)

 
*Stack IV/GMM
gen x1 = -(t_prod==4)*(prod==4)
gen x2 = (t_prod==4)*(prod==5)
gen z0_ = -(t_prod==1)
gen z0 = (t_prod==1)
gen z1 = (t_prod==2)
gen z2 = (t_prod==4)

set seed 54545
sample 10
eststo : ivregress 2sls apr z1 (x2 = z2), vce(cluster suc_x_dia)

eststo : ivregress 2sls apr z1 (x2 = z2)
predict res, res
gen ones = 1

sort suc_x_dia 
mkmat x2 z1 ones, matrix(X1)
mkmat z1 z0 ones, matrix(W)
mkmat apr , matrix(Y)



matrix accum ZPZ = apr x2 z1 ones z1 z0 ones, nocons

matrix WPY = ZPZ[5..7,1]
matrix WPX = ZPZ[2..4,5..7]




matrix WPXi = inv(WPX)
matrix theta1 = (WPXi*WPY)'
mat list theta1


matrix score double xbhat1 = theta1

gen double ress = apr-xbhat1


gen obs = _n
sort obs
sort suc_x_dia
matrix opaccum Szuu = z1 z0, group(suc_x_dia) opvar(res)




matrix cov = inv(W'*X1)*Szuu*inv(X1'*W)
mat list cov






eststo : ivregress 2sls apr z1 (x2 = z2), vce(cluster suc_x_dia)
mat list e(V)
mat list cov


ereturn post theta1 cova
ereturn display

