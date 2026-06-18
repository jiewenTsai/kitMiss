@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

title KIT Missing Data Tool

echo.
echo  ========================================
echo   KIT Missing Data Mechanism Tool
echo   (KIT 缺失機制檢定工具)
echo  ========================================
echo.
echo  Working dir: %CD%
echo.

if not exist "%~dp0run_launcher.R" (
  echo [ERROR] run_launcher.R not found.
  echo Please make sure the ZIP is fully extracted
  echo and run.bat is in the project root folder.
  echo.
  pause
  exit /b 1
)

if not exist "%~dp0inst\shiny-app\app.R" (
  echo [ERROR] inst\shiny-app\app.R not found.
  echo Please make sure the ZIP is fully extracted.
  echo.
  pause
  exit /b 1
)

set "RSCRIPT="

where Rscript.exe >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%i in ('where Rscript.exe 2^>nul') do (
    if not defined RSCRIPT set "RSCRIPT=%%i"
  )
)

if not defined RSCRIPT (
  where Rscript >nul 2>&1
  if not errorlevel 1 (
    for /f "delims=" %%i in ('where Rscript 2^>nul') do (
      if not defined RSCRIPT set "RSCRIPT=%%i"
    )
  )
)

if not defined RSCRIPT (
  for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\R-core\R64" /v InstallPath 2^>nul') do (
    if exist "%%b\bin\x64\Rscript.exe" set "RSCRIPT=%%b\bin\x64\Rscript.exe"
    if exist "%%b\bin\Rscript.exe"     set "RSCRIPT=%%b\bin\Rscript.exe"
  )
)

if not defined RSCRIPT (
  for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\R-core\R" /v InstallPath 2^>nul') do (
    if exist "%%b\bin\x64\Rscript.exe" set "RSCRIPT=%%b\bin\x64\Rscript.exe"
    if exist "%%b\bin\Rscript.exe"     set "RSCRIPT=%%b\bin\Rscript.exe"
  )
)

if not defined RSCRIPT (
  if exist "%ProgramFiles%\R" (
    for /f "delims=" %%i in ('dir /b /ad /o-n "%ProgramFiles%\R\R-*" 2^>nul') do (
      if not defined RSCRIPT (
        if exist "%ProgramFiles%\R\%%i\bin\x64\Rscript.exe" (
          set "RSCRIPT=%ProgramFiles%\R\%%i\bin\x64\Rscript.exe"
        ) else if exist "%ProgramFiles%\R\%%i\bin\Rscript.exe" (
          set "RSCRIPT=%ProgramFiles%\R\%%i\bin\Rscript.exe"
        )
      )
    )
  )
)

if not defined RSCRIPT (
  echo [ERROR] R not found.
  echo Please install R from: https://cran.r-project.org/
  echo During installation, check "Add R to PATH".
  echo.
  pause
  exit /b 1
)

echo Using R: !RSCRIPT!
echo.
echo Checking and installing required packages (first run may take a few minutes)...
echo.

set "ROOT=%~dp0."

"!RSCRIPT!" "%~dp0run_launcher.R" "!ROOT!"
if errorlevel 1 (
  echo.
  echo [ERROR] Launch failed. See kitmiss_log.txt for details.
  echo.
  pause
  exit /b 1
)

endlocal
exit /b 0
