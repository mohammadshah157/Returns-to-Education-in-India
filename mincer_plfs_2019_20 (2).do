/*===========================================================================
  RETURNS TO EDUCATION IN INDIA
  Mincer Earnings Function — PLFS 2019-20
  
  Data:    Periodic Labour Force Survey (PLFS) 2019-20, MoSPI
  Files:   PERFV_2019-20.csv  (First Visit person schedule)
           PERRV_2019-20.csv  (Revisit person schedule)
  
  Stages:
    0.  Setup
    1.  Load & stack raw CSVs
    2.  Variable construction & sample restrictions
    3.  Wage trimming (floor + winsorize)
    4.  Descriptive statistics
    5.  Progressive OLS (Models 1-4) + robust SEs
    6.  Figure 1 — returns across progressive models
    7.  Figure 2 — wage-experience profile
    8.  Figure 3 — unexplained wage premiums
    9.  Subgroup regressions (gender & sector)
   10.  Figure 4 — subgroup returns comparison
   11.  Interaction tests (formal heterogeneity tests)
   12.  Quantile regression (Q10/Q25/Q50/Q75/Q90)
   13.  Figure 5 — returns across wage distribution
   14.  Robustness checks
   15.  Export regression tables (esttab/estout)
===========================================================================*/


/*---------------------------------------------------------------------------
  0. SETUP
---------------------------------------------------------------------------*/

clear all
set more off
capture log close

* ── SET YOUR WORKING DIRECTORY ──────────────────────────────────────────────
* Change this to the folder containing PERFV_2019-20.csv and PERRV_2019-20.csv
cd "D:\Projects (ongoing)\Returns to Education"

* Output log
log using "mincer_plfs_results.log", replace text

* Install required packages (comment out after first run)
capture ssc install estout, replace   // regression tables

* Clean scheme for all figures
set scheme s2color

import delimited "D:\Projects (ongoing)\Returns to Education\plfs_2019_20_clean_trimmed.csv"

/*---------------------------------------------------------------------------
  4. DESCRIPTIVE STATISTICS
---------------------------------------------------------------------------*/

di _newline "============================================"
di          "  DESCRIPTIVE STATISTICS"
di          "============================================"

tabstat wage wage_capped log_wage_capped edu_years experience age, ///
    stats(n mean sd p25 p50 p75 p99) columns(stats) format(%9.2f)

di _newline "Gender:"
tab male

di _newline "Sector:"
tab urban

di _newline "Visit round:"
tab visit_type

di _newline "Education level:"
tab edu_level, sort

di _newline "State distribution (top 10):"
tab state


/*---------------------------------------------------------------------------
  5. PROGRESSIVE OLS (Models 1-4) + ROBUST STANDARD ERRORS
  
  HC1 robust SEs throughout — Cook-Weisberg test (estat hettest)
  confirms strong heteroskedasticity as expected with wage data.
  
  The preferred specification is Model 4 (+ state fixed effects).
  State dummies absorb persistent regional wage differences that
  would otherwise confound the education coefficient.
---------------------------------------------------------------------------*/

di _newline "============================================"
di          "  PROGRESSIVE OLS"
di          "============================================"

* Model 1: Basic Mincer
reg log_wage_capped edu_years, vce(robust)
estimates store model1
local ret1 = (exp(_b[edu_years]) - 1) * 100
di "Model 1 return: " %5.2f `ret1' "%"

* Model 2: + experience (quadratic)
reg log_wage_capped edu_years experience experience_sq, vce(robust)
estimates store model2
local ret2 = (exp(_b[edu_years]) - 1) * 100
di "Model 2 return: " %5.2f `ret2' "%"

