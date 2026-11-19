# Select the EPA CSV interactively or pass its path to Rscript.
args <- commandArgs(trailingOnly = TRUE)
csv_path <- if (length(args) > 0) args[1] else file.choose()

water <- read.csv(csv_path, colClasses = "character")

dim(water)
c("PWSID", "HEALTH_FLAG") %in% names(water)

# Audit system identifiers.
ids <- trimws(water$PWSID)   # Removes leading and trailing whitespace from the copy in ids
missing_id <- is.na(ids) | ids == ""

sum(missing_id)

valid_ids <- ids[!missing_id]
repeated_ids <- unique(valid_ids[duplicated(valid_ids)])

length(repeated_ids)
sum(duplicated(valid_ids))
head(repeated_ids)

# Audit violation flag codes and missing values.
flag <- water$HEALTH_FLAG
table(flag, useNA = "always")

flag_trimmed <- trimws(flag)

na_count <- sum(is.na(flag_trimmed))
blank_count <- sum(flag_trimmed == "", na.rm = TRUE)

c(
  NA_values = na_count,
  blank_or_whitespace = blank_count,
  total_missing = na_count + blank_count
)

known_flag <- flag_trimmed %in% c("Yes", "No")

c(
  total_rows = nrow(water),
  recognized_flags = sum(known_flag),
  unrecognized_or_missing = sum(!known_flag)
)

yes_count <- sum(flag_trimmed[known_flag] == "Yes")
known_count <- sum(known_flag)

round(100 * yes_count / known_count, 2)

# Inspect state, activity, and system-type codes.
target_states <- c("IL", "IN", "MI", "MN", "NY", "OH", "PA", "WI")
state_code <- trimws(water$STATE_CODE)
state_counts <- table(state_code, useNA = "always")

target_counts <- state_counts[match(target_states, names(state_counts))]
target_counts[is.na(target_counts)] <- 0L
setNames(as.integer(target_counts), target_states)

sum(is.na(state_code) | state_code == "")

table(
  code = trimws(water$PWS_ACTIVITY_CODE),
  label = trimws(water$PWS_ACTIVITY_DESC),
  useNA = "ifany"
)

table(
  code = trimws(water$PWS_TYPE_CODE),
  label = trimws(water$PWS_TYPE_DESC),
  useNA = "ifany"
)

# Select active community systems in the eight states.
water_eight <- water[state_code %in% target_states, , drop = FALSE]
nrow(water_eight)

active_code <- trimws(water_eight$PWS_ACTIVITY_CODE)
water_active <- water_eight[active_code %in% "A", , drop = FALSE]
nrow(water_active)

type_code <- trimws(water_active$PWS_TYPE_CODE)
water_eligible <- water_active[type_code %in% "CWS", , drop = FALSE]
nrow(water_eligible)

c(
  full_download = nrow(water),
  eight_states = nrow(water_eight),
  active_in_eight_states = nrow(water_active),
  active_community_in_eight_states = nrow(water_eligible)
)

# Summarize flags by state, including reported-zero systems.
eligible_state <- trimws(water_eligible$STATE_CODE)

eligible_by_state <- table(factor(eligible_state, levels = target_states))
eligible_by_state

c(
  counted_by_state = sum(eligible_by_state),
  eligible_rows = nrow(water_eligible),
  difference = nrow(water_eligible) - sum(eligible_by_state)
)

eligible_flag <- trimws(water_eligible$HEALTH_FLAG)
flag_missing <- is.na(eligible_flag) | eligible_flag == ""
flag_unexpected <- !flag_missing & !(eligible_flag %in% c("Yes", "No"))

sum(flag_unexpected)

flag_group <- eligible_flag
flag_group[flag_missing] <- "Missing"

flag_by_state <- table(
  state = factor(eligible_state, levels = target_states),
  flag = factor(flag_group, levels = c("Yes", "No", "Missing"))
)

flag_by_state

rowSums(flag_by_state) - as.integer(eligible_by_state)

yes_by_state <- flag_by_state[, "Yes"]
no_by_state <- flag_by_state[, "No"]
known_by_state <- yes_by_state + no_by_state

known_by_state

has_known <- known_by_state > 0
pct_flagged <- setNames(rep(NA_real_, length(known_by_state)), names(known_by_state))

pct_flagged[has_known] <-
  100 * yes_by_state[has_known] / known_by_state[has_known]

