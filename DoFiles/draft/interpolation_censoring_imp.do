
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Jan. 22, 2023
* Last date of modification: 
* Modifications: (Need to add uncertainty quantification)
* Files used:     
		- 
* Files created:  

* Purpose: Interpolation for imputation of censored (not observed final default status) loans with extreme cases.

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
set seed 1

drop fc_admin cost_losing_pawn downpayment_capital apr

gen def_imp = .
gen des_imp = .

gen unif1 = .
gen unif2 = .

local reps = 500

matrix pvalue_apr = J(`reps', `reps', 0) 
matrix pvalue_def_imp = J(`reps', `reps', 0) // empty matrix for pvalues

matrix te_apr_c0 = J(`reps', 5, 0) 
matrix te_def_imp_c0 = J(`reps', 5, 0) // empty matrix for treatment effects when C=0 and running imputation in T
//  3 cols are: (1) beta, (2) low ci, (3) high ci, 

matrix te_apr_t1 = J(`reps', 5, 0) 
matrix te_def_imp_t1 = J(`reps', 5, 0) // empty matrix for treatment effects when T=1 and running imputation in C
//  3 cols are: (1) beta, (2) low ci, (3) high ci, 



replace unif1 = runiform() if t_prod==1 & concluyo_c==0 
replace unif2 = runiform() if t_prod==2 & concluyo_c==0 


local k = 1
forvalues i = 1/`reps' {
	forvalues j = 1/`reps' {
	qui {	
	if `j'==1 & `i'==1 {	
		noi di " "
		noi _dots 0, title(Number of iteration) reps(`=`reps'*`reps'')
	}
	
	preserve	
	*Imputation
			*Default/Recovery
	replace def_imp = def_c
	replace def_imp = (unif1>`j'/`reps') if t_prod==1 & concluyo_c==0 
	replace def_imp = (unif2<=`i'/`reps') if t_prod==2 & concluyo_c==0
	replace des_imp = 1-def_imp


		*Days towards def/rec
	replace dias_al_default = dias_ultimo_mov if concluyo_c==0 & def_imp==1
	replace dias_al_default = 105 if dias_ultimo_mov<90 & concluyo_c==0 & def_imp==1
	replace dias_al_default = 210 if inrange(dias_ultimo_mov, 110, 180) & concluyo_c==0 & def_imp==1
	replace dias_al_default = 315 if inrange(dias_ultimo_mov, 220, 270) & concluyo_c==0 & def_imp==1
	replace dias_al_default = 420 if dias_ultimo_mov>315 & concluyo_c==0 & def_imp==1
	replace dias_al_desempenyo = dias_ultimo_mov if concluyo_c==0 & des_imp==1


		*Payment if imputed recovery
	replace sum_p_c = prestamo + sum_inc_int if concluyo_c==0 & des_imp==1


		*Interest if imputed recovery
	replace sum_int_c = sum_inc_int if concluyo_c==0 & des_imp==1 		


		*Financial cost
	gen double fc_admin = .
			*Only fees and interest for recovered pawns
	replace fc_admin = sum_int_c + sum_pay_fee_c if des_imp==1
			*All payments + appraised value when default
	replace fc_admin = sum_p_c + prestamo_i/(0.7) if def_imp==1

		*cost of losing pawn
	gen double cost_losing_pawn = 0
	replace cost_losing_pawn = sum_p_c - sum_int_c - sum_pay_fee_c + prestamo_i/(0.7) if def_imp==1

		*Downpayment
	gen double downpayment_capital = 0
	replace downpayment_capital = sum_p_c - sum_int_c - sum_pay_fee_c if def_imp==1

		*APR
	gen double apr = (1 + (fc_admin/prestamo)/dias_al_desempenyo)^dias_al_desempenyo - 1  if des_imp==1
	replace apr = (1 + (fc_admin/prestamo)/dias_al_default)^dias_al_default - 1  if def_imp==1
	
*-------------------------------------------------------------------------------
	
	foreach var in def_imp apr {
			*OLS 
		 reg `var' i.t_prod $C0 if inlist(t_prod,1,2), vce(cluster suc_x_dia)
		local df = e(df_r)	
		
		// p-value 
		matrix pvalue_`var'[`i',`j'] = 2*ttail(`df', abs(_b[2.t_prod]/_se[2.t_prod]))
		
		if `j'==`reps' {
			// beta
			matrix te_`var'_c0[`i',1] = _b[2.t_prod]
			// low ci
			matrix te_`var'_c0[`i',2] = _b[2.t_prod] - invttail(`df',.05/2)*_se[2.t_prod]
			matrix te_`var'_c0[`i',4] = _b[2.t_prod] - invttail(`df',.10/2)*_se[2.t_prod]
			// high ci
			matrix te_`var'_c0[`i',3] = _b[2.t_prod] + invttail(`df',.05/2)*_se[2.t_prod]
			matrix te_`var'_c0[`i',5] = _b[2.t_prod] + invttail(`df',.10/2)*_se[2.t_prod]
		}
		
		if `i'==`reps' {
			// beta
			matrix te_`var'_t1[`j',1] = _b[2.t_prod]
			// low ci
			matrix te_`var'_t1[`j',2] = _b[2.t_prod] - invttail(`df',.05/2)*_se[2.t_prod]
			matrix te_`var'_t1[`j',4] = _b[2.t_prod] - invttail(`df',.10/2)*_se[2.t_prod]
			// high ci
			matrix te_`var'_t1[`j',3] = _b[2.t_prod] + invttail(`df',.05/2)*_se[2.t_prod]
			matrix te_`var'_t1[`j',5] = _b[2.t_prod] + invttail(`df',.10/2)*_se[2.t_prod]		
		}
	}
	}
