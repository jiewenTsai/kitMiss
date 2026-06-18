#' 讀取 CSV 或 SAV 並修正 UTF-8
#' @return data.frame，已修正 UTF-8；SAV 標籤欄保留原型態
load_data_file <- function(path, name) {
  ext <- tolower(tools::file_ext(name))
  if (ext == "csv") {
    df <- tryCatch(
      readr::read_csv(path, show_col_types = FALSE,
                      locale = readr::locale(encoding = "UTF-8")),
      error = function(e) NULL
    )
    if (is.null(df)) {
      df <- tryCatch(
        readr::read_csv(path, show_col_types = FALSE,
                        locale = readr::locale(encoding = "BIG5")),
        error = function(e) NULL
      )
    }
    if (is.null(df)) {
      df <- readr::read_csv(path, show_col_types = FALSE,
                            locale = readr::locale(encoding = "Latin1"))
    }
  } else if (ext %in% c("sav", "zsav")) {
    df <- haven::read_sav(path)
  } else {
    stop("不支援的格式：", name)
  }
  fix_utf8_df(df)
}

#' missing code → NA，保留原始資料框結構
recode_missing <- function(df, codes = MISSING_CODES) {
  dplyr::mutate(df, dplyr::across(
    dplyr::where(is.numeric),
    ~ ifelse(. %in% codes, NA, .)
  ))
}

#' 匯出清理後 CSV（加回 release_id 並驗證列數）
#' @return list(ok, msg, df)
build_export_df <- function(release_id_vec, cleaned_df) {
  n_raw  <- length(release_id_vec)
  n_clean <- nrow(cleaned_df)
  if (n_raw != n_clean) {
    return(list(
      ok  = FALSE,
      msg = sprintf("列數不一致：release_id 有 %d 列，清理後資料有 %d 列", n_raw, n_clean),
      df  = NULL
    ))
  }
  n_na <- sum(is.na(release_id_vec))
  df_out <- dplyr::bind_cols(
    tibble::tibble(release_id = release_id_vec),
    cleaned_df
  )
  list(
    ok  = TRUE,
    msg = sprintf("release_id 非缺失筆數：%d / %d，列數一致：符合",
                  n_raw - n_na, n_raw),
    df  = df_out
  )
}

# ── 內部工具 ────────────────────────────────────────────────
fix_utf8_chr <- function(x) {
  if (!is.character(x)) return(x)
  iconv(as.character(x), from = "", to = "UTF-8", sub = "")
}

fix_utf8_df <- function(df) {
  dplyr::mutate(df, dplyr::across(dplyr::everything(), function(x) {
    if (inherits(x, "labelled") && is.numeric(x)) return(x)
    if (inherits(x, "labelled") || is.character(x) || is.factor(x))
      return(fix_utf8_chr(as.character(x)))
    x
  }))
}
