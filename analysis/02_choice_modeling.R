# Smartphone Customer Analytics
# 02 - Smartphone Choice Modeling
# Author: Anne Han
#
# Objective:
# Estimate smartphone purchase probabilities using multinomial logit (MNL)
# models and evaluate whether incorporating customer heterogeneity improves
# predictive performance.

library(tidyverse)
library(mlogit)


# -------------------------------------------------------------------
# 1. Load prepared MNL dataset
# -------------------------------------------------------------------

# The course-provided formatted choice dataset is not distributed in
# this public repository.
#
# mdat1 contains customers who purchased smartphones one year ago,
# with six available smartphone alternatives per customer.

load("mnl_datasets.RData")


# -------------------------------------------------------------------
# 2. Define model evaluation function
# -------------------------------------------------------------------

# Brand hit rate measures the proportion of observed customer brand
# choices correctly predicted by the model.
#
# Each customer chooses among six phones:
# A1, A2, S1, S2, H1, H2
# where each pair corresponds to Apple, Samsung, or Huawei.

brand_hit_rate <- function(data, model) {

  predicted_phone <- apply(
    predict(model, newdata = data),
    1,
    which.max
  )

  actual_phone <- apply(
    matrix(data$choice, ncol = 6, byrow = TRUE),
    1,
    which.max
  )

  # Convert six product alternatives into three brand categories.
  predicted_brand <- ceiling(predicted_phone / 2)
  actual_brand <- ceiling(actual_phone / 2)

  mean(predicted_brand == actual_brand)
}


# -------------------------------------------------------------------
# 3. Initial heterogeneous choice model
# -------------------------------------------------------------------

# This specification allows brand, price, and screen-size preferences
# to vary across customer segments and allows price sensitivity to vary
# with both smartphone usage intensity and segment membership.

initial_model <- mlogit(
  choice ~
    apple:segment +
    samsung:segment +
    price:segment +
    screen_size:segment +
    price:total_minutes:segment |
    0,
  data = mdat1
)

summary(initial_model)

initial_accuracy <- brand_hit_rate(
  mdat1,
  initial_model
)

initial_accuracy


# -------------------------------------------------------------------
# 4. Enhanced behavioral choice model
# -------------------------------------------------------------------

# The enhanced specification introduces additional interactions among
# product attributes, brand, customer usage intensity, and behavioral
# segment to capture more flexible preference heterogeneity.

enhanced_model <- mlogit(
  choice ~
    price +
    screen_size +
    apple:segment +
    samsung:segment +
    price:segment +
    screen_size:segment +
    price:total_minutes:segment +
    screen_size:total_minutes +
    apple:price +
    samsung:price +
    apple:price:total_minutes:segment +
    samsung:price:total_minutes:segment |
    0,
  data = mdat1
)

summary(enhanced_model)

enhanced_accuracy <- brand_hit_rate(
  mdat1,
  enhanced_model
)

enhanced_accuracy


# -------------------------------------------------------------------
# 5. Compare predictive performance
# -------------------------------------------------------------------

model_comparison <- tibble(
  model = c(
    "Initial Segmented Model",
    "Enhanced Behavioral Model"
  ),
  brand_accuracy = c(
    initial_accuracy,
    enhanced_accuracy
  )
)

model_comparison


# Report improvement in percentage points.
accuracy_improvement <-
  (enhanced_accuracy - initial_accuracy) * 100

accuracy_improvement
