@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1
cd /d "%~dp0"

title KIT 缺失機制檢定工具

echo.
echo  ========================================
echo   KIT 缺失機制檢定工具
echo  ========================================
echo.
echo  工作目錄：%CD%
echo.

if not exist "%~dp0run_launcher.R" (
  echo [錯誤] 找不到 run_launcher.R
  echo 請確認 ZIP 已完整解壓，並在專案根目錄雙擊 run.bat
  echo.
  pause
  exit /b 1
)

if not exist "%~dp0inst\shiny-app\app.R" (
  echo [錯誤] 找不到 inst\shiny-app
  echo 請確認下載的是完整專案 ZIP，而非僅原始碼片段
  echo.
  pause
  exit /b 1
)

set "RSCRIPT="

where Rscript.exe >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%i in ('where Rscript.exe 2^>nul') do (
    set "RSCRIPT=%%i"
    goto :found_r
  )
)

where Rscript >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%i in ('where Rscript 2^>nul') do (
    set "RSCRIPT=%%i"
    goto :found_r
  )
)

for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\R-core\R64" /v InstallPath 2^>nul') do (
  if exist "%%b\bin\x64\Rscript.exe" set "RSCRIPT=%%b\bin\x64\Rscript.exe"
  if exist "%%b\bin\Rscript.exe" set "RSCRIPT=%%b\bin\Rscript.exe"
  if defined RSCRIPT goto :found_r
)

for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\R-core\R" /v InstallPath 2^>nul') do (
  if exist "%%b\bin\x64\Rscript.exe" set "RSCRIPT=%%b\bin\x64\Rscript.exe"
  if exist "%%b\bin\Rscript.exe" set "RSCRIPT=%%b\bin\Rscript.exe"
  if defined RSCRIPT goto :found_r
)

if exist "%ProgramFiles%\R" (
  for /f "delims=" %%i in ('dir /b /ad /o-n "%ProgramFiles%\R\R-*" 2^>nul') do (
    if exist "%ProgramFiles%\R\%%i\bin\x64\Rscript.exe" (
      set "RSCRIPT=%ProgramFiles%\R\%%i\bin\x64\Rscript.exe"
      goto :found_r
    )
    if exist "%ProgramFiles%\R\%%i\bin\Rscript.exe" (
      set "RSCRIPT=%ProgramFiles%\R\%%i\bin\Rscript.exe"
      goto :found_r
    )
  )
)

echo [錯誤] 找不到 R。
echo.
echo 請先安裝 R：https://cran.r-project.org/
echo 安裝時建議勾選「Add R to PATH」。
echo.
pause
exit /b 1

:found_r
echo 使用 R：!RSCRIPT!
echo.
echo 首次執行會自動安裝缺少的套件，請稍候…
echo.

call "!RSCRIPT!" "%~dp0run_launcher.R" "%~dp0"
if errorlevel 1 (
  echo.
  echo [錯誤] 啟動失敗。
  echo 詳細訊息請查看：%~dp0kitmiss_log.txt
  echo.
  pause
  exit /b 1
)

endlocal
exit /b 0
