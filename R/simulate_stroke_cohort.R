# Data-generating process for the simulated stroke cohort.
#
# Causal structure (every arrow corresponds to a coefficient below):
#   age, sex      -> severity
#   age, sex, severity -> time_to_hosp
#   age, sex, severity, time_to_hosp -> survival
# No other arrows exist; in particular there is no unmeasured confounding.
#
# severity is stroke severity at ONSET (NIHSS-like, 0-42), so it precedes the
# exposure and is a confounder, not a mediator. (In real data NIHSS is measured
# on arrival and may itself be affected by delay; here that is ruled out.)
#
# All parameter values are illustrative teaching choices, not literature estimates.

default_params <- list(
  # severity: negative binomial, log-mean model
  sev_mu0      = 7,      # mean severity at age 70, male
  sev_age      = 0.02,   # log-mean change per year of age
  sev_female   = 0.10,   # log-mean change for women
  sev_size     = 1.5,    # NB dispersion
  # time to hospital (minutes): log-normal
  time_median0 = 150,    # median minutes at age 70, male, severity 7
  time_age     = 0.005,  # log-minutes per year of age
  time_female  = 0.10,   # log-minutes for women
  time_sev     = -0.04,  # log-minutes per severity point (severe -> faster)
  time_sdlog   = 0.6,
  # survival: Weibull proportional hazards, time in days
  surv_shape   = 0.7,    # < 1: hazard highest soon after stroke
  surv_scale   = 0.0045, # baseline hazard scale (age 70, male, sev 7, time 0)
  surv_age     = 0.04,   # log-HR per year of age
  surv_female  = -0.10,  # log-HR for women
  surv_sev     = 0.08,   # log-HR per severity point
  surv_time    = log(1.10) / 60,  # TRUE EFFECT: HR 1.10 per 60 min delay
  follow_up    = 365     # administrative censoring (days)
)

# Draw baseline covariates and the uniform used for event times.
# Kept separate so counterfactual arms can share the same draws.
draw_baseline <- function(n, p = default_params) {
  age <- pmin(pmax(round(rnorm(n, 72, 11)), 18), 100)
  female <- rbinom(n, 1, 0.5)
  sev_mu <- p$sev_mu0 * exp(p$sev_age * (age - 70) + p$sev_female * female)
  severity <- pmin(rnbinom(n, mu = sev_mu, size = p$sev_size), 42)
  data.frame(age, female, severity,
             time_noise = rnorm(n, 0, p$time_sdlog),
             u_event = runif(n))
}

# Event times given covariates and a (possibly intervened) time to hospital.
event_times <- function(b, time_to_hosp, p = default_params) {
  lp <- p$surv_age * (b$age - 70) + p$surv_female * b$female +
    p$surv_sev * (b$severity - 7) + p$surv_time * time_to_hosp
  # Inverse of the Weibull cumulative hazard H(t) = scale * exp(lp) * t^shape
  (-log(b$u_event) / (p$surv_scale * exp(lp)))^(1 / p$surv_shape)
}

simulate_stroke_cohort <- function(n, p = default_params) {
  b <- draw_baseline(n, p)
  time_to_hosp <- exp(log(p$time_median0) + p$time_age * (b$age - 70) +
                        p$time_female * b$female +
                        p$time_sev * (b$severity - 7) + b$time_noise)
  t_event <- event_times(b, time_to_hosp, p)
  data.frame(
    id = seq_len(n),
    age = b$age,
    sex = factor(ifelse(b$female == 1, "female", "male"), c("male", "female")),
    severity = b$severity,
    time_to_hosp = round(time_to_hosp),
    followup_days = pmin(t_event, p$follow_up),
    died = as.integer(t_event <= p$follow_up),
    died_90d = as.integer(t_event <= 90)
  )
}

# True marginal risk of death by `horizon` days if everyone's time to hospital
# were set to `t_fixed` minutes. Monte Carlo over a large population; the same
# draws are reused across interventions (common random numbers).
true_risk <- function(t_fixed, horizon = 90, n_mc = 1e6, p = default_params,
                      seed = 1) {
  set.seed(seed)
  b <- draw_baseline(n_mc, p)
  sapply(t_fixed, function(t) mean(event_times(b, t, p) <= horizon))
}
