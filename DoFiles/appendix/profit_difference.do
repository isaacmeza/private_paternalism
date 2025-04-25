
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Sept. 14, 2024
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Profit calculation

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear

*Define FC and Pr values
reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su fc_admin if e(sample) & t_prod==1

scalar FC1 = `r(mean)'
scalar FC2 = FC1 + _b[2.t_prod]

reg reincidence i.t_prod if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
su reincidence if e(sample) & t_prod==1

scalar Pr1 = `r(mean)'
scalar Pr2 = Pr1 + _b[2.t_prod]


di Pr1
di Pr2
di FC1
di FC2
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

*Create expanded list of delta values and T values (T = 0 to 10)
local delta_values 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 
local T_values 0 1 2 3 4 5 6 7 8 9 10

*Prepare data for CSV using a loop
gen Delta = .
gen T = .
gen Difference = .


// Counter for observation numbers
local obs = 0

foreach delta of local delta_values {
    foreach T of local T_values {
        // Initialize sums
        scalar control = 0
        scalar mandatory = 0

        // Calculate the sums for each T
        forvalues t = 0/`T' {
            scalar control = control + (`delta'^`t') * (Pr1^`t') * FC1
            scalar mandatory = mandatory + (`delta'^`t') * (Pr2^`t') * FC2
        }

        // Calculate the difference
        scalar difference = (mandatory - control)/control

        // Add new observation
        local obs = `obs' + 1
        replace Delta = `delta' in `obs'
        replace T = `T' in `obs'
        replace Difference = difference in `obs'
    }
}

// Save the dataset
*save "difference_delta_T_data.dta", replace

// Generate the plot with lines for each Delta value
twoway (line Difference T if inrange(Delta,0.05,0.15), lcolor(gs15)) ///
       (line Difference T if inrange(Delta,0.15,0.25), lcolor(gs14)) ///
       (line Difference T if inrange(Delta,0.25,0.35), lcolor(gs12)) ///
       (line Difference T if inrange(Delta,0.35,0.45), lcolor(gs10)) ///
       (line Difference T if inrange(Delta,0.45,0.55), lcolor(gs8)) ///
       (line Difference T if inrange(Delta,0.55,0.65), lcolor(gs6)) ///
       (line Difference T if inrange(Delta,0.65,0.75), lcolor(gs4)) ///
       (line Difference T if inrange(Delta,0.75,0.85), lcolor(gs2)) ///
       (line Difference T if inrange(Delta,0.85,0.95), lcolor(gs1)), ///
       title("") ///
	   ytitle("Profit difference %") ///
       xlabel(0(1)10) ylabel(, angle(horizontal)) ///
       legend(order(1 "{&delta} = 0.1" 2 "{&delta} = 0.2" 3 "{&delta} = 0.3" 4 "{&delta} = 0.4" 5 "{&delta} = 0.5" 6 "{&delta} = 0.6" 7 "{&delta} = 0.7" 8 "{&delta} = 0.8" 9 "{&delta} = 0.9"))
graph export "$directorio\Figuras\profit_mandatory_control.pdf", replace
