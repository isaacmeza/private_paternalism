*ssc install find
*ssc install rcd
 
*******************************************************************************/
clear
set more off
 
 
rcd "$directorio/DoFiles"  : find *.do , match(plot_te_allarms) show