state_summary <- data.frame(
  state = names(known_by_state),
  flagged_yes = as.integer(yes_by_state),
  flagged_no = as.integer(no_by_state),
  missing = as.integer(flag_by_state[, "Missing"]),
  known_flags = as.integer(known_by_state),
  pct_flagged = round(as.numeric(pct_flagged), 2)
)

state_summary

total_yes <- sum(state_summary$flagged_yes)
total_known <- sum(state_summary$known_flags)

c(
  flagged_yes = total_yes,
  known_flags = total_known,
  pct_flagged = round(100 * total_yes / total_known, 2)
)

# Audit reported population counts.
population_text <- trimws(water_eligible$POPULATION_SERVED_COUNT)
population_missing <- is.na(population_text) | population_text == ""

sum(population_missing)

population <- suppressWarnings(as.numeric(population_text))

population_status <- rep("Positive whole number", length(population))
population_status[!is.finite(population)] <- "Non-numeric or non-finite"
population_status[is.finite(population) & population != trunc(population)] <- "Fractional"
population_status[is.finite(population) & population < 0] <- "Negative"
population_status[is.finite(population) & population == 0] <- "Zero"
population_status[population_missing] <- "Missing"

population_audit <- table(factor(
  population_status,
  levels = c(
    "Missing", "Non-numeric or non-finite", "Negative",
    "Zero", "Fractional", "Positive whole number"
  )
))
population_audit

sum(population_audit) == nrow(water_eligible)

needs_review <- population_status != "Positive whole number"
head(water_eligible[needs_review, c("PWSID", "STATE_CODE", "POPULATION_SERVED_COUNT")], 10)

# Review reported-zero populations separately.
zero_population <- population_status == "Zero"

zero_review <- data.frame(
  system_id = water_eligible$PWSID[zero_population],
  state = eligible_state[zero_population],
  population_served = population[zero_population],
  health_flag = flag_group[zero_population]
)

zero_review[order(zero_review$state, zero_review$system_id), ]

zero_by_state <- table(
  state = factor(zero_review$state, levels = target_states),
  flag = factor(zero_review$health_flag, levels = c("Yes", "No", "Missing"))
)

zero_by_state
sum(zero_by_state)

# Group positive counts using project-defined boundaries.
size_labels <- c("1-1,000", "1,001-10,000", "More than 10,000")
positive_population <- population_status == "Positive whole number"

size_group <- rep(NA_character_, length(population))
size_group[positive_population] <- as.character(cut(
  population[positive_population],
  breaks = c(0, 1000, 10000, Inf),
  labels = size_labels,
  right = TRUE
))

zero_label <- "Reported zero population"
size_group[population_status == "Zero"] <- zero_label

water_eligible$size_group <- factor(
  size_group,
  levels = c(size_labels, zero_label)
)

size_counts <- table(water_eligible$size_group, useNA = "always")
size_counts

c(
  positive_size_groups = sum(size_counts[size_labels]),
  reported_zero = unname(size_counts[zero_label]),
  unassigned = sum(is.na(water_eligible$size_group)),
  total = sum(size_counts)
)

# Summarize flags within each population group.
flag_by_size <- table(
  size_group = water_eligible$size_group,
  flag = factor(flag_group, levels = c("Yes", "No", "Missing"))
)

flag_by_size

yes_by_size <- flag_by_size[, "Yes"]
no_by_size <- flag_by_size[, "No"]
known_by_size <- yes_by_size + no_by_size

pct_by_size <- rep(NA_real_, length(known_by_size))
has_known <- known_by_size > 0
pct_by_size[has_known] <- 100 * yes_by_size[has_known] / known_by_size[has_known]

size_summary <- data.frame(
  size_group = rownames(flag_by_size),
  flagged_yes = as.integer(yes_by_size),
  flagged_no = as.integer(no_by_size),
  missing = as.integer(flag_by_size[, "Missing"]),
  known_flags = as.integer(known_by_size),
  pct_flagged = round(pct_by_size, 2)
)

size_summary

colSums(size_summary[c("flagged_yes", "known_flags", "missing")])

# Summarize state and size combinations.
flag_by_state_size <- table(
  state = factor(eligible_state, levels = target_states),
  size_group = water_eligible$size_group,
  flag = factor(flag_group, levels = c("Yes", "No", "Missing"))
)

apply(flag_by_state_size, "flag", sum)

state_size_summary <- expand.grid(
  state = target_states,
  size_group = levels(water_eligible$size_group),
  stringsAsFactors = FALSE
)

