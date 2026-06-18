#' 小規模試跑，外推正式執行時間（num.proj=300, nrep=500）
#'
#' @param X_mat       分析用 matrix
#' @param target_proj 正式執行 num.proj，預設 300
#' @param target_nrep 正式執行 nrep，預設 500
#' @return list(pilot_seconds, est_min_low, est_min_high, est_seconds, message)
pilot_pklm <- function(X_mat, target_proj = 300L, target_nrep = 500L) {
  t0 <- proc.time()
  PKLMtest::PKLMtest(
    X_mat,
    num.proj              = 10L,
    nrep                  = 50L,
    compute.partial.pvals = FALSE
  )
  t_pilot <- as.numeric((proc.time() - t0)["elapsed"])
  scale   <- (target_proj / 10) * (target_nrep / 50)
  t_full  <- t_pilot * scale
  est_mid <- t_full / 60

  est_min_low  <- max(0.5, est_mid - 2.5)
  est_min_high <- est_mid + 2.5

  list(
    pilot_seconds = t_pilot,
    est_min_low   = est_min_low,
    est_min_high  = est_min_high,
    est_seconds   = t_full,
    message = sprintf(
      "試跑耗時 %.1f 秒；正式執行（num.proj=%d, nrep=%d）預估 %.0f–%.0f 分鐘",
      t_pilot, target_proj, target_nrep, est_min_low, est_min_high
    )
  )
}

#' 執行 PKLMtest 並整理結果
#'
#' @param X_mat matrix（全數值，含 NA）
#' @param num.proj 投影數，notebook 正式值 300
#' @param nrep     重複數，notebook 正式值 500
#' @return list:
#'   $global_pval    numeric
#'   $mcar_verdict   character
#'   $partial_df     tibble：name, partial_pval, sig
#'   $n_violators    integer
run_pklm <- function(X_mat, num.proj = 300L, nrep = 500L) {
  pvals_all <- PKLMtest::PKLMtest(
    X_mat,
    num.proj              = num.proj,
    nrep                  = nrep,
    compute.partial.pvals = TRUE
  )

  global_pval   <- pvals_all[1]
  partial_pvals <- pvals_all[-1]
  names(partial_pvals) <- colnames(X_mat)

  partial_df <- tibble::tibble(
    name         = names(partial_pvals),
    partial_pval = as.numeric(partial_pvals),
    sig          = partial_pvals < 0.05
  )
  partial_df <- dplyr::arrange(partial_df, partial_pval)

  list(
    global_pval  = as.numeric(global_pval),
    mcar_verdict = ifelse(global_pval < 0.05, "拒絕 MCAR", "無法拒絕 MCAR"),
    partial_df   = partial_df,
    n_violators  = sum(partial_pvals < 0.05)
  )
}