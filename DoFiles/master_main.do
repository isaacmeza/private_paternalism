/*

**  Isaac Meza, isaac.meza@berkeley.edu


Master do file for main tables and figures of the paper
	Tying Odysseus or giving him choice? 
	The demand for and effects of frequent payment commitment contracts

Data first need to be processed with the main_cleaning & processing dofile.	
For further details see the notes in the paper and the dofile itself.	
*/		


*********************************** TABLES *************************************

*Table 1—: Summary statistics and Balance
do "$directorio\DoFiles\main_results\ss.do"

*Table 2—: Mechanism effects
do "$directorio\DoFiles\main_results\mechanisms.do"


*********************************** FIGURES ************************************

*Figure 1. : Experiment description
do "$directorio\DoFiles\main_results\timeline_suc_exp.do"

*Figure 2. : Financial Cost
do "$directorio\DoFiles\main_results\hist_fc.do"

*Figure 3. : Behavior of those who lost pawn
do "$directorio\DoFiles\main_results\hist_den_default.do"

*Figure 4. : “Forced commitment with fee” Treatment Effects
*Figure 8. : “Forced commitment with promise Treatment Effects
do "$directorio\DoFiles\main_results\fc_te.do"
do "$directorio\DoFiles\main_results\def_te.do"
do "$directorio\DoFiles\main_results\fc_quantilereg.do"

*Figure 5. : Voluntary commitment with fee” Treatment Effects
*Figure 9. : Voluntary commitment with promise Treatment Effects
do "$directorio\DoFiles\main_results\fc_te_choice_dec.do"
do "$directorio\DoFiles\main_results\def_te_choice_dec.do"
do "$directorio\DoFiles\main_results\fc_quantilereg_choice_dec.do"

*Figure 6. : Effect of those induced in early payment
do "$directorio\DoFiles\main_results\binscatter_hte.do"

*Figure 7. : Who makes mistakes?
do "$directorio\DoFiles\main_results\effect_contr_takeup.do"
do "$directorio\DoFiles\main_results\choose_wrong_quant_wrong.do"



