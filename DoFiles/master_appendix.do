/*

**  Isaac Meza, isaac.meza@berkeley.edu


Master do file for tables and figures for the appendix for the paper
	Private paternalism and the limits of self commitment

Data first need to be processed with the main_cleaning.do & processing.do dofiles.	
For further details see the notes in the paper and the dofile itself.	
*/		


*********************************** TABLES *************************************

*Table A1. : Survey’s non-response balance
do "$directorio\DoFiles\appendix\balance_response.do"

*Table A3. : Intermediate outcomes
do "$directorio\DoFiles\appendix\mechanisms.do"

*Table A4. : Clients who should prefer fee-forcing financial cost distribution
do "$directorio\DoFiles\appendix\stoch_dominance.do"

*Table A5. : Predicting Take-up: Goodness-of-Fit
** RUN R CODE : pfv_pred.R 
do "$directorio\DoFiles\appendix\pred_take_up.do"


*********************************** FIGURES ************************************

*Figure A4. : Behavior of those who lost pawn
do "$directorio\DoFiles\appendix\hist_den_default.do"

*Figure A5. :  Financial cost effect: charging all fees
do "$directorio\DoFiles\appendix\fc_all_fee.do"

*Figure A6. : FC as % of loan - treatment effect
do "$directorio\DoFiles\appendix\fc_perc_allarms.do"

*Figure A7. : Relationship between treatment effects
** RUN R CODE : grf.R
do "$directorio\DoFiles\appendix\binscatter_hte.do"

*Figure A8. : Empirical CDF of Financial Cost: fee-focing vs status-quo
do "$directorio\DoFiles\appendix\ecdf_fc.do"

*Figure A9. : Honest causal tree for the fee forcing contract heterogenous treatment effects
** RUN R CODE : grf.R 

*Figure A10. : Heterogeneous Treatment Effect: Fee-forcing contract
** RUN R CODE : grf.R 
*local arm pro_2
*do "$directorio\DoFiles\main_results\analyze_grf_single_arm.do"

*Figure A11. : Out of sample ROC curve
** RUN R CODE : pfv_pred.R 
*do "$directorio\DoFiles\appendix\pred_take_up.do"

*Figure A12. : Predictors of commitment contract take-up
** RUN R : pfv_pred.R
do "$directorio\DoFiles\appendix\analyze_fvp.do"

