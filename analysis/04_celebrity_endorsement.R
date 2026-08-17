# Smartphone Customer Analytics
# 04 - Celebrity Endorsement Simulation
# Author: Anne Han
#
# Objective:
# Simulate the potential effect of a celebrity endorsement on Samsung
# brand preference, predicted smartphone demand, and profitability.

library(tidyverse)
library(mlogit)


# -------------------------------------------------------------------
# 1. Load prepared choice data
# -------------------------------------------------------------------

# The course-provided formatted choice dataset is not distributed in
# this public repository.

load("mnl_datasets.RData")


# -------------------------------------------------------------------
# 2. Fit heterogeneous MNL model
# -------------------------------------------------------------------

# The model allows brand, price, and screen-size preferences to vary
# across behavioral customer segments and incorporates differences in
# price sensitivity based on smartphone usage intensity.

choice_model <- mlogit(
  choice ~
    apple:segment +
    samsung:segment +
    price:segment +
    screen_size:segment +
    price:total_minutes:segment |
    0,
  data = mdat1
)

phone_names <- c(
  "A1", "A2", "S1", "S2", "H1", "H2"
)


# -------------------------------------------------------------------
# 3. Calculate baseline market shares
# -------------------------------------------------------------------

baseline_shares <- colMeans(
  predict(
    choice_model,
    newdata = mdat1
  )
)

names(baseline_shares) <- phone_names

baseline_shares


# -------------------------------------------------------------------
# 4. Establish baseline Samsung profitability
# -------------------------------------------------------------------

# Prices and cost assumptions for Samsung S1 and S2.
s1_price <- 799
s2_price <- 899

s1_marginal_cost <- 440
s2_marginal_cost <- 470

# The simulation assumes a target market of 10 million smartphones.
# Quantities are therefore measured in millions of phones, so revenue,
# cost, and profit values are expressed in millions of dollars.

market_size <- 10


calculate_samsung_profit <- function(
  s1_share,
  s2_share
) {

  tibble(
    s1_price = s1_price,
    s1_share = s1_share,
    s2_price = s2_price,
    s2_share = s2_share
  ) |>
    mutate(
      s1_quantity = s1_share * market_size,
      s2_quantity = s2_share * market_size,

      s1_revenue = s1_quantity * s1_price,
      s2_revenue = s2_quantity * s2_price,

      s1_cost = s1_quantity * s1_marginal_cost,
      s2_cost = s2_quantity * s2_marginal_cost,

      s1_profit = s1_revenue - s1_cost,
      s2_profit = s2_revenue - s2_cost,

      total_profit = s1_profit + s2_profit
    )
}


baseline_profit <- calculate_samsung_profit(
  baseline_shares["S1"],
  baseline_shares["S2"]
)

baseline_profit


# -------------------------------------------------------------------
# 5. Simulate celebrity endorsement effect
# -------------------------------------------------------------------

# The original analysis assumes external market research indicates that
# a celebrity endorsement would increase Samsung brand preference.
#
# That hypothetical effect is represented as a 0.005 increase in each
# segment-specific Samsung brand coefficient.

celebrity_effect <- 0.005

endorsement_model <- choice_model

# Identify Samsung-by-segment coefficients.
samsung_coefficients <- grep(
  "samsung.*segment|segment.*samsung",
  names(coef(choice_model)),
  ignore.case = TRUE
)

# Verify that the expected three segment-specific coefficients were found.
if (length(samsung_coefficients) != 3) {
  stop("Expected three Samsung segment coefficients.")
}

endorsement_model$coefficients[samsung_coefficients] <-
  endorsement_model$coefficients[samsung_coefficients] +
  celebrity_effect


# -------------------------------------------------------------------
# 6. Predict market shares after endorsement
# -------------------------------------------------------------------

endorsement_shares <- colMeans(
  predict(
    endorsement_model,
    newdata = mdat1
  )
)

names(endorsement_shares) <- phone_names


share_comparison <- tibble(
  phone = phone_names,
  baseline_share = baseline_shares,
  endorsement_share = endorsement_shares
) |>
  mutate(
    share_change = endorsement_share - baseline_share,
    percentage_point_change = share_change * 100
  )

share_comparison


# -------------------------------------------------------------------
# 7. Visualize simulated demand effect
# -------------------------------------------------------------------

share_plot_data <- bind_rows(
  tibble(
    scenario = "No Endorsement",
    phone = phone_names,
    market_share = baseline_shares
  ),
  tibble(
    scenario = "Celebrity Endorsement",
    phone = phone_names,
    market_share = endorsement_shares
  )
)

ggplot(
  share_plot_data,
  aes(
    x = phone,
    y = market_share,
    fill = scenario
  )
) +
  geom_col(
    position = "dodge"
  ) +
  labs(
    title = "Simulated Celebrity Endorsement Demand Effect",
    x = "Smartphone",
    y = "Predicted Market Share",
    fill = "Scenario"
  ) +
  theme_bw()


# -------------------------------------------------------------------
# 8. Calculate profitability after endorsement
# -------------------------------------------------------------------

endorsement_profit <- calculate_samsung_profit(
  endorsement_shares["S1"],
  endorsement_shares["S2"]
)

endorsement_profit


# -------------------------------------------------------------------
# 9. Calculate projected incremental profit
# -------------------------------------------------------------------

incremental_profit <-
  endorsement_profit$total_profit -
  baseline_profit$total_profit

incremental_profit


# Under the assumptions of this simulation, incremental profit represents
# the approximate maximum endorsement fee Samsung could pay before the
# partnership would cease to increase profit.
