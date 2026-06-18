# kitMiss：KIT 缺失機制檢定工具

KIT 風格 Shiny App，整合 **RBtest** 與 **PKLMtest** 對多波次調查資料進行缺失資料機制檢定。

## 功能

- **上傳**：接受 CSV / SAV（單檔上限 500 MB）
- **Tab 1 缺失資料**：naniar 缺失圖、逐步排除、摘要表、匯出含 `release_id` 的 CSV
- **Tab 2 RBtest**：MCAR / MAR / Complete 判定，可匯出 CSV
- **Tab 3 PKLMtest**：可試跑預估時間、可調整 `num.proj` / `nrep`，可匯出 CSV

---

## 推薦：用 `runGitHub()` 啟動（無需 clone）

從 GitHub 直接下載並執行 Shiny App，適合一般使用者。

### 步驟

**1. 安裝相依套件**（首次使用時執行一次即可）

```r
install.packages(c(
  "shiny", "bslib", "dplyr", "readr", "haven",
  "naniar", "ggplot2", "caret", "tibble",
  "RBtest", "PKLMtest"
))
```

**2. 從 GitHub 啟動 App**

```r
shiny::runGitHub("jiewenTsai/kitMiss")
```

根目錄的 `app.R` 會自動啟動 `inst/shiny-app`，**不必**加 `subdir`。

瀏覽器會自動開啟本機介面。上傳 CSV / SAV → 執行資料清理 → 再進行 RBtest 或 PKLMtest。

**3. 使用流程摘要**

| 步驟 | 分頁 | 動作 |
|------|------|------|
| 1 | 缺失資料 | 上傳檔案 → 檢視缺失圖 → 確認排除欄位 → 執行資料清理 |
| 2 | 缺失資料 | 檢視清理摘要 → 下載含 `release_id` 的 CSV（建議用 Chrome） |
| 3 | RBtest | 執行 RBtest → 檢視機制摘要 → 下載結果 |
| 4 | PKLMtest | （可選）預估執行時間 → 設定參數 → 執行 PKLMtest → 下載結果 |

> 若下載無反應，請改用 Chrome 或檢查瀏覽器是否封鎖下載。

---

## 其他啟動方式

### 安裝套件後執行

```r
install.packages("remotes")
remotes::install_github("jiewenTsai/kitMiss")
kitMiss::run_kitmiss()
```

### 本機開發（clone 後）

```r
setwd("path/to/kitMiss")   # 專案根目錄
shiny::runApp("app.R")
```

或：

```r
devtools::load_all(".")
run_kitmiss()
```

---

## 分析方法引用

- Rouzinov, S., & Berchtold, A. (2022). Regression-based approach to test missing data mechanisms. *Data*, 7(2), 16. https://doi.org/10.3390/data7020016
- Spohn, M.-L., Näf, J., Michel, L., & Meinshausen, N. (2025). PKLM: A flexible MCAR test using classification. *Psychometrika*, 90(1), 280–303. https://doi.org/10.1017/psy.2024.14

## 授權

MIT
