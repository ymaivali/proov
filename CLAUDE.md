# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This is an RStudio project (`proov.Rproj`). Steps 1 (folder structure) and 2 (simulation) are done. `a1.qmd` holds the project brief rather than any analysis. It is not yet a git repository and has no R package setup (`DESCRIPTION`, `renv`) and no tests.

## Layout and data flow

The README has the folder table. The intended flow is:

`R/` functions → `scripts/01_*.R` writes `data/raw/` → later scripts write `data/processed/` and `output/{figures,tables}/` → `reports/*.qmd` reads the saved outputs.

- Put reusable logic (the simulation function, estimators) in `R/`. Scripts `source()` it and stay thin.
- Number scripts in the order they run. Each one should run from a fresh R session with the project root as the working directory.
- Treat `data/raw/` as immutable: regenerate it from the seeded simulation, and never edit it by hand.
- The `.gitkeep` files exist only so git tracks empty folders. Delete one once its folder has real files.

## Purpose (from `a1.qmd`)

This is a teaching project: students watch a Claude Code project get built step by step. Every step and commit should therefore be easy to follow and explain. The planned steps, in order:

1. Create a typical folder structure.
2. Simulate data for an epidemiological study in which stroke patients' survival depends on how quickly they reach hospital, with **age and sex as confounders**.
3. Present an analysis plan.
4. Do the analysis.
5. Create a GitHub repository and push the commits.

Work through these in order. Present the analysis plan (step 3) before writing any analysis code.

## The simulation (`R/simulate_stroke_cohort.R`)

The user chose to add **stroke severity** as a confounder, alongside age and sex.

- `scripts/01_simulate_data.R` writes the dataset (n = 2000, seed 2026) to `data/raw/stroke_cohort.csv`. It writes the truth to `data/raw/true_estimands.csv`.
- **Exposure:** `time_to_hosp`, onset-to-door time in minutes (log-normal). More severe strokes arrive faster.
- **Outcome:** Weibull proportional-hazards survival, with administrative censoring at 365 days (`followup_days`, `died`), plus `died_90d`.
- `severity` means severity at *onset*, so it comes before the exposure. It is a confounder, not a mediator.
- **True effect:** a conditional HR of 1.10 per 60 minutes, linear in minutes on the log-hazard scale.
- The marginal truths come from `true_risk()`: Monte Carlo over 10^6 people, with a fixed time imposed on everyone.
- Adjusting for age and sex alone leaves the estimate near the null. Adjusting for severity as well recovers the true effect. This is deliberate and is the teaching point.
- `draw_baseline()` and `event_times()` are split so that counterfactual arms share the same random draws. Keep that split if you change the DGP.

## Epidemiological constraints

- The data are simulated, so the true data-generating process is known. Write the true effect down in the simulation code, as a named parameter or a computed true marginal estimand. The analysis should then be checked against that truth, not just reported.
- The analysis plan should state the estimand explicitly: the exposure definition (continuous time-to-hospital or a threshold), the outcome (death by a fixed time or time-to-event), and the effect measure (risk difference, risk ratio or hazard ratio, marginal or conditional). It should also give the adjustment set implied by the DAG.
- The simulation should make its causal structure (age, sex → time-to-hospital and → survival) explicit enough to draw as a DAG.
- Set a random seed for every simulation, so results can be reproduced when the project is rendered for students.

## Commands

The installed tools are Quarto 1.4.554, R 4.6.0, `git` and `gh`.

```bash
quarto render a1.qmd
```

To run R scripts non-interactively:

```bash
Rscript path/to/script.R
```

`a1.qmd` uses `editor: visual`, so it may also be edited in RStudio's visual editor. Keep the Markdown source clean, because RStudio reformats it.

## Conventions

- Indent with 2 spaces and use UTF-8 (both set in `proov.Rproj`).
- `.gitignore` already excludes `.Rproj.user/`, R session files and rendered Quarto output (`*.html`, `*_files/`).
- Step 5 creates a remote GitHub repository, which is visible to others. Confirm with the user before creating or pushing it.
