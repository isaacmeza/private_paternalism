/*

**  Isaac Meza, isaac.meza@berkeley.edu


Master do file for main tables and figures of the paper
	Private paternalism and the limits of self commitment
	
Data first need to be processed with the main_cleaning.do & processing.do dofiles.	
For further details see the notes in the paper and the dofile itself.	
*/		


*********************************** TABLES *************************************

*Table 1. : Summary statistics and Balance
do "$directorio\DoFiles\main_results\ss.do"

*Table 2 : Overconfidence: Take-up and Treatment Effects
** RUN R CODE : grf.R 
do "$directorio\DoFiles\main_results\oc.do"


*********************************** FIGURES ************************************

*Figure 1. : Experiment description
do "$directorio\DoFiles\main_results\timeline_suc_exp.do"

*Figure 3. : Financial Cost
do "$directorio\DoFiles\main_results\hist_fc.do"

*Figure 4. : The effect of the fee-forcing treatment
*Figure 9. : The effect of promises
do "$directorio\DoFiles\main_results\fc_te.do"
do "$directorio\DoFiles\main_results\fc_quantilereg.do"	
do "$directorio\DoFiles\main_results\def_te.do"
** RUN R CODE : grf.R 
*local arm pro_2
do "$directorio\DoFiles\main_results\analyze_grf_single_arm.do" 

*Figure 5. : Effects on repeat purchasing
do "$directorio\DoFiles\main_results\re_te.do" 

*Figure 6. : The effect of choice between fee-commitment and status quo
*Figure 9. : The effect of promises
do "$directorio\DoFiles\main_results\fc_te_choice_dec.do"
do "$directorio\DoFiles\main_results\def_te_choice_dec.do"
do "$directorio\DoFiles\main_results\fc_quantilereg_choice_dec.do"

*Figure 7 : Distribution of overconfidence
*do "$directorio\DoFiles\main_results\oc.do"


*Figure 8. : Choice of contracts and treatment effects
** RUN R CODE : fc_te_grf.R
do "$directorio\DoFiles\main_results\choose_wrong_quant_wrong.do"
do "$directorio\DoFiles\main_results\choose_wrong_quant_wrong_decomposition.do"
** RUN R CODE : pfv_pred_hte.R
do "$directorio\DoFiles\main_results\effect_contr_takeup.do"