state_size_summary$flagged_yes <- as.vector(flag_by_state_size[, , "Yes"])
state_size_summary$flagged_no <- as.vector(flag_by_state_size[, , "No"])
state_size_summary$missing <- as.vector(flag_by_state_size[, , "Missing"])

state_size_summary$known_flags <-
  state_size_summary$flagged_yes + state_size_summary$flagged_no

has_known <- state_size_summary$known_flags > 0
state_size_summary$pct_flagged <- NA_real_
state_size_summary$pct_flagged[has_known] <- round(
  100 * state_size_summary$flagged_yes[has_known] /
    state_size_summary$known_flags[has_known],
  2
)

positive_size_summary <- subset(state_size_summary, size_group %in% size_labels)
positive_size_summary[order(
  match(positive_size_summary$state, target_states),
  match(positive_size_summary$size_group, size_labels)
), ]

zero_size_summary <- subset(state_size_summary, size_group == zero_label)
zero_size_summary

# Model positive populations with known flags.
keep_model <- water_eligible$size_group %in% size_labels &
  flag_group %in% c("Yes", "No")

model_data <- data.frame(
  flagged = as.integer(flag_group[keep_model] == "Yes"),
  size_group = factor(water_eligible$size_group[keep_model], levels = size_labels),
  state = factor(eligible_state[keep_model], levels = target_states)
)

c(systems = nrow(model_data), flagged = sum(model_data$flagged))

# Adjust size-group odds for state.
size_model <- glm(
  flagged ~ size_group + state,
  data = model_data,
  family = binomial(link = "logit")
)

size_model$converged
nobs(size_model)

model_terms <- coef(summary(size_model))
size_terms <- model_terms[startsWith(rownames(model_terms), "size_group"), ]
estimate <- size_terms[, "Estimate"]
se <- size_terms[, "Std. Error"]

adjusted_size_results <- data.frame(
  size_group = size_labels[-1],
  odds_ratio = exp(estimate),
  lower_95 = exp(estimate - qnorm(0.975) * se),
  upper_95 = exp(estimate + qnorm(0.975) * se)
)

print(adjusted_size_results, row.names = FALSE, digits = 3)

# Compare the largest group with the middle group.
middle_ref_data <- model_data
middle_ref_data$size_group <- relevel(
  middle_ref_data$size_group,
  ref = size_labels[2]
)

middle_ref_model <- glm(
  flagged ~ size_group + state,
  data = middle_ref_data,
  family = binomial(link = "logit")
)

middle_ref_model$converged
nobs(middle_ref_model)

largest_term <- paste0("size_group", size_labels[3])
comparison <- coef(summary(middle_ref_model))[largest_term, ]
estimate <- comparison["Estimate"]
se <- comparison["Std. Error"]

largest_vs_middle <- exp(c(
  odds_ratio = unname(estimate),
  lower_95 = unname(estimate - qnorm(0.975) * se),
  upper_95 = unname(estimate + qnorm(0.975) * se)
))

round(largest_vs_middle, 3)

# Standardize predictions to the pooled state mix.
adjusted_pct <- setNames(numeric(length(size_labels)), size_labels)

for (group in size_labels) {
  prediction_data <- model_data[c("size_group", "state")]
  prediction_data$size_group <- factor(
    rep(group, nrow(prediction_data)),
    levels = size_labels
  )
  
  predicted_prob <- predict(size_model, newdata = prediction_data, type = "response")
  adjusted_pct[group] <- 100 * mean(predicted_prob)
}

round(adjusted_pct, 2)

observed <- size_summary[match(size_labels, size_summary$size_group), ]
observed_pct <- 100 * observed$flagged_yes / observed$known_flags

size_comparison <- data.frame(
  size_group = size_labels,
  flagged_yes = observed$flagged_yes,
  known_flags = observed$known_flags,
  observed_pct = round(observed_pct, 2),
  adjusted_pct = round(unname(adjusted_pct), 2),
  change_pp = round(unname(adjusted_pct) - observed_pct, 2)
)

print(size_comparison, row.names = FALSE)

subset(size_summary, size_group == zero_label)

# Calculate delta-method intervals on the log-odds scale.
model_cov <- vcov(size_model)
critical_value <- qnorm(0.975)

adjusted_size_ci <- data.frame(
  size_group = size_labels,
  adjusted_pct = unname(adjusted_pct[size_labels]),
  lower_95 = NA_real_,
  upper_95 = NA_real_
)

