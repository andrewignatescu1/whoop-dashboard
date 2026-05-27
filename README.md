# WHOOP Biometrics Dashboard

A personal biometrics explorer built with **Quarto** and **R**, analyzing 13 months of physiological data from the WHOOP 4.0 wearable (March 2023 – April 2024).

Analytical approach inspired by [*Functional Data Analysis with R*](https://www.routledge.com/Functional-Data-Analysis-with-R/Goldsmith-Scheipl-Huang-Wrobel-Di-Gellar-Hasenstab-Crainiceanu/p/book/9781032229089) (Goldsmith et al., 2024).

## Pages

| Page | Description |
|---|---|
| Overview | Summary metrics, recovery timeline, zone composition |
| Recovery & HRV | HRV trajectories, RHR trends, day-of-week patterns |
| Sleep | Stage composition, sleep debt, sleep→recovery lag |
| Workouts | Swimming analysis, timing patterns, strain vs. recovery |
| Methods | Data provenance, processing notes, rendering instructions |

## Setup

### Prerequisites

- [R](https://cran.r-project.org/) ≥ 4.2
- [Quarto](https://quarto.org/docs/get-started/) ≥ 1.3
- [RStudio](https://posit.co/download/rstudio-desktop/) (recommended)

### Install R packages

```r
install.packages(c(
  "tidyverse", "lubridate", "zoo",
  "patchwork", "ggridges", "glue",
  "htmltools", "scales"
))
```

### Add your data

Place your WHOOP CSV exports in the `data/` folder:

```
data/
  physiological_cycles.csv
  sleeps.csv
  workouts.csv
```

Export from: WHOOP app → Account → My Data → Export

### Render

```bash
# Preview locally
quarto preview

# Full render to docs/
quarto render
```

## Deploy to GitHub Pages

1. Push repo to GitHub
2. Settings → Pages → Source → Deploy from branch
3. Branch: `main` | Folder: `/docs`
4. Save → site live at `https://<username>.github.io/<repo>/`

## Project structure

```
whoop-dashboard/
├── _quarto.yml          # Site config, navbar, output dir
├── styles.css           # Custom CSS (metric cards, theme)
├── index.qmd            # Overview page
├── recovery.qmd         # Recovery & HRV page
├── sleep.qmd            # Sleep analysis page
├── workouts.qmd         # Workouts page
├── methods.qmd          # Methods & data notes
├── R/
│   └── load_data.R      # Shared data loading + theme
├── data/
│   ├── physiological_cycles.csv
│   ├── sleeps.csv
│   └── workouts.csv
└── docs/                # Rendered output (git-tracked for GH Pages)
```
