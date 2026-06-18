server <- function(input, output, session) {

  raw_data    <- shiny::reactiveVal(NULL)
  pipeline    <- shiny::reactiveVal(NULL)
  rb_result   <- shiny::reactiveVal(NULL)
  pklm_result <- shiny::reactiveVal(NULL)
  pklm_pilot  <- shiny::reactiveVal(NULL)

  # ── 上傳檔案 ──────────────────────────────────────────────
  shiny::observeEvent(input$file_upload, {
    pipeline(NULL); rb_result(NULL); pklm_result(NULL); pklm_pilot(NULL)
    f   <- input$file_upload
    dat <- tryCatch(load_data_file(f$datapath, f$name), error = function(e) {
      shiny::showNotification(paste("讀檔失敗：", e$message), type = "error", duration = 10)
      NULL
    })
    if (is.null(dat)) return()
    dat <- recode_missing(dat)
    raw_data(dat)
    shiny::updateTextAreaInput(session, "exclude_vars",
                               value = default_exclude_text(dat))
  })

  output$upload_info_ui <- shiny::renderUI({
    dat <- raw_data(); shiny::req(dat)
    shiny::div(
      class = "alert alert-info",
      sprintf("已載入：%d 列 × %d 欄", nrow(dat), ncol(dat))
    )
  })

  output$miss_plot <- shiny::renderPlot({
    dat <- raw_data(); shiny::req(dat)
    naniar::vis_miss(dat, warn_large_data = FALSE) +
      ggplot2::theme(axis.text.x = ggplot2::element_text(size = 5, angle = 90))
  })

  # ── 執行清理 ──────────────────────────────────────────────
  shiny::observeEvent(input$run_clean, {
    dat <- raw_data()
    if (is.null(dat)) {
      shiny::showNotification("請先上傳資料。", type = "warning")
      return()
    }
    user_drop <- parse_var_list(input$exclude_vars)
    shiny::withProgress(message = "資料清理中…", value = 0.5, {
      res <- tryCatch(
        run_miss_pipeline(dat, user_drop = user_drop),
        error = function(e) {
          shiny::showNotification(paste("清理失敗：", e$message), type = "error")
          NULL
        }
      )
    })
    if (!is.null(res)) {
      pipeline(res)
      rb_result(NULL); pklm_result(NULL)
    }
  })

  output$clean_status_ui <- shiny::renderUI({
    res <- pipeline(); shiny::req(res)
    shiny::div(class = "alert alert-success",
      shiny::tags$strong("【成功】"),
      sprintf("清理完成，分析資料：%d 列 × %d 欄", nrow(res$X_df), ncol(res$X_df))
    )
  })

  output$steps_table <- shiny::renderTable({
    shiny::req(pipeline())
    pipeline()$steps
  }, striped = TRUE, spacing = "s")

  output$dropped_detail_ui <- shiny::renderUI({
    res <- pipeline(); shiny::req(res)
    d <- res$dropped
    section <- function(label, vars) {
      if (length(vars) == 0)
        return(shiny::p(shiny::strong(label), shiny::em("（無）")))
      shiny::tagList(
        shiny::p(shiny::strong(label), sprintf("（%d 個）", length(vars))),
        shiny::pre(style = "font-size:0.78rem; max-height:120px; overflow-y:auto;",
                   paste(vars, collapse = ", "))
      )
    }
    shiny::tagList(
      section("排除行政資料：", d$admin),
      section("排除 >50% 缺失：", d$miss),
      section("排除 NZV：",       d$nzv)
    )
  })

  # ── 匯出清理後 CSV ────────────────────────────────────────
  output$export_msg_ui <- shiny::renderUI({
    res <- pipeline(); shiny::req(res)
    if (is.null(res$release_id)) {
      return(shiny::div(class = "alert alert-warning",
        "原始資料中未找到 release_id 欄；匯出時不含識別碼。"))
    }
    ec <- build_export_df(res$release_id, res$X_df)
    cls <- if (ec$ok) "alert alert-success" else "alert alert-warning"
    shiny::div(class = cls, ec$msg)
  })

  output$download_clean_csv <- shiny::downloadHandler(
    filename = function() paste0("cleaned_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content  = function(file) {
      tryCatch({
        res <- shiny::isolate(pipeline())
        if (is.null(res)) stop("請先執行資料清理")
        if (!is.null(res$release_id)) {
          ec <- build_export_df(res$release_id, res$X_df)
          if (ec$ok) {
            readr::write_csv(ec$df, file)
            return(invisible(NULL))
          }
        }
        # 若無 release_id 或 build 失敗，直接匯出分析資料
        readr::write_csv(as.data.frame(res$X_df), file)
      }, error = function(e) {
        shiny::showNotification(paste("匯出失敗：", e$message), type = "error", duration = 10)
        readr::write_csv(data.frame(error = as.character(e$message)), file)
      })
    }
  )
  shiny::outputOptions(output, "download_clean_csv", suspendWhenHidden = FALSE)

  # ── RBtest ────────────────────────────────────────────────
  shiny::observeEvent(input$run_rbtest, {
    res <- shiny::isolate(pipeline())
    if (is.null(res)) {
      shiny::showNotification("請先在「缺失資料」分頁執行清理。", type = "warning")
      return()
    }
    shiny::withProgress(message = "RBtest 執行中…", value = 0.3, {
      rb <- tryCatch(run_rbtest(res$X_df), error = function(e) {
        shiny::showNotification(paste("RBtest 失敗：", e$message), type = "error")
        NULL
      })
      shiny::setProgress(1)
    })
    if (!is.null(rb)) rb_result(rb)
  })

  output$rbtest_status_ui <- shiny::renderUI({
    rb <- rb_result(); shiny::req(rb)
    shiny::div(class = "alert alert-success",
      shiny::tags$strong("【成功】"),
      sprintf("RBtest 完成，共 %d 個變項。", nrow(rb$result_df))
    )
  })

  output$rbtest_summary_table <- shiny::renderTable({
    rb <- rb_result(); shiny::req(rb)
    rb$summary
  }, striped = TRUE, spacing = "s")

  output$rbtest_preview <- shiny::renderTable({
    rb <- rb_result(); shiny::req(rb)
    head(rb$result_df[, c("variable", "abs_nbrMD", "rel_nbrMD", "mechanism", "label")], 20)
  }, striped = TRUE, spacing = "s")

  output$download_rbtest_csv <- shiny::downloadHandler(
    filename = function() paste0("rbtest_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content  = function(file) {
      tryCatch({
        rb <- shiny::isolate(rb_result())
        if (is.null(rb)) stop("請先執行 RBtest")
        readr::write_csv(rb$result_df, file)
      }, error = function(e) {
        shiny::showNotification(paste("匯出失敗：", e$message), type = "error", duration = 10)
        readr::write_csv(data.frame(error = as.character(e$message)), file)
      })
    }
  )
  shiny::outputOptions(output, "download_rbtest_csv", suspendWhenHidden = FALSE)

  # ── PKLMtest ──────────────────────────────────────────────
  shiny::observeEvent(input$run_pilot_pklm, {
    res <- shiny::isolate(pipeline())
    if (is.null(res)) {
      shiny::showNotification("請先在「缺失資料」分頁執行清理。", type = "warning")
      return()
    }
    shiny::withProgress(message = "PKLM 試跑中（num.proj=10, nrep=50）…", value = 0.5, {
      pilot <- tryCatch(
        pilot_pklm(res$X_mat, target_proj = 300L, target_nrep = 500L),
        error = function(e) {
          shiny::showNotification(paste("試跑失敗：", e$message), type = "error", duration = 10)
          NULL
        }
      )
    })
    if (!is.null(pilot)) {
      pklm_pilot(pilot)
      shiny::showNotification(pilot$message, type = "message", duration = 12)
    }
  })

  output$pklm_pilot_ui <- shiny::renderUI({
    pilot <- pklm_pilot()
    shiny::req(pilot)
    shiny::div(
      class = "alert alert-info",
      shiny::tags$strong("【時間預估】"), " ", pilot$message
    )
  })

  shiny::observeEvent(input$run_pklm, {
    res <- shiny::isolate(pipeline())
    if (is.null(res)) {
      shiny::showNotification("請先在「缺失資料」分頁執行清理。", type = "warning")
      return()
    }
    num_proj <- as.integer(input$pklm_num_proj)
    nrep     <- as.integer(input$pklm_nrep)
    if (is.na(num_proj) || num_proj < 1) {
      shiny::showNotification("num.proj 須為正整數。", type = "warning"); return()
    }
    if (is.na(nrep) || nrep < 1) {
      shiny::showNotification("nrep 須為正整數。", type = "warning"); return()
    }

    pilot <- shiny::isolate(pklm_pilot())
    subtitle <- if (!is.null(pilot)) pilot$message else "分析進行中，請耐心等待。"

    show_busy_modal(
      session,
      sprintf("PKLMtest 執行中（num.proj=%d, nrep=%d）", num_proj, nrep),
      subtitle
    )

    session$onFlushed(function() {
      pk <- tryCatch(
        run_pklm(res$X_mat, num.proj = num_proj, nrep = nrep),
        error = function(e) {
          shiny::showNotification(paste("PKLMtest 失敗：", e$message),
                                  type = "error", duration = 10)
          NULL
        }
      )
      shiny::removeModal()
      if (!is.null(pk)) pklm_result(pk)
    }, once = TRUE)
  })

  output$pklm_status_ui <- shiny::renderUI({
    pk <- pklm_result(); shiny::req(pk)
    cls <- if (pk$global_pval < 0.05) "alert alert-warning" else "alert alert-success"
    shiny::div(class = cls,
      shiny::tags$strong("【成功】"),
      sprintf("PKLMtest 完成。Global p-value = %.4f → %s", pk$global_pval, pk$mcar_verdict)
    )
  })

  output$pklm_global_ui <- shiny::renderUI({
    pk <- pklm_result(); shiny::req(pk)
    n_all <- nrow(pk$partial_df)
    shiny::tags$table(
      class = "table table-sm",
      shiny::tags$tbody(
        shiny::tags$tr(shiny::tags$th("Global p-value"),
                       shiny::tags$td(sprintf("%.4f", pk$global_pval))),
        shiny::tags$tr(shiny::tags$th("結論"),
                       shiny::tags$td(shiny::tags$strong(pk$mcar_verdict))),
        shiny::tags$tr(shiny::tags$th("違反 MCAR 變項數"),
                       shiny::tags$td(sprintf("%d / %d（%.1f%%）",
                         pk$n_violators, n_all, pk$n_violators / n_all * 100)))
      )
    )
  })

  output$pklm_partial_preview <- shiny::renderTable({
    pk <- pklm_result(); shiny::req(pk)
    df <- pk$partial_df
    df$sig <- ifelse(df$sig, "是", "否")
    names(df) <- c("變項名稱", "局部 p 值", "違反 MCAR")
    head(df, 20)
  }, striped = TRUE, spacing = "s")

  output$download_pklm_csv <- shiny::downloadHandler(
    filename = function() paste0("pklm_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content  = function(file) {
      tryCatch({
        pk <- shiny::isolate(pklm_result())
        if (is.null(pk)) stop("請先執行 PKLMtest")
        readr::write_csv(pk$partial_df, file)
      }, error = function(e) {
        shiny::showNotification(paste("匯出失敗：", e$message), type = "error", duration = 10)
        readr::write_csv(data.frame(error = as.character(e$message)), file)
      })
    }
  )
  shiny::outputOptions(output, "download_pklm_csv", suspendWhenHidden = FALSE)
}
