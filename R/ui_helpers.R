#' 顯示轉圈等待視窗（計算完成後請呼叫 removeModal）
#'
#' @param session  Shiny session
#' @param title    主標題
#' @param subtitle 副標題
show_busy_modal <- function(session, title, subtitle = "請勿關閉視窗，完成後會自動關閉。") {
  shiny::showModal(shiny::modalDialog(
    title = NULL,
    shiny::div(
      class = "text-center py-3",
      shiny::tags$div(class = "kit-spinner mx-auto mb-3", role = "status"),
      shiny::tags$p(class = "mb-1 fw-semibold", title),
      shiny::tags$p(class = "text-muted small mb-0", subtitle)
    ),
    footer = NULL,
    easyClose = FALSE
  ))
}
