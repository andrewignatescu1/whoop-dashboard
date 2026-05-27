# R/load_data.R
# Shared data loading, cleaning, and feature engineering for all pages.
# Source this at the top of each .qmd with: source("R/load_data.R")

library(tidyverse)
library(lubridate)
library(zoo)

# ── Raw imports ────────────────────────────────────────────────────────────────

cycles_raw <- read_csv("data/physiological_cycles.csv", show_col_types = FALSE)
sleeps_raw <- read_csv("data/sleeps.csv",               show_col_types = FALSE)
workouts_raw <- read_csv("data/workouts.csv",           show_col_types = FALSE)

# ── Cycles / daily physiology ──────────────────────────────────────────────────

cycles <- cycles_raw |>
  rename(
    cycle_start   = `Cycle start time`,
    cycle_end     = `Cycle end time`,
    timezone      = `Cycle timezone`,
    recovery      = `Recovery score %`,
    rhr           = `Resting heart rate (bpm)`,
    hrv           = `Heart rate variability (ms)`,
    skin_temp     = `Skin temp (celsius)`,
    spo2          = `Blood oxygen %`,
    day_strain    = `Day Strain`,
    energy_cal    = `Energy burned (cal)`,
    max_hr        = `Max HR (bpm)`,
    avg_hr        = `Average HR (bpm)`,
    sleep_onset   = `Sleep onset`,
    wake_onset    = `Wake onset`,
    sleep_perf    = `Sleep performance %`,
    resp_rate     = `Respiratory rate (rpm)`,
    asleep_min    = `Asleep duration (min)`,
    inbed_min     = `In bed duration (min)`,
    light_min     = `Light sleep duration (min)`,
    deep_min      = `Deep (SWS) duration (min)`,
    rem_min       = `REM duration (min)`,
    awake_min     = `Awake duration (min)`,
    sleep_need    = `Sleep need (min)`,
    sleep_debt    = `Sleep debt (min)`,
    sleep_eff     = `Sleep efficiency %`,
    sleep_consist = `Sleep consistency %`
  ) |>
  mutate(
    date         = as_date(cycle_start),
    week         = floor_date(date, "week"),
    month        = floor_date(date, "month"),
    month_label  = format(date, "%b %Y"),
    day_of_week  = wday(date, label = TRUE, abbr = TRUE),
    # 7-day rolling averages (align = right, min 3 obs)
    recovery_7   = rollmean(recovery,    7, fill = NA, align = "right", na.rm = TRUE),
    hrv_7        = rollmean(hrv,         7, fill = NA, align = "right", na.rm = TRUE),
    rhr_7        = rollmean(rhr,         7, fill = NA, align = "right", na.rm = TRUE),
    strain_7     = rollmean(day_strain,  7, fill = NA, align = "right", na.rm = TRUE),
    # Sleep totals in hours
    asleep_hr    = asleep_min / 60,
    inbed_hr     = inbed_min  / 60,
    # Recovery zones (WHOOP convention)
    rec_zone     = case_when(
      recovery >= 67 ~ "Green",
      recovery >= 34 ~ "Yellow",
      !is.na(recovery) ~ "Red",
      TRUE ~ NA_character_
    ) |> factor(levels = c("Green", "Yellow", "Red"))
  ) |>
  filter(!is.na(recovery)) |>
  arrange(date)

# ── Sleeps (includes naps) ─────────────────────────────────────────────────────

sleeps <- sleeps_raw |>
  rename(
    cycle_start  = `Cycle start time`,
    sleep_onset  = `Sleep onset`,
    wake_onset   = `Wake onset`,
    sleep_perf   = `Sleep performance %`,
    resp_rate    = `Respiratory rate (rpm)`,
    asleep_min   = `Asleep duration (min)`,
    inbed_min    = `In bed duration (min)`,
    light_min    = `Light sleep duration (min)`,
    deep_min     = `Deep (SWS) duration (min)`,
    rem_min      = `REM duration (min)`,
    awake_min    = `Awake duration (min)`,
    sleep_need   = `Sleep need (min)`,
    sleep_debt   = `Sleep debt (min)`,
    sleep_eff    = `Sleep efficiency %`,
    sleep_consist = `Sleep consistency %`,
    is_nap       = Nap
  ) |>
  mutate(
    date         = as_date(cycle_start),
    month        = floor_date(date, "month"),
    month_label  = format(date, "%b %Y"),
    is_nap       = as.logical(is_nap),
    asleep_hr    = asleep_min / 60
  ) |>
  arrange(date)

