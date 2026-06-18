ui <- bslib::page_fluid(
  theme = kit_theme(),
  title = "KIT 缺失機制檢定工具",
  shiny::tags$head(shiny::tags$style(kit_css())),
  kit_header(
    title    = "KIT 缺失機制檢定工具",
    subtitle = "臺灣幼兒發展調查資料庫",
    tagline  = "PKLM / RBtest"
  ),

  bslib::navset_tab(

    # ── Tab 1：缺失資料 ──────────────────────────────────────
    bslib::nav_panel(
      "缺失資料",
      shiny::br(),

      shiny::div(
        class = "alert alert-success",
        shiny::tags$strong("【本分頁目標】"), "清理多波次調查資料，去除行政識別欄與低品質變項，準備供後續缺失機制檢定使用。",
        shiny::tags$hr(style = "margin: 0.5rem 0;"),
        shiny::tags$strong("工具："), "naniar（缺失視覺化）、caret（NZV 篩選）、haven / readr（檔案讀取）",
        shiny::tags$br(),
        shiny::tags$strong("步驟："),
        shiny::tags$ol(
          style = "margin: 0.3rem 0 0 1.2rem; padding: 0;",
          shiny::tags$li("上傳 CSV 或 SAV 檔"),
          shiny::tags$li("確認缺失圖（重編碼後、排除前）"),
          shiny::tags$li("視需要調整排除欄位清單 → 執行清理"),
          shiny::tags$li("下載含 release_id 的清理後 CSV（可備用）")
        ),
        shiny::tags$strong("結果："), "依序排除行政欄、>50% 缺失欄、近零變異欄，並顯示各步驟欄數變化。"
      ),

      shiny::fileInput(
        "file_upload",
        "上傳資料檔（CSV 或 SAV，單檔上限 500 MB）",
        accept = c(".csv", ".sav", ".zsav")
      ),

      shiny::uiOutput("upload_info_ui"),
      shiny::hr(),

      # 缺失圖（完整輸入資料）— 置於排除設定之前
      shiny::h4("完整輸入資料缺失圖（naniar）"),
      shiny::tags$p(class = "text-muted", "此圖顯示 missing code 重編碼後、排除前的完整資料。"),
      shiny::div(class = "kit-table-scroll", shiny::plotOutput("miss_plot", height = "500px")),
      shiny::hr(),

      # 排除框
      shiny::h4("排除變項設定"),
      shiny::tags$p(
        class = "text-muted",
        "逗號或換行分隔。上傳資料後自動預填：",
        shiny::tags$br(),
        "① 行政識別欄（release_id, interviewer_id, wsel0…）",
        shiny::tags$br(),
        "② 測量時間欄（heigh*, weight*：身長/體重測量年月日）",
        shiny::tags$br(),
        "③ 跨波次生長紀錄欄（groweight1, growheigh1…，以正則比對）",
        shiny::tags$br(),
        shiny::tags$em("僅顯示資料中實際存在的欄位；若欄名與預設不符，請手動補充。")
      ),
      shiny::textAreaInput(
        "exclude_vars",
        label  = NULL,
        value  = "",
        rows   = 4,
        width  = "100%"
      ),
      shiny::actionButton("run_clean", "執行資料清理", class = "btn-primary"),
      shiny::br(), shiny::br(),
      shiny::uiOutput("clean_status_ui"),
      shiny::hr(),

      shiny::h4("清理摘要"),
      shiny::tableOutput("steps_table"),
      shiny::br(),

      shiny::h5("各階段排除變項明細"),
      shiny::uiOutput("dropped_detail_ui"),
      shiny::hr(),

      shiny::h4("匯出清理後資料"),
      shiny::uiOutput("export_msg_ui"),
      shiny::downloadButton("download_clean_csv", "下載 CSV", class = "btn-primary"),
      shiny::tags$p(class = "text-muted", style = "font-size:0.85rem; margin-top:0.5rem;",
        "若下載無反應，請改用 Chrome 或檢查瀏覽器是否封鎖下載。")
    ),

    # ── Tab 2：RBtest ────────────────────────────────────────
    bslib::nav_panel(
      "RBtest",
      shiny::br(),

      shiny::div(
        class = "alert alert-success",
        shiny::tags$strong("【本分頁目標】"), "逐一檢定每個變項的缺失機制，判斷為 MCAR、MAR 或完整（無缺失）。",
        shiny::tags$hr(style = "margin: 0.5rem 0;"),
        shiny::tags$strong("原理："), "對每個有缺失的變項建立缺失指標的迴歸模型；若其他變項能顯著預測缺失，則判為 MAR，否則為 MCAR。",
        shiny::tags$br(),
        shiny::tags$strong("步驟："), "完成「缺失資料」分頁清理後，直接按「執行 RBtest」。",
        shiny::tags$br(),
        shiny::tags$strong("結果："), "各變項機制標記（complete / MCAR / MAR）、缺失數與比例，可下載完整 CSV。",
        shiny::tags$hr(style = "margin: 0.5rem 0;"),
        shiny::tags$small(
          class = "text-muted",
          shiny::tags$strong("引用："),
          "Rouzinov, S., & Berchtold, A. (2022). Regression-based approach to test missing data mechanisms. ",
          shiny::tags$em("Data"), ", 7(2), 16. ",
          shiny::tags$a("https://doi.org/10.3390/data7020016",
                        href = "https://doi.org/10.3390/data7020016", target = "_blank")
        )
      ),

      shiny::actionButton("run_rbtest", "執行 RBtest", class = "btn-primary"),
      shiny::br(), shiny::br(),
      shiny::uiOutput("rbtest_status_ui"),
      shiny::hr(),

      shiny::h4("機制摘要"),
      shiny::tableOutput("rbtest_summary_table"),
      shiny::br(),

      shiny::h4("變項結果（前 20 列）"),
      shiny::div(class = "kit-table-scroll", shiny::tableOutput("rbtest_preview")),
      shiny::br(),
      shiny::downloadButton("download_rbtest_csv", "下載完整結果 CSV", class = "btn-outline-primary"),
      shiny::tags$p(class = "text-muted", style = "font-size:0.85rem; margin-top:0.5rem;",
        "若下載無反應，請改用 Chrome 或檢查瀏覽器是否封鎖下載。")
    ),

    # ── Tab 3：PKLMtest ──────────────────────────────────────
    bslib::nav_panel(
      "PKLMtest",
      shiny::br(),

      shiny::div(
        class = "alert alert-success",
        shiny::tags$strong("【本分頁目標】"), "以整體觀點檢定資料是否符合 MCAR，並找出哪些變項是違反 MCAR 的主要來源。",
        shiny::tags$hr(style = "margin: 0.5rem 0;"),
        shiny::tags$strong("原理："), "透過隨機投影將缺失模式轉為分類問題，再以訓練分類器的方式檢驗缺失是否可被預測；若可預測則拒絕 MCAR。",
        shiny::tags$br(),
        shiny::tags$strong("步驟："),
        shiny::tags$ol(
          style = "margin: 0.3rem 0 0 1.2rem; padding: 0;",
          shiny::tags$li("完成「缺失資料」分頁清理"),
          shiny::tags$li("（可選）按「預估執行時間」了解所需時間"),
          shiny::tags$li("視需要調整參數（num.proj / nrep）→ 執行 PKLMtest")
        ),
        shiny::tags$strong("結果："), "Global p 值（整體 MCAR 結論）＋各變項局部 p 值，可下載完整 CSV。",
        shiny::tags$br(),
        shiny::tags$span(
          class = "text-muted", style = "font-size:0.85rem;",
          "注意：正式執行（num.proj=300, nrep=500）需時數分鐘，建議先預估時間再執行。"
        ),
        shiny::tags$hr(style = "margin: 0.5rem 0;"),
        shiny::tags$small(
          class = "text-muted",
          shiny::tags$strong("引用："),
          "Spohn, M.-L., Näf, J., Michel, L., & Meinshausen, N. (2025). PKLM: A flexible MCAR test using classification. ",
          shiny::tags$em("Psychometrika"), ", 90(1), 280–303. ",
          shiny::tags$a("https://doi.org/10.1017/psy.2024.14",
                        href = "https://doi.org/10.1017/psy.2024.14", target = "_blank")
        )
      ),

      shiny::actionButton("run_pilot_pklm", "預估執行時間",
                          class = "btn-outline-secondary"),
      shiny::tags$p(
        class = "text-muted",
        style = "margin-top:0.35rem; font-size:0.9rem;",
        "以 num.proj = 10、nrep = 50 試跑，外推至 num.proj = 300、nrep = 500 的預估時間（±2.5 分鐘）。"
      ),
      shiny::uiOutput("pklm_pilot_ui"),
      shiny::hr(),

      shiny::h4("執行參數"),
      shiny::tags$p(class = "text-muted", "正式分析建議 num.proj = 300、nrep = 500。可先試跑預估時間，或調低參數測試。"),
      shiny::fluidRow(
        shiny::column(4, shiny::numericInput("pklm_num_proj", "num.proj（投影數）",
                                             value = 300, min = 10, max = 1000, step = 10)),
        shiny::column(4, shiny::numericInput("pklm_nrep", "nrep（重複數）",
                                             value = 500, min = 50, max = 2000, step = 50))
      ),

      shiny::actionButton("run_pklm", "執行 PKLMtest", class = "btn-primary"),
      shiny::tags$p(
        class = "text-muted",
        style = "font-size:0.85rem; margin-top:0.35rem;",
        "執行時會顯示轉圈等待視窗；建議先試跑預估時間。"
      ),
      shiny::br(), shiny::br(),
      shiny::uiOutput("pklm_status_ui"),
      shiny::hr(),

      shiny::h4("全域結果"),
      shiny::uiOutput("pklm_global_ui"),
      shiny::br(),

      shiny::h4("局部 p 值（前 20 列，依 p 值排序）"),
      shiny::div(class = "kit-table-scroll", shiny::tableOutput("pklm_partial_preview")),
      shiny::br(),
      shiny::downloadButton("download_pklm_csv", "下載完整結果 CSV", class = "btn-outline-primary"),
      shiny::tags$p(class = "text-muted", style = "font-size:0.85rem; margin-top:0.5rem;",
        "若下載無反應，請改用 Chrome 或檢查瀏覽器是否封鎖下載。")
    )
  )
)
