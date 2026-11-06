@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "GL_ACCOUNT=cinar0"
set "FAST_LOCAL=%~dp0"
set "WORKFLOW_LOCAL=%~dp0..\great_lakes"
set "REMOTE_STAGE=/home/emmasmit/hea250_rep100_stage"
set "PRECOMPUTED_LOCAL=%~dp0output\local_rep100_precomputed_v6"
set "REMOTE_PRECOMPUTED=/home/emmasmit/hea250_rep100_precomputed_v6"

for /f %%C in ('dir /b /a-d "%PRECOMPUTED_LOCAL%\fixed_baseline_cache\Sequence_*_fixed_baseline.mat" 2^>nul ^| find /c /v ""') do set "FIXED_COUNT=%%C"
if not "%FIXED_COUNT%"=="100" (
    echo Expected 100 local fixed-baseline MAT files but found %FIXED_COUNT%.
    echo Finish PrecomputeRepresentative100Baselines before submitting.
    goto :failed
)

echo Creating the Great Lakes staging directory...
ssh "%GL_HOST%" "mkdir -p %REMOTE_STAGE%"
if errorlevel 1 goto :failed

echo Uploading the checked FAST code, literature-calibrated specs, and resized inputs...
scp "%FAST_LOCAL%RunAllSequencesFullComparisonParallel.m" "%FAST_LOCAL%RunGreatLakesSequenceTask.m" "%FAST_LOCAL%+OptimizationPkg\MissionPowerOpt.m" "%FAST_LOCAL%+OptimizationPkg\SequencePowerOpt.m" "%FAST_LOCAL%+OptimizationPkg\OptimizationTraceRecorder.m" "%FAST_LOCAL%+AircraftSpecsPkg\ERJ175LR.m" "%FAST_LOCAL%+AircraftSpecsPkg\ERJ175LR_PHE.m" "%FAST_LOCAL%ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat" "%FAST_LOCAL%Seq100Represent.mat" "%GL_HOST%:%REMOTE_STAGE%/"
if errorlevel 1 goto :failed

echo Uploading the representative-100 preparation and processing workflow...
scp "%WORKFLOW_LOCAL%\PrepareSelectedSequenceRun.m" "%WORKFLOW_LOCAL%\RunSelectedSequenceTask.m" "%WORKFLOW_LOCAL%\CollectSelectedSequenceResults.m" "%WORKFLOW_LOCAL%\ProcessSelectedSequenceResults.m" "%WORKFLOW_LOCAL%\HEAOpsPaperResults.m" "%WORKFLOW_LOCAL%\prepare_selected.sbatch" "%WORKFLOW_LOCAL%\run_selected_sequence.sbatch" "%WORKFLOW_LOCAL%\process_results.sbatch" "%WORKFLOW_LOCAL%\submit_selected_sequences.sh" "%WORKFLOW_LOCAL%\submit_250_representative100.sh" "%WORKFLOW_LOCAL%\install_and_submit_250_representative100.sh" "%GL_HOST%:%REMOTE_STAGE%/"
if errorlevel 1 goto :failed

echo Creating the reusable baseline-cache directory on Great Lakes...
ssh "%GL_HOST%" "mkdir -p %REMOTE_PRECOMPUTED%"
if errorlevel 1 goto :failed

echo Uploading compact conventional and fixed-baseline MAT files...
echo Each transferred file will be shown below.
scp -r "%PRECOMPUTED_LOCAL%\conventional_flight_cache" "%PRECOMPUTED_LOCAL%\fixed_baseline_cache" "%PRECOMPUTED_LOCAL%\Representative100_Precomputed_Baseline_Manifest.csv" "%PRECOMPUTED_LOCAL%\Representative100_Precomputed_Baseline_Manifest.mat" "%GL_HOST%:%REMOTE_PRECOMPUTED%/"
if errorlevel 1 goto :failed

echo Installing atomically and submitting a fresh timestamped run...
ssh "%GL_HOST%" "export FAST_PRECOMPUTED_BASELINE_ROOT=%REMOTE_PRECOMPUTED%; sed -i 's/\r$//' %REMOTE_STAGE%/*.sh %REMOTE_STAGE%/*.sbatch; bash %REMOTE_STAGE%/install_and_submit_250_representative100.sh %REMOTE_STAGE% %GL_ACCOUNT%"
if errorlevel 1 goto :failed

echo.
echo Representative-100 submission completed. Review the printed job IDs and results directory above.
pause
exit /b 0

:failed
echo.
echo Upload, installation, or submission stopped. If FAST jobs are active, no live code was changed and no new run was submitted.
pause
exit /b 1
