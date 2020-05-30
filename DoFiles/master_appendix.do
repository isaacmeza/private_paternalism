/*

**  Isaac Meza, isaac.meza@berkeley.edu


Master do file for main tables and figures of the paper
	Tying Odysseus or giving him choice? 
	The demand for and effects of frequent payment commitment contracts

Data first need to be processed with the main_cleaning & processing dofile.	
For further details see the notes in the paper and the dofile itself.	
*/		


*********************************** TABLES *************************************

*Table A1. : Balance response table
do "$directorio\DoFiles\appendix\balance_response.do"

*Table A2. : Out of sample measures of fit
** RUN R CODE : pfv_pred.R 
do "$directorio\DoFiles\appendix\pred_take_up.do"

*Table A3. : Reincidence SS
do "$directorio\DoFiles\appendix\tab_reincidence.do"

*Table A4. : Reincidence SS
*do "$directorio\DoFiles\main_results\ss.do"

*Table A5. : Stochastic dominance of fee-forcing contract
do "$directorio\DoFiles\appendix\stoch_dominance.do"

*Table A6. : OC Regression
** RUN R CODE : grf.R 
do "$directorio\DoFiles\appendix\oc.do"


*********************************** FIGURES ************************************

*Figure A2. : ECDF of Financial Cost
do "$directorio\DoFiles\appendix\ecdf_fc.do"

*Figure A3. : Behavior of those who lost pawn
do "$directorio\DoFiles\appendix\hist_den_default.do"

*Figure A4. : Histogram of payments
*Figure A5. : Percentage of payments
*Figure A6. : Percentage of payment conditional on positive payment and Losing Pawn
do "$directorio\DoFiles\appendix\hist_payments.do"

*Figure A7. : Heterogeneous Treatment Effect:  Fee-forcing contract
** RUN R CODE : grf.R 
*local arm pro_2
*do "$directorio\DoFiles\main_results\analyze_grf_single_arm.do"

*Figure A8. : Relationship between treatment effects
** RUN R CODE : grf.R
do "$directorio\DoFiles\appendix\binscatter_hte.do"

*Figure A9. : FC as % of loan - treatment effect
do "$directorio\DoFiles\appendix\fc_perc_allarms.do"

*Figure A10. : Financial cost effect with all fees
do "$directorio\DoFiles\appendix\fc_all_fee.do"

*Figure A11. : Overconfidence histogram
*do "$directorio\DoFiles\appendix\oc.do"

*Figure A12. : FC effect for different discount rates
do "$directorio\DoFiles\appendix\discounted_noeffect.do"

*Figure A13. : Predictors of commitment contract take-up
** RUN R : pfv_pred.R
do "$directorio\DoFiles\appendix\analyze_fvp.do"

*Figure A14. : Out of sample ROC curve
** RUN R CODE : pfv_pred.R 
*do "$directorio\DoFiles\appendix\pred_take_up.do"

*Figure A15. : Heterogeneous Treatment Effect - Choice/Fee
** RUN R CODE : grf.R 
*local arm pro_4
*do "$directorio\DoFiles\main_results\analyze_grf_single_arm.do"

*Figure A16. : Heterogeneous Treatment Effect:  Choice/Promise
** RUN R CODE : grf.R 
*local arm pro_5
*do "$directorio\DoFiles\main_results\analyze_grf_single_arm.do"

*Figure A17. : Heterogeneous Treatment Effect:  No-Choice/Promise
** RUN R CODE : grf.R 
*local arm pro_3
*do "$directorio\DoFiles\main_results\analyze_grf_single_arm.do"

*Figure A18. : Causal tree for HTE
** RUN R CODE : grf.R 
