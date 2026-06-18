# 關閉 Shiny 自動載入套件 R/（避免函式進入錯誤環境）
options(shiny.autoload.r = FALSE)

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

source_dev_backend <- function(r_dir) {
  for (f in c("kit_theme.R", "miss_constants.R", "io_data.R",
              "miss_pipeline.R", "rbtest_run.R", "pklm_run.R", "ui_helpers.R")) {
    source(file.path(r_dir, f), local = FALSE)
  }
}

load_kitmiss_modules <- function() {
  if (exists("run_miss_pipeline", mode = "function")) {
    return(invisible(NULL))
  }

  r_dir <- find_dev_r_dir()
  if (!is.null(r_dir)) {
    source_dev_backend(r_dir)
    return(invisible(NULL))
  }

  if (requireNamespace("kitMiss", quietly = TRUE)) {
    getFromNamespace("load_kitmiss_backend", "kitMiss")(.GlobalEnv)
    return(invisible(NULL))
  }

  stop(
    "找不到 R/ 後端模組目錄。請安裝 kitMiss 套件，或從專案根目錄執行 shiny::runApp(\"app.R\")",
    call. = FALSE
  )
}

load_kitmiss_modules()