* Model 3: + gender and sector
reg log_wage_capped edu_years experience experience_sq male urban, vce(robust)
estimates store model3
local ret3 = (exp(_b[edu_years]) - 1) * 100
di "Model 3 return: " %5.2f `ret3' "%"

* Model 4: + state fixed effects [preferred]
reg log_wage_capped edu_years experience experience_sq male urban i.state, ///
    vce(robust)
estimates store model4
local ret4       = (exp(_b[edu_years]) - 1) * 100
local b_exp      = _b[experience]
local b_exp2     = _b[experience_sq]
local b_male     = _b[male]
local b_urban    = _b[urban]
local prem_male  = (exp(`b_male')  - 1) * 100
local prem_urban = (exp(`b_urban') - 1) * 100
di "Model 4 return (preferred): " %5.2f `ret4' "%"
di "Male premium  (Model 4):    " %5.2f `prem_male'  "%"
di "Urban premium (Model 4):    " %5.2f `prem_urban' "%"

* Breusch-Pagan / Cook-Weisberg test for heteroskedasticity
quietly reg log_wage_capped edu_years experience experience_sq male urban i.state
estat hettest, rhs
* Significant → confirms robust SEs are appropriate

* Model comparison table
di _newline "--- Model comparison ---"
estout model1 model2 model3 model4, ///
    keep(edu_years experience experience_sq male urban _cons) ///
    cells(b(star fmt(%9.4f)) se(par fmt(%9.4f))) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    varlabels(edu_years     "Years of Education" ///
              experience    "Experience"          ///
              experience_sq "Experience^2"        ///
              male          "Male"                ///
              urban         "Urban"               ///
              _cons         "Constant")           ///
    mlabels("Model 1" "Model 2" "Model 3" "Model 4*") ///
    title("OLS Results (Dep var: Log Monthly Wage, winsorized)") ///
    note("* Preferred specification (+ state FE, omitted from display)" ///
         "HC robust SEs in parentheses. ***p<.01 **p<.05 *p<.10")

di _newline "Returns to education:"
di "  Model 1: " %5.2f `ret1' "%"
di "  Model 2: " %5.2f `ret2' "%"
di "  Model 3: " %5.2f `ret3' "%"
di "  Model 4: " %5.2f `ret4' "%  [preferred]"


/*---------------------------------------------------------------------------
  6. FIGURE 1 — RETURNS ACROSS PROGRESSIVE MODELS
  
  Bar chart showing how the education return changes as controls
  are added. Model 4 highlighted in navy.
---------------------------------------------------------------------------*/

preserve
clear
input byte model_n float return_pct str28 model_label
1   8.00  "Model 1 (Basic)"
2  10.62  "Model 2 (+Experience)"
3  10.43  "Model 3 (+Gender/Sector)"
4  10.25  "Model 4 (+State FE)"
end

* Assign bar colours: grey for Models 1-3, navy for preferred Model 4
gen bar_col = cond(model_n == 4, 1, 2)

twoway ///
    (bar return_pct model_n if model_n < 4, ///
         barwidth(0.6) fcolor(gs10) lcolor(gs10))   ///
    (bar return_pct model_n if model_n == 4, ///
         barwidth(0.6) fcolor("31 58 95") lcolor("31 58 95")), ///
    xlabel(1 `""Model 1" "(Basic)""'          ///
           2 `""Model 2" "(+Experience)""'     ///
           3 `""Model 3" "(+Gender/Sector)""'  ///
           4 `""Model 4" "(+State FE)""', noticks) ///
    ylabel(0(2)14, angle(0) format(%2.0f) gmin) ///
    ytitle("Return to one additional year of education (%)", size(small)) ///
    title("Returns to Education Stabilize as Controls Are Added", ///
          color("31 58 95") size(medsmall)) ///
    text(8.60  1  "8.00%",  size(small) color(black) placement(n)) ///
    text(11.22 2  "10.62%", size(small) color(black) placement(n)) ///
    text(11.03 3  "10.43%", size(small) color(black) placement(n)) ///
    text(10.85 4  "10.25%", size(small) color(black) placement(n)) ///
    text(13.0  3.5 "Preferred{break}specification", ///
         size(vsmall) color("31 58 95") justification(center)) ///
    note("Returns = (exp(beta_1) - 1) x 100. All estimates p < 0.001.", ///
         size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))

graph export "figure1_progressive_models.png", replace width(2400) height(1600)
di "Figure 1 saved."
restore


/*---------------------------------------------------------------------------
  7. FIGURE 2 — WAGE-EXPERIENCE PROFILE
  
  Plots the wage growth curve implied by Model 4 beta coefficients.
  The curve's mathematical peak is at ~56 years experience (outside
  the observable range), so wages keep rising across all sample ages
  but at a steadily decreasing rate.
---------------------------------------------------------------------------*/

preserve
clear
set obs 200
gen experience = (_n - 1) * (50 / 199)

* Model 4 coefficients
local b1 =  0.036436
local b2 = -0.000327
gen log_effect  = `b1' * experience + `b2' * experience^2
gen wage_growth = (exp(log_effect) - 1) * 100

twoway ///
    (area wage_growth experience, ///
         fcolor("31 58 95%12") lcolor(none)) ///
    (line wage_growth experience, ///
         lcolor("31 58 95") lwidth(medthick)), ///
    xtitle("Years of Potential Experience", size(small)) ///
    ytitle("Wage Growth Relative to Entry (%)", size(small)) ///
    xlabel(0(10)50) ///
    ylabel(0(25)175, angle(0) format(%3.0f)) ///
    title("Wages Rise with Experience, at a Decreasing Rate", ///
          color("31 58 95") size(medsmall)) ///
    text(148 36 ///
         "Growth decelerates — curve flattens" ///
         "but does not turn downward within" ///
         "working-age range (peak ~56 yrs)", ///
         size(vsmall) color("231 111 81") justification(left)) ///
    note("Plotted from Model 4 coefficients: b_exp = 0.0364, b_exp2 = -0.000327." ///
         "Mathematical peak at ~56 years (beyond observable sample range).", ///
         size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))

graph export "figure2_experience_profile.png", replace width(2400) height(1600)
di "Figure 2 saved."
restore


/*---------------------------------------------------------------------------
  8. FIGURE 3 — UNEXPLAINED WAGE PREMIUMS
  
  Male premium:  (exp(0.3366) - 1) x 100 = 40.0%
  Urban premium: (exp(0.1975) - 1) x 100 = 21.8%
  Both conditional on education, experience, and state.
---------------------------------------------------------------------------*/

preserve
clear
input byte group_n float premium_pct str22 group_label
1  21.8  "Urban wage premium"
2  40.0  "Male wage premium"
end

graph hbar premium_pct, over(group_label, sort(group_n) ///
        label(labsize(small))) ///
    bar(1, fcolor("31 58 95") lcolor(none)) ///
    ytitle("Wage premium, controlling for education/experience/state (%)", ///
           size(vsmall)) ///
    title("Unexplained Wage Premiums (Model 4)", ///
          color("31 58 95") size(medsmall)) ///
    ylabel(0(10)50, angle(0) format(%2.0f)) ///
    blabel(bar, format(%4.1f) ///
           size(small) color(black)) ///
    note("Premiums = (exp(beta) - 1) x 100. All controls held at sample means.", ///
         size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "figure3_wage_premiums.png", replace width(2400) height(1400)
di "Figure 3 saved."
restore


/*---------------------------------------------------------------------------
  9. SUBGROUP REGRESSIONS — GENDER & SECTOR
  
  Each subgroup model mirrors Model 4: full controls + state FE.
  Gender models omit the male dummy; sector models omit urban.
---------------------------------------------------------------------------*/

di _newline "============================================"
di          "  SUBGROUP REGRESSIONS"
di          "============================================"

* Male workers
reg log_wage_capped edu_years experience experience_sq urban i.state ///
    if male == 1, vce(robust)
estimates store sub_male
local ret_male = (exp(_b[edu_years]) - 1) * 100
di "Male return:   " %5.2f `ret_male' "%  (N = `e(N)')"

* Female workers
reg log_wage_capped edu_years experience experience_sq urban i.state ///
    if male == 0, vce(robust)
estimates store sub_female
local ret_female = (exp(_b[edu_years]) - 1) * 100
di "Female return: " %5.2f `ret_female' "%  (N = `e(N)')"

* Rural workers
reg log_wage_capped edu_years experience experience_sq male i.state ///
    if urban == 0, vce(robust)
estimates store sub_rural
local ret_rural = (exp(_b[edu_years]) - 1) * 100
di "Rural return:  " %5.2f `ret_rural' "%  (N = `e(N)')"

* Urban workers
reg log_wage_capped edu_years experience experience_sq male i.state ///
    if urban == 1, vce(robust)
estimates store sub_urban
local ret_urban = (exp(_b[edu_years]) - 1) * 100
di "Urban return:  " %5.2f `ret_urban' "%  (N = `e(N)')"

* Table
estout sub_male sub_female sub_rural sub_urban, ///
    keep(edu_years experience experience_sq) ///
    cells(b(star fmt(%9.4f)) se(par fmt(%9.4f))) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    varlabels(edu_years     "Years of Education" ///
              experience    "Experience"          ///
              experience_sq "Experience^2")       ///
    mlabels("Male" "Female" "Rural" "Urban") ///
    title("Subgroup Regressions (all include state FE)") ///
    note("HC robust SEs in parentheses. ***p<.01 **p<.05 *p<.10")

di _newline "Return summary:"
di "  Male:            " %5.2f `ret_male'   "%"
di "  Female:          " %5.2f `ret_female' "%"
di "  Rural:           " %5.2f `ret_rural'  "%"
di "  Urban:           " %5.2f `ret_urban'  "%"
di "  Pooled (Model 4):" %5.2f `ret4'       "%"


/*---------------------------------------------------------------------------
  10. FIGURE 4 — SUBGROUP RETURNS COMPARISON
  
  Four-bar chart with pooled OLS reference line at 10.25%.
---------------------------------------------------------------------------*/

preserve
clear
input byte group_n float return_pct str8 category str10 group_label
1  10.02  "Gender"  "Male"
2  12.31  "Gender"  "Female"
3   8.92  "Sector"  "Rural"
4  10.99  "Sector"  "Urban"
end

local pooled = 10.25

twoway ///
    (bar return_pct group_n if group_n == 1, ///
         barwidth(0.6) fcolor("31 58 95") lcolor(none)) ///
    (bar return_pct group_n if group_n == 2, ///
         barwidth(0.6) fcolor("231 111 81") lcolor(none)) ///
    (bar return_pct group_n if group_n == 3, ///
         barwidth(0.6) fcolor("42 157 143") lcolor(none)) ///
    (bar return_pct group_n if group_n == 4, ///
         barwidth(0.6) fcolor("233 196 106") lcolor(none)) ///
    (function y = `pooled', range(0.5 4.5) ///
         lpattern(dash) lcolor(gs8) lwidth(thin)), ///
    xlabel(1 "Male" 2 "Female" 3 "Rural" 4 "Urban", noticks) ///
    xscale(range(0.2 4.8)) ///
    ylabel(0(2)14, angle(0) format(%2.0f)) ///
    ytitle("Return to education (%)", size(small)) ///
    title("Returns to Education Vary by Gender and Sector", ///
          color("31 58 95") size(medsmall)) ///
    text(10.02  1  "10.02%", size(vsmall) color(black) placement(n)) ///
    text(12.31  2  "12.31%", size(vsmall) color(black) placement(n)) ///
    text(8.92   3  "8.92%",  size(vsmall) color(black) placement(n)) ///
    text(10.99  4  "10.99%", size(vsmall) color(black) placement(n)) ///
    text(`pooled' 4.3 "Pooled: 10.25%", ///
         size(vsmall) color(gs8) justification(right)) ///
    note("Dashed line = pooled OLS return (10.25%). State FE included in all models.", ///
         size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))

graph export "figure4_subgroup_comparison.png", replace width(2600) height(1600)
di "Figure 4 saved."
restore


/*---------------------------------------------------------------------------
  11. INTERACTION TESTS
  
  Tests whether the gender and sector gaps in returns are statistically
  significant — not just visual/sampling noise from separate regressions.
  
  edu_years#male  < 0 → men earn LOWER returns than women  
  edu_years#urban > 0 → urban workers earn HIGHER returns than rural
---------------------------------------------------------------------------*/

di _newline "============================================"
di          "  INTERACTION TESTS (formal heterogeneity)"
di          "============================================"

* Gender interaction
reg log_wage_capped c.edu_years##i.male ///
    experience experience_sq urban i.state, vce(robust)
di _newline "Interaction term edu_years x male:"
lincom c.edu_years#1.male
* Expected: negative, highly significant

* Sector interaction
reg log_wage_capped c.edu_years##i.urban ///
    experience experience_sq male i.state, vce(robust)
di _newline "Interaction term edu_years x urban:"
lincom c.edu_years#1.urban
* Expected: positive, highly significant


/*---------------------------------------------------------------------------
  12. QUANTILE REGRESSION (Q10 / Q25 / Q50 / Q75 / Q90)
  
  Stata's qreg does not support factor variables (i.state) natively
  with quantile loops, so state FE are excluded here — matching the
  approach taken in the R analysis for consistency.
  
  The specification mirrors Model 3: edu_years, experience,
  experience_sq, male, urban.
  
  vce(robust) gives asymptotic SEs — appropriate for N > 100,000
  and much faster than bootstrapping (bsqreg) at this sample size.
---------------------------------------------------------------------------*/

di _newline "============================================"
di          "  QUANTILE REGRESSION"
di          "============================================"

local quantiles 10 25 50 75 90

foreach q of local quantiles {
    local tau = `q' / 100
    qreg log_wage_capped edu_years experience experience_sq male urban, ///
        quantile(`tau') vce(robust) nolog
    estimates store qr_q`q'

    local coef_`q'  = _b[edu_years]
    local se_`q'    = _se[edu_years]
    local ret_`q'   = (exp(`coef_`q'') - 1) * 100
    local cilo_`q'  = (exp(`coef_`q'' - 1.96 * `se_`q'') - 1) * 100
    local cihi_`q'  = (exp(`coef_`q'' + 1.96 * `se_`q'') - 1) * 100
}

* Print clean results
di _newline "Quantile   Coef     Return    95% CI"
di "--------   ------   ------    ----------------"
foreach q of local quantiles {
    di "Q`q'" _col(12) %6.4f `coef_`q'' ///
       _col(21) %5.2f `ret_`q'' "%" ///
       _col(31) "[" %5.2f `cilo_`q'' "%, " %5.2f `cihi_`q'' "%]"
}
di "OLS (M4)" _col(12) "—" _col(21) %5.2f `ret4' "%" _col(31) "(reference)"

* Comparison table
estout qr_q10 qr_q25 qr_q50 qr_q75 qr_q90, ///
    keep(edu_years experience experience_sq male urban) ///
    cells(b(star fmt(%9.4f)) se(par fmt(%9.4f))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    varlabels(edu_years     "Years of Education" ///
              experience    "Experience"          ///
              experience_sq "Experience^2"        ///
              male          "Male"                ///
              urban         "Urban")              ///
    mlabels("Q10" "Q25" "Q50" "Q75" "Q90") ///
    title("Quantile Regression Results (Dep var: Log Monthly Wage)") ///
    note("Robust asymptotic SEs. No state FE (qreg limitation in Stata)." ///
         "***p<.01 **p<.05 *p<.10")


/*---------------------------------------------------------------------------
  13. FIGURE 5 — RETURNS ACROSS WAGE DISTRIBUTION
  
  Line + CI band + OLS reference. Values from your actual results:
    Q10: return = 7.33%   CI [7.16%, 7.49%]
    Q25: return = 9.04%   CI [8.92%, 9.16%]
    Q50: return = 11.84%  CI [11.72%, 11.96%]
    Q75: return = 12.59%  CI [12.46%, 12.73%]  ← peak
    Q90: return = 11.87%  CI [11.72%, 12.02%]
  OLS mean (Model 4): 10.25%
---------------------------------------------------------------------------*/

preserve
clear
input float quantile return_pct ci_lower ci_upper
0.10   7.33   7.16   7.49
0.25   9.04   8.92   9.16
0.50  11.84  11.72  11.96
0.75  12.59  12.46  12.73
0.90  11.87  11.72  12.02
end

local ols_ref = 10.25

twoway ///
    (rarea ci_upper ci_lower quantile, ///
         fcolor("31 58 95%15") lcolor(none)) ///
    (line return_pct quantile, ///
         lcolor("31 58 95") lwidth(medthick)) ///
    (scatter return_pct quantile, ///
         mcolor("31 58 95") msymbol(circle) msize(medium)) ///
    (function y = `ols_ref', range(0.10 0.90) ///
         lcolor("231 111 81") lwidth(medthick) lpattern(dash)), ///
    xlabel(0.10 `""Q10" "(Low earners)""' ///
           0.25 "Q25"                     ///
           0.50 `""Q50" "(Median)""'      ///
           0.75 "Q75"                     ///
           0.90 `""Q90" "(High earners)""', noticks labsize(vsmall)) ///
    ylabel(5(1)14, angle(0) format(%2.0f)) ///
    xtitle("Wage Quantile", size(small)) ///
    ytitle("Return to one year of education (%)", size(small)) ///
    title("Returns to Education Across the Wage Distribution", ///
          color("31 58 95") size(medsmall)) ///
    subtitle("Quantile regression vs. OLS mean (Model 4)", ///
             size(vsmall) color(gs7)) ///
    text(10.52 0.87 "OLS mean: 10.25%", ///
         color("231 111 81") size(vsmall) justification(right)) ///
    text(12.78 0.74 "Peak: 12.59%", ///
         color("31 58 95") size(vsmall) justification(center)) ///
    legend(order(1 "95% CI" 2 "Quantile regression" 4 "OLS mean") ///
           size(vsmall) cols(3) position(6) region(lcolor(none))) ///
    note("Controls: experience, experience2, male, urban. State FE omitted (qreg limitation)." ///
         "Robust asymptotic SEs.", size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "figure5_quantile_returns.png", replace width(2800) height(1800)
di "Figure 5 saved."
restore


/*---------------------------------------------------------------------------
  14. ROBUSTNESS CHECKS
---------------------------------------------------------------------------*/

di _newline "============================================"
di          "  ROBUSTNESS CHECKS"
di          "============================================"

* (a) Capped vs uncapped wage
reg log_wage edu_years experience experience_sq male urban i.state, vce(robust)
local ret_uncapped = (exp(_b[edu_years]) - 1) * 100
di "Uncapped wage return:   " %5.2f `ret_uncapped' "%"
di "Winsorized wage return: " %5.2f `ret4' "%"

di "Difference:             " %5.2f (`ret_uncapped' - `ret4') " percentage points"

* (b) Default vs robust SE comparison on edu_years (Model 4)
quietly reg log_wage_capped edu_years experience experience_sq male urban i.state
local se_default = _se[edu_years]
quietly reg log_wage_capped edu_years experience experience_sq male urban i.state, ///
    vce(robust)
local se_robust = _se[edu_years]
di _newline "Default SE (edu_years): " %8.6f `se_default'
di "Robust  SE (edu_years): " %8.6f `se_robust'
di "% change:               " %5.2f ((`se_robust' - `se_default') / `se_default') * 100 "%"

* (c) First Visit vs Revisit subsample stability
foreach round in FV RV {
    reg log_wage_capped edu_years experience experience_sq male urban i.state ///
        if visit_type == "`round'", vce(robust)
    local ret_`round' = (exp(_b[edu_years]) - 1) * 100
    di "`round' return: " %5.2f `ret_`round'' "%  (N = `e(N)')"
}
di "Pooled return: " %5.2f `ret4' "%"

* (d) VIF check (multicollinearity — run on default OLS for vif command)
quietly reg log_wage_capped edu_years experience experience_sq male urban i.state
estat vif
* VIF > 10 = problematic; experience/experience_sq will be moderate by construction


/*---------------------------------------------------------------------------
  15. EXPORT REGRESSION TABLES
---------------------------------------------------------------------------*/

* Table 1: Progressive OLS → RTF (opens directly in Word)
esttab model1 model2 model3 model4 using "table1_ols_results.rtf", ///
    replace ///
    keep(edu_years experience experience_sq male urban) ///
    cells(b(star fmt(%9.4f)) se(par fmt(%9.4f))) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    varlabels(edu_years     "Years of Education" ///
              experience    "Experience"          ///
              experience_sq "Experience Squared"  ///
              male          "Male"                ///
              urban         "Urban")              ///
    mlabels("Model 1" "Model 2" "Model 3" "Model 4") ///
    title("Table 1: Mincer Earnings Function — OLS Results") ///
    note("HC robust SEs in parentheses. State FE included in Model 4 (omitted from display)." ///
         "Return to Education = (exp(beta_1) - 1) x 100." ///
         "*** p<0.01 ** p<0.05 * p<0.10")

* Table 2: Subgroup regressions → RTF
esttab sub_male sub_female sub_rural sub_urban using "table2_subgroup.rtf", ///
    replace ///
    keep(edu_years experience experience_sq) ///
    cells(b(star fmt(%9.4f)) se(par fmt(%9.4f))) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    mlabels("Male" "Female" "Rural" "Urban") ///
    title("Table 2: Returns to Education by Gender and Sector") ///
    note("All specifications include state FE and HC robust SEs." ///
         "*** p<0.01 ** p<0.05 * p<0.10")

* Table 3: Quantile regression → RTF
esttab qr_q10 qr_q25 qr_q50 qr_q75 qr_q90 using "table3_quantile.rtf", ///
    replace ///
    keep(edu_years experience experience_sq male urban) ///
    cells(b(star fmt(%9.4f)) se(par fmt(%9.4f))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    mlabels("Q10" "Q25" "Q50" "Q75" "Q90") ///
    title("Table 3: Quantile Regression — Returns Across Wage Distribution") ///
    note("Robust asymptotic SEs. Controls: experience, male, urban (no state FE)." ///
         "*** p<0.01 ** p<0.05 * p<0.10")

di _newline "Tables exported to:"
di "  table1_ols_results.rtf"
di "  table2_subgroup.rtf"
di "  table3_quantile.rtf"


/*---------------------------------------------------------------------------
  END
---------------------------------------------------------------------------*/

di _newline "============================================"
di          "  ALL DONE"
di          "============================================"
di "Figures:  figure1_progressive_models.png"
di "          figure2_experience_profile.png"
di "          figure3_wage_premiums.png"
di "          figure4_subgroup_comparison.png"
di "          figure5_quantile_returns.png"
di "Tables:   table1_ols_results.rtf"
di "          table2_subgroup.rtf"
di "          table3_quantile.rtf"
di "Dataset:  plfs_2019_20_clean_trimmed.dta"
di "Log:      mincer_plfs_results.log"

log close



