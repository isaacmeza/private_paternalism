/*

**  Isaac Meza, isaac.meza@berkeley.edu


Master do file for tables and figures for the appendix for the paper
	The limits of self-commitment and private paternalism

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

*Table B1. : Predicting the supply of FP contracts within branch across time
do "$directorio\DoFiles\appendix\instrument_random.do"
** RUN R CODE : instrument_pred.R
do "$directorio\DoFiles\appendix\pred_instrument.do"

*Table B2. : Experience with frequent payment contract raises future demand for it
do "$directorio\DoFiles\appendix\iv_reg_demand_pf.do"


*********************************** FIGURES ************************************

*Figure A4. : Behavior of those who lost pawn
do "$directorio\DoFiles\appendix\hist_den_default.do"

*Figure A5. : FC as % of loan - treatment effect
do "$directorio\DoFiles\appendix\fc_te_115.do"

*Figure A6. :  Financial cost effect: charging all fees
do "$directorio\DoFiles\appendix\fc_all_fee.do"

*Figure A7. : FC as % of loan - treatment effect
do "$directorio\DoFiles\appendix\fc_perc_allarms.do"

*Figure A8. : Relationship between treatment effects
** RUN R CODE : grf.R
do "$directorio\DoFiles\appendix\binscatter_hte.do"

*Figure A9. :  Repeat purchase before 30/60 days
do "$directorio\DoFiles\appendix\re_te_earlydays.do"

*Figure A10. : Empirical CDF of Financial Cost: fee-focing vs status-quo
do "$directorio\DoFiles\appendix\ecdf_fc.do"

*Figure A11. : Honest causal tree for the fee forcing contract heterogenous treatment effects
** RUN R CODE : grf.R 

*Figure A12. : Heterogeneous Treatment Effect: Fee-forcing contract
** RUN R CODE : grf.R 
*local arm pro_2
*do "$directorio\DoFiles\main_results\analyze_grf_single_arm.do"

*Figure A13. : Out of sample ROC curve
** RUN R CODE : pfv_pred.R 
*do "$directorio\DoFiles\appendix\pred_take_up.do"

*Figure A14. : Predictors of commitment contract take-up
** RUN R : pfv_pred.R
do "$directorio\DoFiles\appendix\analyze_fvp.do"

*Figure B1. :  Existence of FP per branch
do "$directorio\DoFiles\appendix\active_pf_suc.do"

*Figure B2. :  Number of pawns per client
do "$directorio\DoFiles\appendix\hist_num_pawns.do"
