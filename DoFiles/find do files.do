*ssc install find
*ssc install rcd
 
*******************************************************************************/
clear
set more off
 
 
rcd "$directorio/DoFiles"  : find *.do , match(val_pren_pr) show