# Main overnight sleeps only
main_sleeps <- sleeps |> filter(!is_nap | is.na(is_nap))

# Monthly sleep stage averages
monthly_sleep <- main_sleeps |>
  filter(!is.na(light_min)) |>
  group_by(month, month_label) |>
  summarise(
    light_avg  = mean(light_min,  na.rm = TRUE),
    deep_avg   = mean(deep_min,   na.rm = TRUE),
    rem_avg    = mean(rem_min,    na.rm = TRUE),
    awake_avg  = mean(awake_min,  na.rm = TRUE),
    n_nights   = n(),
    .groups = "drop"
  ) |>
  arrange(month)

# ── Workouts ──────────────────────────────────────────────────────────────────

workouts <- workouts_raw |>
  rename(
    cycle_start  = `Cycle start time`,
    cycle_end    = `Cycle end time`,
    timezone     = `Cycle timezone`,
    workout_start = `Workout start time`,
    workout_end  = `Workout end time`,
    duration_min = `Duration (min)`,
    activity     = `Activity name`,
    w_strain     = `Activity Strain`,
    energy_cal   = `Energy burned (cal)`,
    max_hr       = `Max HR (bpm)`,
    avg_hr       = `Average HR (bpm)`,
    z1           = `HR Zone 1 %`,
    z2           = `HR Zone 2 %`,
    z3           = `HR Zone 3 %`,
    z4           = `HR Zone 4 %`,
    z5           = `HR Zone 5 %`,
    gps          = `GPS enabled`
  ) |>
  mutate(
    date         = as_date(cycle_start),
    month        = floor_date(date, "month"),
    workout_hour = hour(ymd_hms(workout_start, quiet = TRUE)),
    duration_hr  = duration_min / 60,
    # Consolidate minor activities
    activity_grp = case_when(
      activity == "Swimming"     ~ "Swimming",
      activity == "Weightlifting" | activity == "Strength Trainer" ~ "Lifting",
      activity == "Running"      ~ "Running",
      activity == "Basketball"   ~ "Basketball",
      TRUE                       ~ "Other"
    ) |> factor(levels = c("Swimming", "Lifting", "Running", "Basketball", "Other"))
  ) |>
  arrange(date)

# Join same-day recovery to workouts
workouts <- workouts |>
  left_join(cycles |> select(date, recovery, rec_zone, hrv, rhr), by = "date")

# ── Summary stats (used on overview page) ─────────────────────────────────────

n_days        <- nrow(cycles)
date_range    <- paste(format(min(cycles$date), "%b %Y"), "–", format(max(cycles$date), "%b %Y"))
avg_recovery  <- round(mean(cycles$recovery, na.rm = TRUE))
avg_hrv       <- round(mean(cycles$hrv,      na.rm = TRUE))
avg_rhr       <- round(mean(cycles$rhr,      na.rm = TRUE))
n_workouts    <- nrow(workouts)
n_swims       <- sum(workouts$activity == "Swimming")
peak_hrv      <- max(cycles$hrv, na.rm = TRUE)
peak_hrv_date <- cycles$date[which.max(cycles$hrv)]

# ── Shared ggplot theme ────────────────────────────────────────────────────────

theme_whoop <- function() {
  theme_minimal(base_size = 13) +
    theme(
      plot.title       = element_text(size = 14, face = "bold", margin = margin(b = 4)),
      plot.subtitle    = element_text(size = 11, color = "grey50", margin = margin(b = 10)),
      plot.caption     = element_text(size = 9,  color = "grey60", hjust = 0),
      axis.title       = element_text(size = 10, color = "grey40"),
      axis.text        = element_text(size = 9,  color = "grey50"),
      panel.grid.major = element_line(color = "grey93"),
      panel.grid.minor = element_blank(),
      legend.position  = "bottom",
      legend.text      = element_text(size = 9),
      strip.text       = element_text(face = "bold", size = 10)
    )
}

# Palette
WHOOP_COLS <- c(
  green  = "#1D9E75",
  blue   = "#3266ad",
  red    = "#E24B4A",
  amber  = "#BA7517",
  purple = "#7F77DD",
  gray   = "#888780"
)
