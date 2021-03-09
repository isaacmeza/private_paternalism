*SS/Numbers reported in the paper

use "$directorio/DB/Master.dta", clear

*********************************Abstract*********************************

*their (fee-including) financial cost by 9.5\%, increases the likelihood of recovering their pawn by 25\%, and increases the likelihood of repeat business by 55\%
reg fc_admin_disc  pro_2 ${C0} , r cluster(suc_x_dia) 
su fc_admin_disc if pro_2==0
di  _b[pro_2]*100/`r(mean)'

reg des_c  pro_2 ${C0} , r cluster(suc_x_dia) 
su des_c if pro_2==0
di  _b[pro_2]*100/`r(mean)'

preserve
collapse reincidence prestamo $C1  pro_2 ///
			, by(NombrePignorante fecha_inicial)

*Analyze reincidence for the FIRST treatment arm
sort NombrePignorante fecha_inicial
bysort NombrePignorante : keep if _n==1

reg reincidence pro_2 ${C1} , r 
su reincidence if pro_2==0
di  _b[pro_2]*100/`r(mean)'
restore

*we find that more than 90\% clients would reduce their financing cost with the commitment contract, 
 
 
*however only 10\% choose it
gen pago_frec_vol_fee=(producto==5) if (producto==4 | producto==5)
gen pago_frec_vol_promise=(producto==7) if (producto==6 | producto==7)
gen pago_frec_vol=inlist(producto,5,7)

su pago_frec_vol*


*************************************************************************


*while pawnshop clients predict they will recover their pawn with 93% probability on average, in reality only 40%
su pr_recup des_c

*Even conditional on paying a positive amount towards pawn recovery, 47% lose their pawn and their payment
su des_c if sum_pdisc_c>0

*In our survey 69\% report self-control problems saying they often fall into temptation spending
su tentado

*The effects are large: financing cost decreases by 9.5\% on average, from \hl{XXX} to \hl{XXX}, while the likelihood of recovering their pawn increases by 25\%, from \hl{XXX} to \hl{XXX}.reg des_c  pro_2 ${C0} , r cluster(suc_x_dia) 
reg fc_admin_disc  pro_2 ${C0} , r cluster(suc_x_dia) 
su fc_admin_disc if pro_2==0
di  _b[pro_2]*100/`r(mean)'
di `r(mean)'
di `r(mean)'+_b[pro_2]

reg des_c  pro_2 ${C0} , r cluster(suc_x_dia) 
su des_c if pro_2==0
di  _b[pro_2]*100/`r(mean)'
di `r(mean)'
di `r(mean)'+_b[pro_2]

*Finally, we find that borrowers assigned to the forced fee-commitment contract are 5pp (55\% of the mean) more
preserve
collapse reincidence prestamo $C1  pro_2 ///
			, by(NombrePignorante fecha_inicial)

*Analyze reincidence for the FIRST treatment arm
sort NombrePignorante fecha_inicial
bysort NombrePignorante : keep if _n==1

reg reincidence pro_2 ${C1} , r 
su reincidence if pro_2==0
di  _b[pro_2]*100/`r(mean)'
restore


*Only 10\% of the group offered a choice between the monthly payment fee-commitment contract and the status-quo one chose the former. 
su pago_frec_vol*


* We calculate that about 80\% of clients in the fee-choice group chose contracts that induced \textit{higher} financial cost


*On average they spend an extra \$238 MXN, close to 11\% of the average loan value.



*\hl{XXX\%} of clients lose their pawn in a time span of 230 from the day of pawning.
su def_c


*(a)  the reported subjective value of the pawn is larger than the loan size for \hl{86\%} of them, 
cap drop flag
gen flag = val_pren>=prestamo if !missing(val_pren)
su flag 

*(b) among those that lose their pawn 74\% paid a positive amount towards its recovery
count if def_c
local temp = `r(N)'
count if def_c & sum_p_c>0
di `r(N)'/`temp'

*On average clients that lost their pawn paid 34\% of the value of their loan, 
su sum_porcp_c if def_c & sum_porcp_c>0


*and close to 55\% of clients extended the loan for another cycle and made payments in the second cycle 
count
count if dias_ultimo_mov>105 & sum_p_c>0


*The experiment comprises 13,444 pawns, and our administrative data cover a total of 26,179 pawns
count
count if !missing(prod)

* the 44\% recovery that happens in reality for the pawns in the control group
su des_c if pro_2==0


*********************************Summary Statistics*********************************

*Even those that recover their pawn tend to pay it back at the last moment, with only 17\% paying before the 90th day.
count if des_c==1 & pro_2==0 & dias_al_desempenyo<90
local temp = `r(N)'
count if des_c==1 & pro_2==0
di `temp'/`r(N)'

*The average time they take to come to the branch is 22 minutes, and the amount of money they spend in transport to do that is 11 pesos
su t_llegar c_trans

*The population we are working with is economically vulnerable in the sense that 31\% of them could not pay either water, electricity \& gas or rent in the past 6 months. 
cap drop flag
gen flag = renta +luz +gas +agua
replace flag = flag>0 if !missing(flag)
su flag


