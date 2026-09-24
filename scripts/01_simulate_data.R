# Simulate the stroke cohort and compute the true causal estimands.
# Run from the project root:  Rscript scripts/01_simulate_data.R
#
# Writes:
#   data/raw/stroke_cohort.csv   the dataset students analyse
#   data/raw/true_estimands.csv  the truth, to check the analysis against

source("R/simulate_stroke_cohort.R")

n <- 2000
set.seed(2026)
cohort <- simulate_stroke_cohort(n)
write.csv(cohort, "data/raw/stroke_cohort.csv", row.names = FALSE)

# Conditional truth: the hazard ratio coded into the data-generating process.
# Marginal truth: risk of death if everyone arrived at a fixed time.
times <- c(60, 120, 240)
truth <- data.frame(
  estimand = c("conditional HR per 60 min delay",
               sprintf("marginal %d-day risk if all arrive at %d min",
                       rep(c(90, 365), each = length(times)), times),
               "marginal 90-day RD, 240 vs 60 min",
               "marginal 90-day RR, 240 vs 60 min"),
  value = NA_real_
)
r90  <- true_risk(times, horizon = 90)
r365 <- true_risk(times, horizon = 365)
truth$value <- c(exp(60 * default_params$surv_time), r90, r365,
                 r90[3] - r90[1], r90[3] / r90[1])
write.csv(truth, "data/raw/true_estimands.csv", row.names = FALSE)

print(truth, digits = 3)
