@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>&1
cd /d "%~dp0"

title KIT 缺失機制檢定工具

echo.
echo  ========================================
echo   KIT 缺失機制檢定工具
echo  ========================================
echo.

set "RSCRIPT="

where Rscript >nul 2>&1
if %ERRORLEVEL% equ 0 (
  for /f "delims=" %%i in ('where Rscript 2^>nul') do (
    set "RSCRIPT=%%i"
    goto :found_r
  )
)

if exist "%ProgramFiles%\R" (
  for /f "delims=" %%i in ('dir /b /ad /o-n "%ProgramFiles%\R\R-*" 2^>nul') do (
    if exist "%ProgramFiles%\R\%%i\bin\Rscript.exe" (
      set "RSCRIPT=%ProgramFiles%\R\%%i\bin\Rscript.exe"
      goto :found_r
    )
  )
)

if exist "%ProgramFiles(x86)%\R" (
  for /f "delims=" %%i in ('dir /b /ad /o-n "%ProgramFiles(x86)%\R\R-*" 2^>nul') do (
    if exist "%ProgramFiles(x86)%\R\%%i\bin\Rscript.exe" (
      set "RSCRIPT=%ProgramFiles(x86)%\R\%%i\bin\Rscript.exe"
      goto :found_r
    )
  )
)

echo [錯誤] 找不到 R。請先安裝 R：https://cran.r-project.org/
echo.
pause
exit /b 1

:found_r
echo 使用 R：%RSCRIPT%
echo.

"%RSCRIPT%" "%~dp0run_launcher.R"
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% neq 0 (
  echo.
  echo [錯誤] 啟動失敗（錯誤碼 %EXIT_CODE%）。
  echo.
  pause
  exit /b %EXIT_CODE%
)

endlocal
exit /b 0
