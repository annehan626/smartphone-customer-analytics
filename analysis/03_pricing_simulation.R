# Smartphone Customer Analytics
# 03 - Pricing & Competitive Simulation
# Author: Anne Han
#
# Objective:
# Use an estimated multinomial logit (MNL) choice model to simulate
# how changes in the price of Samsung S1 affect customer demand,
# competitive market shares, and Samsung smartphone profitability.

library(tidyverse)
library(mlogit)


# -------------------------------------------------------------------
# 1. Load prepared choice data
# -------------------------------------------------------------------

# The course-provided formatted choice dataset is not distributed in
# this public repository.
#
# mdat1 contains the MNL-formatted choice data.
# sub1 contains the corresponding smartphone alternatives and customer
# characteristics used for prediction.

load("mnl_datasets.RData")


# -------------------------------------------------------------------
# 2. Fit heterogeneous MNL model
# -------------------------------------------------------------------

# Preferences for brand, price, and screen size vary across behavioral
# customer segments. Price sensitivity also varies with smartphone
# usage intensity.

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


# -------------------------------------------------------------------
# 3. Simulate S1 price changes
# -------------------------------------------------------------------

s1_current_price <- 799
s2_current_price <- 899

# Evaluate S1 price changes from -$200 to +$200 in $10 increments.
price_changes <- seq(
  from = -200,
  to = 200,
  by = 10
)

phone_names <- c(
  "A1", "A2", "S1", "S2", "H1", "H2"
)

market_shares <- matrix(
  NA_real_,
  nrow = length(price_changes),
  ncol = length(phone_names),
  dimnames = list(NULL, phone_names)
)


for (i in seq_along(price_changes)) {

  price_change <- price_changes[i]

  # Hold all other product attributes and prices constant while
  # changing only the price of Samsung S1.
  scenario_data <- as_tibble(sub1) |>
    mutate(
      price = if_else(
        phone_id == "S1",
        price + price_change,
        price
      )
    )

  # Predict each customer's probability of choosing each phone.
  predicted_probabilities <- predict(
    choice_model,
    newdata = scenario_data
  )

  # Average customer-level probabilities to obtain predicted
  # market shares for each smartphone.
  market_shares[i, ] <- colMeans(predicted_probabilities)
}


# -------------------------------------------------------------------
# 4. Organize market-share simulation results
# -------------------------------------------------------------------

share_results <- as_tibble(market_shares) |>
  mutate(
    s1_price = s1_current_price + price_changes,
    .before = 1
  )

share_results


# -------------------------------------------------------------------
# 5. Visualize competitive substitution
# -------------------------------------------------------------------

share_plot_data <- share_results |>
  pivot_longer(
    cols = all_of(phone_names),
    names_to = "phone",
    values_to = "market_share"
  )

ggplot(
  share_plot_data,
  aes(
    x = s1_price,
    y = market_share,
    color = phone
  )
) +
  geom_line() +
  geom_point() +
  labs(
    title = "Estimated Market Share Response to S1 Price Changes",
    x = "S1 Price ($)",
    y = "Market Share",
    color = "Phone"
  ) +
  xlim(650, 950) +
  ylim(0, 0.5) +
  theme_bw()


# -------------------------------------------------------------------
# 6. Estimate S1 and S2 profitability
# -------------------------------------------------------------------

# The simulation assumes a target market of 10 million smartphones.
# Quantities are therefore measured in millions of phones, making the
# resulting revenue, cost, and profit values millions of dollars.

market_size <- 10

# Assumed marginal costs per phone.
s1_marginal_cost <- 470
s2_marginal_cost <- 490


pricing_results <- share_results |>
  transmute(
    s1_price = s1_price,
    s1_share = S1,
    s2_price = s2_current_price,
    s2_share = S2,

    s1_quantity = s1_share * market_size,
    s2_quantity = s2_share * market_size,

    s1_revenue = s1_price * s1_quantity,
    s2_revenue = s2_price * s2_quantity,

    s1_cost = s1_marginal_cost * s1_quantity,
    s2_cost = s2_marginal_cost * s2_quantity,

    s1_profit = s1_revenue - s1_cost,
    s2_profit = s2_revenue - s2_cost,

    total_profit = s1_profit + s2_profit
  )


# -------------------------------------------------------------------
# 7. Identify profit-maximizing S1 price
# -------------------------------------------------------------------

current_pricing <- pricing_results |>
  filter(s1_price == s1_current_price)

optimal_pricing <- pricing_results |>
  filter(total_profit == max(total_profit))

current_pricing |>
  select(
    s1_price,
    s2_price,
    total_profit
  )

optimal_pricing |>
  select(
    s1_price,
    s2_price,
    total_profit
  )


# -------------------------------------------------------------------
# 8. Calculate projected profit improvement
# -------------------------------------------------------------------

profit_improvement <-
  optimal_pricing$total_profit -
  current_pricing$total_profit

profit_improvement
