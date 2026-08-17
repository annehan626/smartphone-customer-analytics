# Smartphone Customer Analytics
# 01 - Customer Segmentation
# Author: Anne Han
#
# Objective:
# Segment smartphone customers based on usage behavior using K-means
# clustering and visualize the resulting behavioral profiles.

library(tidyverse)

# -------------------------------------------------------------------
# 1. Load data
# -------------------------------------------------------------------

# Course-provided dataset is not included in the public repository.
# Place smartphone_customer_data.csv in the project directory to run.

cust_dat <- read_csv("smartphone_customer_data.csv")


# -------------------------------------------------------------------
# 2. Select behavioral variables
# -------------------------------------------------------------------

# This analysis focuses on social-media and gaming usage.
segment_data <- cust_dat |>
  select(social, gaming)


# -------------------------------------------------------------------
# 3. Standardize variables
# -------------------------------------------------------------------

# K-means is distance-based, so variables are standardized to prevent
# differences in measurement scale from disproportionately influencing
# cluster assignments.

segment_scaled <- segment_data |>
  scale() |>
  as_tibble()


# -------------------------------------------------------------------
# 4. Fit K-means clustering model
# -------------------------------------------------------------------

set.seed(3355)

k <- 3

kmeans_model <- kmeans(
  segment_scaled,
  centers = k,
  nstart = 25
)

# Add cluster assignments to the original behavioral data.
segmented_customers <- segment_data |>
  mutate(cluster = factor(kmeans_model$cluster))


# -------------------------------------------------------------------
# 5. Calculate cluster centroids in original units
# -------------------------------------------------------------------

cluster_centers <- segmented_customers |>
  group_by(cluster) |>
  summarize(
    social = mean(social),
    gaming = mean(gaming),
    .groups = "drop"
  )

cluster_centers


# -------------------------------------------------------------------
# 6. Label behavioral segments
# -------------------------------------------------------------------

segmented_customers <- segmented_customers |>
  mutate(
    segment = factor(
      cluster,
      levels = c("1", "2", "3"),
      labels = c(
        "High Social Users",
        "Light Users",
        "High Gaming Users"
      )
    )
  )


# -------------------------------------------------------------------
# 7. Visualize customer segments
# -------------------------------------------------------------------

ggplot() +
  geom_point(
    data = segmented_customers,
    aes(x = social, y = gaming, color = segment)
  ) +
  geom_point(
    data = cluster_centers,
    aes(x = social, y = gaming),
    size = 4
  ) +
  labs(
    title = "Customer Segments Based on Smartphone Usage Behavior",
    subtitle = "(Minutes/Week)",
    x = "Social Media Usage",
    y = "Gaming Usage",
    color = "Customer Segment"
  ) +
  scale_color_manual(
    values = c(
      "red1",
      "turquoise",
      "darkorchid1"
    )
  ) +
  theme_minimal() +
  theme(
    plot.subtitle = element_text(size = 9.75)
  )


# -------------------------------------------------------------------
# 8. Evaluate number of clusters using the elbow method
# -------------------------------------------------------------------

wss <- numeric(10)

for (i in 1:10) {
  set.seed(3355)

  model <- kmeans(
    segment_scaled,
    centers = i,
    nstart = 25
  )

  wss[i] <- model$tot.withinss
}

elbow_data <- tibble(
  k = 1:10,
  wss = wss
)

ggplot(elbow_data, aes(x = k, y = wss)) +
  geom_line() +
  geom_point(size = 3) +
  labs(
    title = "K-means Elbow Plot",
    x = "Number of Clusters (K)",
    y = "Within-Cluster Sum of Squares"
  ) +
  theme_minimal()
