
use "$directorio/DB/Master.dta", clear

local alpha = 0.1
  
keep if !missing(fc_admin_disc)	
keep if !missing(pro_2)	

*Median dummies
foreach var of varlist prestamo pr_recup edad {
	su `var', d
	gen `var'_m=(`var'>=`r(p50)') if !missing(`var')
	}	
su faltas, d
gen faltas_m=(faltas>`r(p50)') if !missing(faltas)

		
keep log_fc_admin_disc fc_admin_disc pro_2 ///
	prestamo_m pr_recup_m  edad_m faltas_m /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido OC pb fb hace_presupuesto tentado low_cost low_time
*Constant var
gen one = 1
	
*Reset trick	
mat zero_matrix = J(4*(`c(k)'-3),4,.)
qui putexcel B3=matrix(zero_matrix) using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify	
mat zero_matrix = J(2*(`c(k)'-3),9,.)
qui putexcel F4=matrix(zero_matrix) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify	
	

local i = 3	
local t = 4

forvalues k = 0/1 {
	*Test for log-normality 
	*Shapiro-Wilk
	swilk log_fc_admin_disc if pro_2==`k' 
	local pval_sw = `r(p)'
	qui putexcel B`i'=matrix(`pval_sw') using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify

	*Anderson-Darling
	a2 log_fc_admin_disc if pro_2==`k' , dist(normal)
	qui putexcel C`i'=matrix(${S_4}) using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify

	*Kolmogorov-Smirnov
	su log_fc_admin_disc if pro_2==`k' 
	ksmirnov log_fc_admin_disc = normal((log_fc_admin_disc-`r(mean)')/`r(sd)') if pro_2==`k' 
	local pval_ks = `r(p_cor)'
	qui putexcel D`i'=matrix(`pval_ks') using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify

	local i = `i'+1
}
	

* Log-normal fit
noi mlexp (-ln(sqrt(2)*c(pi))-ln({sigma: one pro_2}) ///
	- 0.5*((log_fc_admin_disc-{mu: one pro_2})/{sigma:})^2) ///
	if !missing(pro_2) 		

count if  !missing(pro_2)
qui putexcel N`t'=matrix(`r(N)') using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	
*Test on sigma param for FOSD
test _b[/sigma_pro_2] = 0
*Equality in sigma param
if `r(p)'>`alpha' {	
	* T/`i'var FOSD C/`i'var
	if _b[/mu_pro_2]<0 {
		qui putexcel J`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	}
	* C/`i'var FOSD T/`i'var
	else {
		qui putexcel L`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	}
}
* SOSD
* T/`i'var SOSD C/`i'var
if _b[/mu_pro_2]<0 & _b[/sigma_pro_2]>=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] <=0) {
	qui putexcel K`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
}
* C/`i'var SOSD T/`i'var
if _b[/mu_pro_2]>0 & _b[/sigma_pro_2]<=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] >=0) {
	qui putexcel M`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
}

		
*Test on mu param for SD
test _b[/mu_pro_2] = 0
*Significant difference in mu param
if `r(p)'<=`alpha' { 
	
	*Test on sigma param for FOSD
	test _b[/sigma_pro_2] = 0
	*Equality in sigma param
	if `r(p)'>`alpha' {
			
		* T/`i'var FOSD C/`i'var
		if _b[/mu_pro_2]<0 {
			qui putexcel F`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
		}
		* C/`i'var FOSD T/`i'var
		else {
			qui putexcel H`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
		}
	}	

	* T/`i'var SOSD C/`i'var
	if _b[/mu_pro_2]<0 & _b[/sigma_pro_2]>=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] <=0) {
		qui putexcel G`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	}
	* C/`i'var SOSD T/`i'var
	if _b[/mu_pro_2]>0 & _b[/sigma_pro_2]<=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] >=0) {
		qui putexcel I`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	}
}

local t = `t'+1

qui {
foreach var of varlist prestamo_m pr_recup_m edad_m faltas_m /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido OC pb fb hace_presupuesto tentado low_cost low_time {
	
	qui putexcel A`i'=("`var'") using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify
	qui putexcel A`t'=("`var'") using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	
	forvalues j = 0/1 {
	noi di "`var'"
	noi di `j'
	
	qui putexcel O`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	count if  `var'==`j'
	qui putexcel N`t'=matrix(`r(N)') using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
	
		forvalues k = 0/1 {
			*Test for log-normality 
				*Shapiro-Wilk
			swilk log_fc_admin_disc if pro_2==`k' & `var'==`j'
			local pval_sw = `r(p)'
			qui putexcel B`i'=matrix(`pval_sw') using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify

				*Anderson-Darling
			a2 log_fc_admin_disc if pro_2==`k' & `var'==`j', dist(normal)
			qui putexcel C`i'=matrix(${S_4}) using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify

				*Kolmogorov-Smirnov
			su log_fc_admin_disc if pro_2==`k' & `var'==`j'
			ksmirnov log_fc_admin_disc = normal((log_fc_admin_disc-`r(mean)')/`r(sd)') if pro_2==`k' & `var'==`j'
			local pval_ks = `r(p_cor)'
			qui putexcel D`i'=matrix(`pval_ks') using "$directorio\Tables\stoch_dominance.xlsx", sheet("test_fit") modify
			
			local i = `i'+1
			}
	

		* Log-normal fit
		noi mlexp (-ln(sqrt(2)*c(pi))-ln({sigma: one pro_2}) ///
			- 0.5*((log_fc_admin_disc-{mu: one pro_2})/{sigma:})^2) ///
			if !missing(pro_2) & `var'==`j'			
		

		*Test on sigma param for FOSD
		test _b[/sigma_pro_2] = 0
		*Equality in sigma param
		if `r(p)'>`alpha' {	
			* T/`i'var FOSD C/`i'var
			if _b[/mu_pro_2]<0 {
				qui putexcel J`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
			}
			* C/`i'var FOSD T/`i'var
			else {
				qui putexcel L`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
			}
		}
		* SOSD
		* T/`i'var SOSD C/`i'var
		if _b[/mu_pro_2]<0 & _b[/sigma_pro_2]>=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] <=0) {
			qui putexcel K`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
		}
		* C/`i'var SOSD T/`i'var
		if _b[/mu_pro_2]>0 & _b[/sigma_pro_2]<=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] >=0) {
			qui putexcel M`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
		}		
		
		*Test on mu param for SD
		test _b[/mu_pro_2] = 0
		*Significant difference in mu param
		if `r(p)'<=`alpha' { 
		
			*Test on sigma param for FOSD
			test _b[/sigma_pro_2] = 0
			*Equality in sigma param
			if `r(p)'>`alpha' {
			
				* T/`i'var FOSD C/`i'var
				if _b[/mu_pro_2]<0 {
					qui putexcel F`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
				}
				* C/`i'var FOSD T/`i'var
				else {
					qui putexcel H`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
				}
				
				* T/`i'var SOSD C/`i'var
				if _b[/mu_pro_2]<0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] <=0) {
					qui putexcel G`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
				}
				* C/`i'var SOSD T/`i'var
				if _b[/mu_pro_2]>0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] >=0) {
					qui putexcel I`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
				}				
			}	
			
			
			* T/`i'var SOSD C/`i'var
			if _b[/mu_pro_2]<0 & _b[/sigma_pro_2]>=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] <=0) {
				qui putexcel G`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
			}
			* C/`i'var SOSD T/`i'var
			if _b[/mu_pro_2]>0 & _b[/sigma_pro_2]<=0 & (_b[/mu_pro_2] + _b[/sigma_one]*_b[/sigma_pro_2] + 0.5*_b[/sigma_pro_2]*_b[/sigma_pro_2] >=0) {
				qui putexcel I`t'=matrix(1) using "$directorio\Tables\stoch_dominance.xlsx", sheet("dominance") modify
			}
		}
	
	
	local t = `t'+1
	}
}	
}


