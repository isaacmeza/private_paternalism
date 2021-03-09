************************************************
***Code to label yaxis in kdensity with percentage
*********************************

/*USE:

do "$directorio\DoFiles\main_results\yaxis_kdensity.do" ///
 var width esample name
	
*/

args var  	  /*Variable to obtain kdensity*/  ///
	 width	  /*Width of bins in histogram*/  ///
	 esample  /*Variable that encodes wich subsample to work with*/ ///
	 name     /*Name of yaxis as a global variable*/
	 
*********************************

*This part of the code recovers the maximum value of yaxis
qui su `var' if `esample'==1 & !missing(`var')

local n_bins=round((`r(max)'-`r(min)')/`width')
local min=`r(min)'
local cuts= `min'

forvalues i=1/`n_bins' {
	local partition=`min'+`width'*`i'
	local cuts=" `cuts', `partition'"
	}

cap drop dist_cuts
egen dist_cuts = cut(`var') if `esample'==1 & !missing(`var'), at(`quote' `cuts' `quote')
cap drop moda
qui egen moda=mode(dist_cuts)
cap drop porc_max
gen porc_max = (dist_cuts==moda) if `esample'==1 & !missing(`var')
qui su porc_max
local max_yaxis=round(`r(mean)'*100)
local step_size=round(`max_yaxis'/5)

*Re-escale
local factor=`width'*100

*Generate yaxis labels
mylabels 0(`step_size')`max_yaxis', myscale(@/`factor') local(lab_porc)

local nombre="`name'"
global `nombre' `lab_porc'

************************************************
