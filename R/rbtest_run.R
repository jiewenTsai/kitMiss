#' 執行 RBtest 並整理結果
#'
#' @param X_df data.frame（全數值，含 NA）
#' @return list:
#'   $result_df  data.frame：variable, abs_nbrMD, rel_nbrMD, mechanism, label
#'   $summary    tibble：Complete/MCAR/MAR 數量與比例
run_rbtest <- function(X_df) {
  res <- RBtest::RBtest(X_df)

  result_df <- data.frame(
    variable  = names(res$type),
    abs_nbrMD = res$abs.nbrMD,
    rel_nbrMD = res$rel.nbrMD,
    mechanism = as.integer(res$type),
    stringsAsFactors = FALSE
  )
  result_df$label <- dplyr::case_when(
    result_df$mechanism == -1 ~ "complete",
    result_df$mechanism ==  0 ~ "MCAR",
    result_df$mechanism ==  1 ~ "MAR"
  )

  n <- nrow(result_df)
  summary_tbl <- tibble::tibble(
    機制     = c("complete（無缺失）", "MCAR", "MAR"),
    `機制碼` = c(-1L, 0L, 1L),
    數量     = c(
      sum(result_df$mechanism == -1),
      sum(result_df$mechanism ==  0),
      sum(result_df$mechanism ==  1)
    )
  )
  summary_tbl$比例 <- sprintf("%.1f%%", summary_tbl$數量 / n * 100)

  list(result_df = result_df, summary = summary_tbl)
}
