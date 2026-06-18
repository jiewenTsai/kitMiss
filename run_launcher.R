# kitMiss Windows 啟動腳本：檢查並安裝相依套件，啟動 Shiny App
options(repos = c(CRAN = "https://cloud.r-project.org"))
options(shiny.maxRequestSize = 500 * 1024^2)
options(shiny.autoload.r = FALSE)

get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", args[grep("^--file=", args)])
  if (length(f) > 0) {
    return(dirname(normalizePath(f[1], winslash = "/")))
  }
  normalizePath(getwd(), winslash = "/")
}

install_if_missing <- function(pkgs) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) == 0) {
    return(invisible(NULL))
  }
  message("正在安裝缺少的套件：", paste(missing, collapse = ", "))
  tryCatch(
    install.packages(missing, dependencies = TRUE),
    error = function(e) {
      stop(
        "套件安裝失敗：", conditionMessage(e),
        "\n請確認已安裝 R 且網路連線正常，或手動執行 install.packages()。",
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

root <- get_script_dir()
setwd(root)

pkgs <- c(
  "shiny", "bslib", "dplyr", "readr", "haven",
  "naniar", "ggplot2", "caret", "tibble",
  "RBtest", "PKLMtest"
)

message("檢查相依套件…")
install_if_missing(pkgs)

app_dir <- file.path(root, "inst", "shiny-app")
if (!dir.exists(app_dir)) {
  stop("找不到 Shiny App 目錄：", app_dir, call. = FALSE)
}

message("啟動 KIT 缺失機制檢定工具…")
message("（關閉此視窗或按 Ctrl+C 可停止 App）")

shiny::runApp(
  appDir         = app_dir,
  launch.browser = TRUE
)
