
use "$directorio/DB/Master.dta", clear

* SS % of people lacking utilities and basic services
* In the last six months, did you need money to pay...?
rename renta Rent
rename comida Food
rename medicina Medicine
rename luz Electricity
rename gas Gas
rename telefono Telephone
rename agua Water


graph bar Rent Food Medicine Electricity Gas Telephone Water, scheme(s2mono) graphregion(color(white)) ///
	ytitle("Percentage")  legend(off) bargap(50) blabel(name)
graph export "$directorio\Figuras\perc_utilities.pdf", replace
	
********************************************************************************

*Histograms of distance/cost of arrival
preserve
xtile perc_c = c_trans, nq(100)
xtile perc_t = t_llegar, nq(100)
keep if inrange(perc_c,2,90) & inrange(t_llegar,2,90)
keep c_trans t_llegar
scatter c_ t_  
export delimited using "$directorio\MATLAB\cost_time.csv", replace novarnames
restore

*Histograms of financial cost (log)
preserve
keep log_fc_admin log_fc_survey
keep if !missing(log_fc_a) & !missing(log_fc_s)
scatter log_fc_*  
export delimited using "$directorio\MATLAB\logfc.csv", replace novarnames
restore

*Histograms of financial cost
preserve
keep fc_admin fc_survey
keep if !missing(fc_a) & !missing(fc_s)
xtile perc_a = fc_a, nq(100)
xtile perc_s = fc_s, nq(100)
keep if inrange(perc_a,0,98) & inrange(perc_s,0,98)
scatter fc_*  
export delimited using "$directorio\MATLAB\fc.csv", replace novarnames
restore
