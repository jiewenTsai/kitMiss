#' 將後端函式與常數載入 Shiny app 環境
#'
#' 套件安裝後 R/ 原始碼不會保留在磁碟，需從 namespace 取出供 Shiny 使用。
#' @param envir 目標環境，預設為 global environment
#' @keywords internal
load_kitmiss_backend <- function(envir = .GlobalEnv) {
  ns <- asNamespace("kitMiss")
  objs <- c(
    "MISSING_CODES", "DROP_ITEMS", "GROW_PATTERN",
    "parse_var_list", "default_exclude_text", "run_miss_pipeline",
    "load_data_file", "recode_missing", "build_export_df",
    "run_rbtest", "pilot_pklm", "run_pklm",
    "kit_theme", "kit_colors", "kit_css", "kit_header",
    "show_busy_modal"
  )
  for (nm in objs) {
    assign(nm, get(nm, envir = ns, inherits = FALSE), envir = envir)
  }
  invisible(NULL)
}
