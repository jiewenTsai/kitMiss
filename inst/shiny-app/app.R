options(shiny.maxRequestSize = 500 * 1024^2)
options(shiny.autoload.r = FALSE)

library(shiny)
library(bslib)
library(dplyr)
library(readr)
library(haven)
library(naniar)
library(ggplot2)
library(RBtest)
library(PKLMtest)

# global.R 已載入後端模組；若直接 source app.R 則在此補載
if (!exists("run_miss_pipeline", mode = "function")) {
  find_dev_r_dir <- function() {
    candidates <- c(
      normalizePath(file.path(getwd(), "R"), mustWork = FALSE),
      normalizePath(file.path(getwd(), "..", "..", "R"), mustWork = FALSE)
    )
    hits <- candidates[
      dir.exists(candidates) &
        file.exists(file.path(candidates, "kit_theme.R"))
    ]
    if (length(hits) == 0) return(NULL)
    hits[1]
  }

  r_dir <- find_dev_r_dir()
  if (!is.null(r_dir)) {
    for (f in c("kit_theme.R", "miss_constants.R", "io_data.R",
                "miss_pipeline.R", "rbtest_run.R", "pklm_run.R", "ui_helpers.R")) {
      source(file.path(r_dir, f), local = FALSE)
    }
  } else if (requireNamespace("kitMiss", quietly = TRUE)) {
    getFromNamespace("load_kitmiss_backend", "kitMiss")(.GlobalEnv)
  } else {
    stop("找不到 R/ 後端模組目錄", call. = FALSE)
  }
}

source("ui.R",     local = FALSE)
source("server.R", local = FALSE)

shinyApp(ui, server)
