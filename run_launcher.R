# kitMiss Windows 啟動腳本：檢查並安裝相依套件，啟動 Shiny App
options(repos = c(CRAN = "https://cloud.r-project.org"))
options(shiny.maxRequestSize = 500 * 1024^2)
options(shiny.autoload.r = FALSE)

log_path <- NULL

log_msg <- function(...) {
  line <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  ", paste(..., collapse = " "))
  message(line)
  if (!is.null(log_path)) {
    cat(line, "\n", file = log_path, append = TRUE)
  }
}

get_project_root <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 1 && nzchar(args[1])) {
    return(normalizePath(args[1], winslash = "/", mustWork = TRUE))
  }
  file_arg <- sub("^--file=", "", commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))])
  if (length(file_arg) >= 1 && nzchar(file_arg[1])) {
    return(dirname(normalizePath(file_arg[1], winslash = "/")))
  }
  normalizePath(getwd(), winslash = "/")
}

install_if_missing <- function(pkgs) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) == 0) {
    return(invisible(NULL))
  }
  log_msg("正在安裝缺少的套件：", paste(missing, collapse = ", "))
  tryCatch(
    install.packages(missing, dependencies = TRUE),
    error = function(e) {
      stop(
        "套件安裝失敗：", conditionMessage(e),
        "\n請確認已安裝 R 且網路連線正常。",
        call. = FALSE
      )
    }
  )
  still_missing <- missing[!vapply(missing, requireNamespace, logical(1), quietly = TRUE)]
  if (length(still_missing) > 0) {
    stop(
      "以下套件仍無法載入：", paste(still_missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(NULL)
}

run_app <- function() {
  root <- get_project_root()
  log_path <<- file.path(root, "kitmiss_log.txt")
  cat("", file = log_path)

  log_msg("專案目錄：", root)
  setwd(root)

  pkgs <- c(
    "shiny", "bslib", "dplyr", "readr", "haven",
    "naniar", "ggplot2", "caret", "tibble",
    "RBtest", "PKLMtest"
  )

  log_msg("檢查相依套件…")
  install_if_missing(pkgs)

  app_dir <- file.path(root, "inst", "shiny-app")
  if (!dir.exists(app_dir)) {
    stop("找不到 Shiny App 目錄：", app_dir, call. = FALSE)
  }

  log_msg("啟動 Shiny App…")
  log_msg("（關閉此視窗或按 Ctrl+C 可停止 App）")

  shiny::runApp(
    appDir         = app_dir,
    launch.browser = TRUE
  )
}

status <- tryCatch(
  {
    run_app()
    0L
  },
  error = function(e) {
    if (is.null(log_path)) {
      log_path <<- file.path(getwd(), "kitmiss_log.txt")
    }
    log_msg("錯誤：", conditionMessage(e))
    1L
  }
)

quit(save = "no", status = status)