*They often receive negative income shocks: 87\% said they are pawning because of an emergency, and only 13\% stated it was to use in a `non-urgent expense'
tab razon

*This cost is calculated for a time period of 230 days after loan origination, as 50\% of clients actually renew the loan one time
*Of those who renew 34\% lose the pawn. 
count if !missing(prod)
count if !missing(prod) & dias_ultimo_mov>105
local temp =`r(N)'
count if !missing(prod) & dias_ultimo_mov>105 & def_c
di `r(N)'/`temp'

*APR of xxx\% on average for the control group.
preserve
use "$directorio/_aux/apr.dta", clear
su apr
di (1+`r(mean)'/100)^365
restore

*(only 1\% of consumers appear in more than one of our branches)
preserve
cap drop flag
duplicates drop NombrePignorante suc, force
bysort NombrePignorante : gen flag = _n
tab flag
restore

*To this end we estimated the regression\footnote{We cluster the standard errors by branch.} $Pawns \: per \: day_{jt} = \alpha_j + \gamma f(t) + \beta_b \mathbbm{1}(t \in MB)_{t} +\beta_a \mathbbm{1}(t \in MA)_{t}$
preserve

use "$directorio/_aux/num_pawns_suc_dia.dta", clear

gen before = inrange(fecha_inicial,date("08/05/2012","MDY"),date("09/05/2012","MDY"))
replace before = . if fecha_inicial<date("08/05/2012","MDY")

gen after = .

replace after = inrange(fecha_inicial,date("09/30/2012","MDY"),date("10/30/2012","MDY")) ///
	if suc==3 & fecha_inicial<=date("10/30/2012","MDY")

replace after = inrange(fecha_inicial,date("10/2/2012","MDY"),date("11/2/2012","MDY")) ///
	if suc==5 & fecha_inicial<=date("11/2/2012","MDY")
	
replace after = inrange(fecha_inicial,date("12/23/2012","MDY"),date("1/23/2013","MDY")) ///
	if suc==42 & fecha_inicial<=date("1/23/2013","MDY")
	
replace after = inrange(fecha_inicial,date("12/25/2012","MDY"),date("1/25/2013","MDY")) ///
	if suc==78 & fecha_inicial<=date("1/25/2013","MDY")
	
replace after = inrange(fecha_inicial,date("12/25/2012","MDY"),date("1/25/2013","MDY")) ///
	if suc==80 & fecha_inicial<=date("1/25/2013","MDY")
	
replace after = inrange(fecha_inicial,date("12/25/2012","MDY"),date("1/25/2013","MDY")) ///
	if suc==104 & fecha_inicial<=date("1/25/2013","MDY")

	
reg num_empenio_sucdia before after c.fecha_inicial##c.fecha_inicial##c.fecha_inicial i.suc , cluster(suc)

restore


*the financing cost the client incurred, of 9.5\% (\hl{\$304}) in the fist definition and 13.3\% (\hl{\$478})
reg fc_admin_disc  pro_2 ${C0} , r cluster(suc_x_dia) 
su fc_admin_disc if pro_2==0
di  _b[pro_2]*100/`r(mean)'

reg fc_survey_disc  pro_2 ${C0} , r cluster(suc_x_dia) 
su fc_survey_disc if pro_2==0
di  _b[pro_2]*100/`r(mean)'

*We find that more than 90\% of clients experienced financial cost savings in the fee-forcing group compared to the status-quo group
preserve
import delimited "$directorio/_aux/grf_extended_pro_2_fc_admin_disc.csv", clear
su tau_hat_oobpredictions
local temp = `r(N)'
count if tau_hat_oobpredictions<0
di `r(N)'/`temp'
restore

*the fee-forcing commitment contract increases the likelihood of recovering the pawn by 11pp (25.8\% of mean recovery)
reg des_c  pro_2 ${C0} , r cluster(suc_x_dia) 
su des_c if pro_2==0
di  _b[pro_2]*100/`r(mean)'


*Figure \ref{fc_pro2}(e) shows the distribution of heterogeneous treatment effects for losing the pawn:
preserve
import delimited "$directorio/_aux/grf_extended_pro_2_def_c.csv", clear
su tau_hat_oobpredictions
local temp = `r(N)'
count if tau_hat_oobpredictions<0
di `r(N)'/`temp'
restore


*Results are similar if we condition in the control group on those who would have paid a fee given current behavior.
gen feeall = (sum_porc_inc_fee_c>0)
su feeall
reg fc_admin_disc pro_2 ${C0} if feeall==1 , r cluster(suc_x_dia)

*only \hl{16\%} recover their piece in the fist 75 days in the fee forcing contract)
count if pro_2==1
local temp = `r(N)'
count if pro_2==1 & dias_al_desempenyo<=75
di `r(N)'/`temp'

*90\% of those in the fee-forcing arm incurred a fee, which suggests that shocks are not uncommon.
cap drop flag
gen flag = (sum_porc_inc_fee_c>0)
su flag if pro_2==1


*a large number of people (31\%) in the control group pay a positive amount toward pawn recovery but end up losing their pawn anyway
cap drop flag
gen flag = (sum_porcp_c>0 & def_c==1)
su flag if pro_2==0


*We find that 15\% of clients are classified as present biased
su pb


*Even among those that recover their pawn, only 42\% pay before the 90$^{th}$ day
count if des_c==1 & pro_2==0 & dias_al_desempenyo<90
local temp = `r(N)'
count if des_c==1 & pro_2==0
di `temp'/`r(N)'


