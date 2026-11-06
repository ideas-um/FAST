@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "REMOTE_RESULTS=/scratch/cinar_root/cinar0/emmasmit/fast_first_500_v4"
set "LOCAL_RESULTS_ROOT=%~dp0..\HEA_OPS_results"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
set "DESTINATION=%LOCAL_RESULTS_ROOT%\FAST_processed_%STAMP%"

where tar >nul 2>&1
if errorlevel 1 goto :no_tar

mkdir "%DESTINATION%"
if errorlevel 1 goto :failed

echo Streaming the processed results from Great Lakes...
echo Logs, task files, and retry files are not included.
echo Every downloaded file will be listed below.
echo.
ssh -T "%GL_HOST%" "set -e; test -f %REMOTE_RESULTS%/combined/.fresh_processing_complete; test -f %REMOTE_RESULTS%/combined/SelectedSequences_ProcessedResults.mat; test -d %REMOTE_RESULTS%/PaperResults; tar -C %REMOTE_RESULTS% -cf - combined PaperResults" | tar -x -v -f - -C "%DESTINATION%"
if errorlevel 1 goto :failed

dir /b "%DESTINATION%\combined\*" >nul 2>&1
if errorlevel 1 goto :empty
dir /b "%DESTINATION%\PaperResults\*" >nul 2>&1
if errorlevel 1 goto :empty

echo.
echo Download complete and verified:
echo %DESTINATION%
pause
exit /b 0

:no_tar
echo.
echo Windows tar.exe was not found, so the archive cannot be extracted.
pause
exit /b 1

:empty
echo.
echo The transfer ended without both populated output folders.
echo Check the SSH or tar error shown above. Partial files remain in:
echo %DESTINATION%
pause
exit /b 1

:failed
echo.
echo The streamed download failed. Check the SSH or tar error shown above.
echo If no detailed error appeared, run the clean reprocessing workflow first.
echo Partial files remain in:
echo %DESTINATION%
pause
exit /b 1
