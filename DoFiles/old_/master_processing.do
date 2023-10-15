/*

**  Isaac Meza, isaac.meza@berkeley.edu


Processing of data for further analysis in R
	
*/		


******************************* DATA PROCESSING ********************************

*Preparation of dataset for FC HTE
do "$directorio\DoFiles\processing\prepare_data_fc_te.do"
** RUN R CODE : fc_te_grf.R 

*Preparation of dataset for HTE computation
do "$directorio\DoFiles\processing\prepare_data_grf.do"
** RUN R CODE : grf.R 

*Preparation of dataset for takeup prediction
do "$directorio\DoFiles\processing\prepare_data_pfv.do"
do "$directorio\DoFiles\processing\rf_takeup_preparation.do"
** RUN R CODE : pfv_pred.R 

*Preparation of dataset for computation of contrafactual in takeup for nochoice arm
do "$directorio\DoFiles\processing\prepare_contr_takeup.do"
** RUN R CODE : pfv_pred_hte.R 

