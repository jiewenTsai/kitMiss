#' 缺失值編碼（重編碼為 NA 的值）
MISSING_CODES <- c(7777, 8888, 9996, 9999)

#' 行政資料排除清單（逐一比對資料欄名，僅加入實際存在的欄）
#'
#' 涵蓋：
#'   完訪時間（int_*）、幼兒出生年月（baby_do*）、
#'   身長/體重測量時間（heigh*/weight*）、出生資料（postn03）、
#'   行政識別與加權（wsel0, w_*, release_id, interviewer_id）、
#'   訪問形式（video）、父母出生年（pfa01*, pfc01）
DROP_ITEMS <- c(
  # 完訪時間
  "int_months", "int_y", "int_m",
  # 幼兒出生年月
  "baby_doby", "baby_dobm",
  # 身長測量時間（當期）
  "heighy", "heighm", "heighd",
  # 體重測量時間（當期）
  "weighty", "weightm", "weightd",
  # 出生體重/身長
  "postn03",
  # 行政識別與加權
  "wsel0", "w_post_sel", "w_raking_sel",
  "release_id", "interviewer_id",
  # 訪問形式
  "video",
  # 父母/照顧者出生年
  "pfa0101", "pfa0101a",
  "pfa0102", "pfa0102a",
  "pfc01"
)

#' 跨波次生長紀錄正則（match → 排除）
#' 涵蓋：growheigh*, groweight*, growy*, growm*, growd*（後接數字）
#' 例：groweight1, groweight2, growm36 等
GROW_PATTERN <- "^(growheigh|groweight|growy|growm|growd)\\d+$"
