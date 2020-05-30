clear all
set more off


local dep_var pago_frec_vol_fee pago_frec_vol pago_frec_vol_promise

foreach x in  "pago_frec_vol_fee" "pago_frec_vol" "pago_frec_vol_promise"{
	import delimited "$directorio\_aux\pred_`x'.csv", clear
	tempfile temp_rf_pred
	save `temp_rf_pred'

	import delimited "$directorio\_aux\data_pfv.csv", clear 
	merge 1:1 nombrepignorante prenda using `temp_rf_pred', ///
		keepusing(rf_pred) keep(3)
		
	do "$directorio\DoFiles\AUX_take_up.do" `x'
}
