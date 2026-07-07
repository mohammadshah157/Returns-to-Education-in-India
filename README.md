# Returns to Education in India: Evidence from PLFS 2019–20 using the Mincer Earnings Function

## Project Overview

This project estimates the **private returns to education in India** using unit-level data from the **Periodic Labour Force Survey (PLFS) 2019–20**. The analysis employs the classical **Mincer Earnings Function** to quantify the percentage increase in monthly wages associated with an additional year of schooling.

The project gradually extends the baseline model by incorporating labour market experience, demographic characteristics, and state fixed effects. It further investigates heterogeneity in returns across gender and place of residence.

The empirical results show that education remains one of the strongest predictors of earnings even after controlling for extensive observable characteristics.

---

## Research Question

> **How much does an additional year of education increase workers' wages in India after accounting for experience, gender, sector, and regional differences?**

---

## Dataset

**Source:** Periodic Labour Force Survey (PLFS) 2019–20

Sample characteristics:

- **Observations:** 107,371 wage earners
- **Outcome variable:** Log monthly wage (winsorized at the 99th percentile)
- **Education:** Years of completed schooling
- **Controls:**
  - Potential labour market experience
  - Experience²
  - Gender
  - Rural/Urban residence
  - State fixed effects

---

## Methodology

The project estimates four increasingly comprehensive Mincer wage equations.

### Model 1 — Baseline

$$
\ln(\text{Wage}) = \beta_0 + \beta_1 \text{Education} + \epsilon
$$


---

### Model 2 — Human Capital Specification

Adds

- Experience
- Experience²

---

### Model 3 — Demographic Controls

Adds

- Gender
- Rural/Urban sector

---

### Model 4 — Preferred Specification

Adds

- State Fixed Effects

This serves as the primary specification because it controls for persistent interstate differences in wages.

---

## Regression Results

| Model | Controls Added | Return to Education |
|--------|---------------:|--------------------:|
| Model 1 | None | **8.00%** |
| Model 2 | Experience | **10.62%** |
| Model 3 | Gender + Sector | **10.43%** |
| Model 4 | State Fixed Effects | **10.25%** |

Model fit improves substantially across specifications:

| Model | R² |
|--------|---:|
| Model 1 | 0.212 |
| Model 2 | 0.314 |
| Model 3 | 0.350 |
| Model 4 | **0.394** |

The education coefficient remains remarkably stable after additional controls, indicating a robust association between schooling and wages. :contentReference[oaicite:0]{index=0}

---

# Subgroup Analysis

Returns to education differ across demographic groups.

| Group | Return per Additional Year of Education |
|-------|----------------------------------------:|
| Male | **9.55%** |
| Female | **11.61%** |
| Rural | **8.55%** |
| Urban | **10.42%** |

Key findings:

- Female workers receive higher marginal returns to schooling than male workers.
- Urban labour markets reward education more strongly than rural labour markets.
- Despite lower average wages, education generates relatively larger proportional gains for women. :contentReference[oaicite:1]{index=1}

---

# Experience Profile

The estimated experience coefficients indicate a standard concave wage profile:

- Experience coefficient: **+3.64%**
- Experience² coefficient: **−0.03%**

Interpretation:

- Wages increase with labour market experience.
- The rate of wage growth slows over time.
- Returns eventually flatten as workers approach later career stages.

---

# Wage Premiums After Controls

Holding education, experience and state effects constant:

| Characteristic | Wage Premium |
|---------------|-------------:|
| Male | **≈40.0%** |
| Urban residence | **≈21.8%** |

These unexplained wage differentials suggest that observable human capital alone does not account for all earnings differences across workers.

---

# Final Conclusions

The empirical evidence consistently supports the central role of education in determining wages in India.

### Main findings

- **107,371** observations analysed.
- Education raises wages by approximately **10.25% per additional year of schooling** in the preferred model.
- Estimated returns remain stable between **10.25–10.62%** after progressively adding controls.
- Model explanatory power nearly doubles from **R² = 0.212** to **R² = 0.394**.
- Female workers earn higher marginal returns to education (**11.61%**) than male workers (**9.55%**).
- Urban workers receive higher educational returns (**10.42%**) than rural workers (**8.55%**).
- Experience positively affects earnings but exhibits diminishing marginal returns.
- Even after extensive controls, substantial wage premiums remain for males (**≈40%**) and urban workers (**≈22%**).

Overall, the findings indicate that **education is a robust and economically significant determinant of wages in India**, with approximately a **10% increase in monthly earnings for every additional year of schooling**. While education explains a substantial share of wage variation, persistent gender, geographic, and regional wage differentials remain even after accounting for observable human capital characteristics. :contentReference[oaicite:2]{index=2} :contentReference[oaicite:3]{index=3}

---

# Repository Structure

```text
.
├── Returns.Rmd
├── Comparison Table.html
├── Subgroup Comparison Table.html
├── chart1_Progressive_Models.png
├── chart2_Gender_and_sector_subgroups.png
├── chart3_wage_experience_profile.png
├── chart4_wage_premiums.png
├── README.md
└── LICENSE
```

---

# Software

- R
- tidyverse
- fixest
- modelsummary
- gt
- ggplot2
- broom

---

# Reproducibility

1. Obtain the PLFS 2019–20 microdata.
2. Install the required R packages.
3. Run `Returns.Rmd`.
4. The script automatically:
   - cleans the data,
   - estimates all regression models,
   - produces formatted regression tables,
   - generates publication-quality figures,
   - exports outputs for interpretation.

---

# Citation

If you use or adapt this repository, please cite it as:

> *Returns to Education in India: Evidence from PLFS 2019–20 using the Mincer Earnings Function.* Empirical analysis based on the Periodic Labour Force Survey (PLFS) 2019–20.
