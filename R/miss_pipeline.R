#' 解析逗號分隔的變項名稱文字
#' @return character vector（去空白）
parse_var_list <- function(text) {
  if (is.null(text) || !nzchar(trimws(text))) return(character(0))
  v <- strsplit(text, "[,\\n]+")[[1]]
  trimws(v[nzchar(trimws(v))])
}

#' 從原始資料計算排除框的預填字串
#' 含 drop_items 中實際存在的欄 + grow 正則匹配欄
default_exclude_text <- function(dat) {
  grow_cols <- grep(GROW_PATTERN, names(dat), value = TRUE)
  present   <- intersect(DROP_ITEMS, names(dat))
  all_drop  <- unique(c(present, grow_cols))
  paste(all_drop, collapse = ", ")
}

#' 執行逐步清理管線
#'
#' @param dat        原始 data.frame（已 recode missing codes）
#' @param user_drop  character vector，使用者額外指定要排除的欄名
#' @param miss_thresh 缺失率門檻，預設 0.5
#' @return list:
#'   $X_df        分析用 data.frame（全數值）
#'   $X_mat       as.matrix(X_df)
#'   $release_id  原始識別向量（長度 = nrow(dat)）
#'   $steps       tibble：各階段步驟摘要
#'   $dropped     list：各階段排除的欄名
run_miss_pipeline <- function(dat, user_drop = character(), miss_thresh = 0.5) {
  n0 <- ncol(dat)

  # 保留識別欄（不論有無此欄）
  release_id <- if ("release_id" %in% names(dat)) dat$release_id else NULL

  # Step 1 排除行政資料 + grow 正則 + 使用者自訂
  grow_cols   <- grep(GROW_PATTERN, names(dat), value = TRUE)
  auto_drop   <- unique(c(DROP_ITEMS, grow_cols))
  all_drop    <- unique(c(auto_drop, user_drop))
  dropped_admin <- intersect(all_drop, names(dat))
  X <- dplyr::select(dat, -dplyr::any_of(all_drop))
  n1 <- ncol(X)

  # Step 2 移除 attrition + 數值化（同 notebook Cell 6）
  X <- dplyr::select(X, -dplyr::any_of("attrition"))
  suppressWarnings({
    X <- dplyr::mutate(X,
      dplyr::across(dplyr::where(is.factor),    as.integer),
      dplyr::across(dplyr::where(is.character), as.integer)
    )
  })
  X <- dplyr::select(X, dplyr::where(is.numeric))

  # Step 3 >50% 缺失篩選
  miss_rate <- colMeans(is.na(X))
  dropped_miss <- names(X)[miss_rate >= miss_thresh]
  X <- X[, miss_rate < miss_thresh, drop = FALSE]
  n2 <- ncol(X)

  # Step 4 NZV
  nzv_idx <- caret::nearZeroVar(X)
  dropped_nzv <- if (length(nzv_idx) > 0) names(X)[nzv_idx] else character(0)
  if (length(nzv_idx) > 0) X <- X[, -nzv_idx, drop = FALSE]
  n3 <- ncol(X)

  steps <- tibble::tibble(
    步驟 = c(
      "原始變項數",
      "排除行政資料後",
      sprintf("排除 >%d%% 缺失後", as.integer(miss_thresh * 100)),
      "排除 NZV 後",
      "選入重要變項數"
    ),
    變項數   = c(n0, n1, n2, n3, n3),
    本次排除 = c("—",
                as.character(n0 - n1),
                as.character(n1 - n2),
                as.character(n2 - n3),
                "—")
  )

  list(
    X_df       = as.data.frame(X),
    X_mat      = as.matrix(X),
    release_id = release_id,
    steps      = steps,
    dropped = list(
      admin = dropped_admin,
      miss  = dropped_miss,
      nzv   = dropped_nzv
    )
  )
}
