@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "GL_ACCOUNT=cinar0"
set "FAST_LOCAL=%~dp0"
set "WORKFLOW_LOCAL=%~dp0..\great_lakes"
set "REMOTE_STAGE=/home/emmasmit/battery_technology_upload"
set "RESULTS_PARENT=/scratch/cinar_root/cinar0/emmasmit/hea_battery_technology_100"

echo Creating the deterministic representative 100-sequence file...
pushd "%FAST_LOCAL%"
matlab -batch "BuildRepresentativeSequenceSet('Sequence.mat','Seq100Represent.mat',100)"
if errorlevel 1 goto :failed_popd
popd

echo Creating the remote upload staging directory...
ssh "%GL_HOST%" "mkdir -p %REMOTE_STAGE%"
if errorlevel 1 goto :failed

echo Uploading FAST inputs and battery-technology workflow...
scp "%FAST_LOCAL%RunAllSequencesFullComparisonParallel.m" "%FAST_LOCAL%SizeERJ175LRBatteryTechnology.m" "%FAST_LOCAL%Seq100Represent.mat" "%FAST_LOCAL%+AircraftSpecsPkg\ERJ175LR_PHE.m" "%GL_HOST%:%REMOTE_STAGE%/"
if errorlevel 1 goto :failed
scp "%WORKFLOW_LOCAL%\PrepareBatteryTechnologyRun.m" "%WORKFLOW_LOCAL%\prepare_battery_technology.sbatch" "%WORKFLOW_LOCAL%\CompareBatteryTechnologyRuns.m" "%WORKFLOW_LOCAL%\compare_battery_technology.sbatch" "%WORKFLOW_LOCAL%\submit_battery_technology_comparison.sh" "%WORKFLOW_LOCAL%\RunSelectedSequenceTask.m" "%WORKFLOW_LOCAL%\run_selected_sequence.sbatch" "%WORKFLOW_LOCAL%\ProcessSelectedSequenceResults.m" "%WORKFLOW_LOCAL%\CollectSelectedSequenceResults.m" "%WORKFLOW_LOCAL%\process_results.sbatch" "%WORKFLOW_LOCAL%\HEAOpsPaperResults.m" "%GL_HOST%:%REMOTE_STAGE%/"
if errorlevel 1 goto :failed

echo Installing with backups and submitting the 500 and 1000 Wh/kg runs...
ssh "%GL_HOST%" "set -e; stamp=$(date -u +%%Y%%m%%dT%%H%%M%%SZ); fast_repo_dir=$(dirname $(find /home/emmasmit -maxdepth 6 -type f -name Sequence.mat -print -quit)); test -d $fast_repo_dir; workflow=/home/emmasmit/HEA_OPS/great_lakes; mkdir -p $workflow; cp $fast_repo_dir/RunAllSequencesFullComparisonParallel.m $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.bak.$stamp; cp $fast_repo_dir/+AircraftSpecsPkg/ERJ175LR_PHE.m $fast_repo_dir/+AircraftSpecsPkg/ERJ175LR_PHE.m.bak.$stamp; cp %REMOTE_STAGE%/RunAllSequencesFullComparisonParallel.m $fast_repo_dir/; cp %REMOTE_STAGE%/SizeERJ175LRBatteryTechnology.m %REMOTE_STAGE%/Seq100Represent.mat $fast_repo_dir/; cp %REMOTE_STAGE%/ERJ175LR_PHE.m $fast_repo_dir/+AircraftSpecsPkg/; cp %REMOTE_STAGE%/PrepareBatteryTechnologyRun.m %REMOTE_STAGE%/prepare_battery_technology.sbatch %REMOTE_STAGE%/CompareBatteryTechnologyRuns.m %REMOTE_STAGE%/compare_battery_technology.sbatch %REMOTE_STAGE%/submit_battery_technology_comparison.sh %REMOTE_STAGE%/RunSelectedSequenceTask.m %REMOTE_STAGE%/run_selected_sequence.sbatch %REMOTE_STAGE%/ProcessSelectedSequenceResults.m %REMOTE_STAGE%/CollectSelectedSequenceResults.m %REMOTE_STAGE%/process_results.sbatch %REMOTE_STAGE%/HEAOpsPaperResults.m $workflow/; bash $workflow/submit_battery_technology_comparison.sh %GL_ACCOUNT% $fast_repo_dir $fast_repo_dir/Seq100Represent.mat %RESULTS_PARENT%"
if errorlevel 1 goto :failed

echo.
echo Both technology runs and their comparison job were submitted.
echo Results parent: %RESULTS_PARENT%
pause
exit /b 0

:failed_popd
popd
:failed
echo.
echo Workflow creation, upload, installation, or submission failed.
pause
exit /b 1
