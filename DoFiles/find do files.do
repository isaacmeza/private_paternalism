*ssc install find
*ssc install rcd
 
*******************************************************************************/
clear
set more off
 
 
rcd "$directorio/DoFiles"  : find *.do , match(pago_frec_volu) show
