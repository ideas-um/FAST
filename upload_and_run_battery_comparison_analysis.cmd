@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "GL_ACCOUNT=cinar0"
set "WORKFLOW_LOCAL=%~dp0..\great_lakes"
set "REMOTE_STAGE=/home/emmasmit/battery_comparison_analysis_upload"
set "RESULTS_PARENT=/scratch/cinar_root/cinar0/emmasmit/hea_battery_technology_100"

echo Uploading the comparison analysis workflow...
ssh "%GL_HOST%" "mkdir -p %REMOTE_STAGE%"
if errorlevel 1 goto :failed

scp "%WORKFLOW_LOCAL%\CompareBatteryTechnologyRuns.m" "%WORKFLOW_LOCAL%\compare_battery_technology.sbatch" "%WORKFLOW_LOCAL%\submit_battery_comparison_analysis.sh" "%GL_HOST%:%REMOTE_STAGE%/"
if errorlevel 1 goto :failed

echo Installing with timestamped backups and submitting the analysis-only job...
ssh "%GL_HOST%" "set -e; stamp=$(date -u +%%Y%%m%%dT%%H%%M%%SZ); workflow=/home/emmasmit/HEA_OPS/great_lakes; mkdir -p $workflow; for f in CompareBatteryTechnologyRuns.m compare_battery_technology.sbatch submit_battery_comparison_analysis.sh; do if test -f $workflow/$f; then cp $workflow/$f $workflow/$f.bak.$stamp; fi; cp %REMOTE_STAGE%/$f $workflow/$f; done; bash $workflow/submit_battery_comparison_analysis.sh %GL_ACCOUNT% %RESULTS_PARENT%"
if errorlevel 1 goto :failed

echo.
echo Comparison-only job submitted. No sequence jobs were rerun.
echo Results will be written under:
echo %RESULTS_PARENT%/comparison
pause
exit /b 0

:failed
echo.
echo Upload, installation, or comparison submission failed.
pause
exit /b 1