for (i in seq_along(size_labels)) {
  prediction_data <- model_data[c("size_group", "state")]
  prediction_data$size_group <- factor(
    rep(size_labels[i], nrow(prediction_data)),
    levels = size_labels
  )
  predicted_prob <- predict(size_model, newdata = prediction_data, type = "response")
  mean_prob <- mean(predicted_prob)
  
  design <- model.matrix(
    delete.response(terms(size_model)),
    data = prediction_data,
    contrasts.arg = size_model$contrasts
  )
  design <- design[, colnames(model_cov), drop = FALSE]
  gradient <- colMeans(design * (predicted_prob * (1 - predicted_prob)))
  
  se_prob <- sqrt(drop(t(gradient) %*% model_cov %*% gradient))
  se_logit <- se_prob / (mean_prob * (1 - mean_prob))
  
  limits <- 100 * plogis(
    qlogis(mean_prob) + c(-1, 1) * critical_value * se_logit
  )
  adjusted_size_ci$lower_95[i] <- limits[1]
  adjusted_size_ci$upper_95[i] <- limits[2]
}

ci_display <- adjusted_size_ci
ci_display[2:4] <- round(ci_display[2:4], 2)
print(ci_display, row.names = FALSE)

subset(size_summary, size_group == zero_label)

# Prepare observed and adjusted values for the figure.
observed_plot <- size_comparison[
  match(size_labels, size_comparison$size_group), ]
adjusted_plot <- adjusted_size_ci[
  match(size_labels, adjusted_size_ci$size_group), ]

# Save the figure relative to the working directory.
dir.create("figures", showWarnings = FALSE)
figure_path <- file.path("figures", "violation-percentages-by-size.png")
x <- seq_along(size_labels)
blue <- "#0072B2"

local({
  png(figure_path, width = 2400, height = 1500, res = 300, bg = "white")
  png_device <- dev.cur()
  on.exit(dev.off(png_device))
  
  plot(
    x, adjusted_plot$adjusted_pct,
    type = "n", xaxt = "n", xaxs = "i", yaxs = "i",
    xlim = c(0.5, length(x) + 0.5),
    ylim = c(0, 1.2 * max(adjusted_plot$upper_95, observed_plot$observed_pct)),
    xlab = "People served", ylab = "Systems flagged (%)",
    main = "Reported health-based violations by system size"
  )
  axis(1, at = x, labels = size_labels)
  abline(h = axTicks(2), col = "grey90")
  
  arrows(
    x - 0.12, adjusted_plot$lower_95,
    x - 0.12, adjusted_plot$upper_95,
    angle = 90, code = 3, length = 0.06, col = blue, lwd = 2
  )
  points(x - 0.12, adjusted_plot$adjusted_pct, pch = 19, col = blue, cex = 1.3)
  points(x + 0.12, observed_plot$observed_pct, pch = 1, lwd = 2, cex = 1.3)
  
  legend(
    "topright", legend = c("Observed", "State-adjusted (95% CI)"),
    pch = c(1, 19), col = c("black", blue), bty = "n"
  )
})
# Export summaries for Power BI.
export_dir <- "power_bi_exports"
dir.create(export_dir, showWarnings = FALSE)
write.csv(state_summary, file.path(export_dir, "observed_by_state.csv"),
          row.names = FALSE, na = "")

# Export positive population groups.
positive_size <- size_summary[match(size_labels, size_summary$size_group), ]
write.csv(positive_size, file.path(export_dir, "observed_by_size.csv"),
          row.names = FALSE, na = "")
write.csv(positive_size_summary,
          file.path(export_dir, "observed_by_state_and_size.csv"),
          row.names = FALSE, na = "")
write.csv(adjusted_size_ci, file.path(export_dir, "adjusted_by_size.csv"),
          row.names = FALSE, na = "")

# Export reported-zero results separately.
write.csv(zero_size_summary, file.path(export_dir, "reported_zero_by_state.csv"),
          row.names = FALSE, na = "")


# Record the input filename and its content fingerprint.
dir.create("metadata", showWarnings = FALSE)

input_record <- data.frame(
  input_file = basename(csv_path),
  md5 = unname(tools::md5sum(csv_path)),
  rows = nrow(water),
  columns = ncol(water)
)

write.csv(input_record, "metadata/input_file.csv", row.names = FALSE)

# Record the R version, platform, and loaded packages.
writeLines(capture.output(sessionInfo()), "metadata/session-info.txt")