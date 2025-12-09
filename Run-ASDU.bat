@echo off
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "R_DIR=%ROOT%runtime"
set "R_HOME="

set "R_HOME=%ROOT%runtime\R-4.4.1"
if not defined R_HOME (
  echo Portable R not found under "%R_DIR%". Expected folder like "runtime\R-4.4.1".
  pause
  exit /b 1
)

if exist "%R_HOME%\bin\x64\Rscript.exe" (
  set "RSCRIPT=%R_HOME%\bin\x64\Rscript.exe"
) else (
  set "RSCRIPT=%R_HOME%\bin\Rscript.exe"
)

set "PATH=%R_HOME%\bin\x64;%R_HOME%\bin;%PATH%"
set "RENV_PATHS_CACHE=%ROOT%renv\cache"
set "RENV_CONFIG_AUTO_PROMPT=false"

pushd "%ROOT%"
"%RSCRIPT%" -e "source('renv/activate.R'); renv::restore(prompt=FALSE); shiny::runApp('.', launch.browser=TRUE)"
set "ERR=%ERRORLEVEL%"
popd

if not "%ERR%"=="0" (
  echo.
  echo ASDU failed to start (exit code %ERR%).
  pause
)
endlocal