*-------------------------------------------------------------------------------	
	
	noi _dots `k' 0
	local k = `k' + 1
	
	restore		
	}
}

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------


clear
svmat pvalue_apr 
svmat pvalue_def_imp 
svmat te_apr_c0 
svmat te_def_imp_c0 
svmat te_apr_t1 
svmat te_def_imp_t1 
save "$directorio/_aux/frontier_sig.dta", replace	
 
use "$directorio/_aux/frontier_sig.dta", clear	
local reps = 500
gen n = _n/`reps'*100

foreach var in def_imp apr {
	preserve
	gen frontera_sig_10= .
	gen frontera_sig_5 = .
	gen frontera_sig_1 = .


	forvalues k = 1/`reps' {
		foreach s in 1 5 10 {
			gen csum_aux = sum(pvalue_`var'`k' < `s'/100) 	
			egen mx_val = max(csum_aux)
			replace frontera_sig_`s' = mx_val/`reps'*100 in `k'
			drop csum_aux mx_val
		}
	 }


	set obs `=`reps' + 2'
	replace n = 0 if missing(n) & _n==`=`reps' + 1'
	replace n = 100 if missing(n)
	sort n, stable

	replace frontera_sig_10 = 100 if missing(frontera_sig_10) & n==0
	replace frontera_sig_5 = 100 if missing(frontera_sig_5) & n==0
	replace frontera_sig_1 = 100 if missing(frontera_sig_1) & n==0
	replace frontera_sig_10 = 0 if missing(frontera_sig_10)
	replace frontera_sig_5 = 0 if missing(frontera_sig_5)
	replace frontera_sig_1 = 0 if missing(frontera_sig_1)
	 
	*Marker for lasso logit imputation
	gen mkr2 = 42.57 in 1
	gen mkr1 = 46.58 in 1


	*Frontier significance graph
	twoway (scatter frontera_sig_10 n, connect(line) sort msymbol(none)) ///
		(scatter frontera_sig_5 n, connect(line) sort msymbol(none)) ///
		(scatter frontera_sig_1 n, connect(line) sort msymbol(none)) ///
		(scatter mkr1 mkr2, msymbol(X) msize(medlarge) mlw(medium)), ///
		text(0 0 "C", place(ne)) text(0 100 "A", place(nw)) text(100 100 "B", place(sw)) text(100 0 "D", place(se)) ///
		legend(order(1 "10%" 2 "5%" 3 "1%") pos(6) rows(1)) ytitle("% imputation default T=1") xtitle("% imputation C=0") name(frontera, replace) 
	graph export "$directorio/Figuras/frontera_sig_`var'.pdf", replace
	
	restore
}