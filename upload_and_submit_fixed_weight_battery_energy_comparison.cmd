@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "GL_ACCOUNT=cinar0"
set "FAST_LOCAL=%~dp0"
set "WORKFLOW_LOCAL=%~dp0..\great_lakes"
set "REMOTE_STAGE=/home/emmasmit/fixed_weight_battery_upload"
set "RESULTS_PARENT=/scratch/cinar_root/cinar0/emmasmit/hea_fixed_original_weight_battery_energy_100"

echo Creating the fixed-original-weight 500 and 1000 Wh/kg HEA files...
pushd "%FAST_LOCAL%"
matlab -batch "CreateFixedWeightBatteryTechnologyVariants; BuildRepresentativeSequenceSet('Sequence.mat','Seq100Represent.mat',100)"
if errorlevel 1 goto :failed_popd
popd

echo Creating the Great Lakes upload staging directory...
ssh "%GL_HOST%" "mkdir -p %REMOTE_STAGE%"
if errorlevel 1 goto :failed

echo Uploading the representative sequences and fixed-weight aircraft...
scp "%FAST_LOCAL%RunAllSequencesFullComparisonParallel.m" "%FAST_LOCAL%Seq100Represent.mat" "%FAST_LOCAL%ERJ175LR_PHE_Fixed250Weight_500Whkg.mat" "%FAST_LOCAL%ERJ175LR_PHE_Fixed250Weight_1000Whkg.mat" "%GL_HOST%:%REMOTE_STAGE%/"
if errorlevel 1 goto :failed

echo Uploading the Great Lakes workflow...
scp "%WORKFLOW_LOCAL%\PrepareBatteryTechnologyRun.m" "%WORKFLOW_LOCAL%\prepare_battery_technology.sbatch" "%WORKFLOW_LOCAL%\submit_fixed_weight_battery_comparison.sh" "%WORKFLOW_LOCAL%\RunSelectedSequenceTask.m" "%WORKFLOW_LOCAL%\run_selected_sequence.sbatch" "%WORKFLOW_LOCAL%\ProcessSelectedSequenceResults.m" "%WORKFLOW_LOCAL%\CollectSelectedSequenceResults.m" "%WORKFLOW_LOCAL%\process_results.sbatch" "%WORKFLOW_LOCAL%\HEAOpsPaperResults.m" "%WORKFLOW_LOCAL%\CompareBatteryTechnologyRuns.m" "%WORKFLOW_LOCAL%\compare_battery_technology.sbatch" "%GL_HOST%:%REMOTE_STAGE%/"
if errorlevel 1 goto :failed

echo Installing with backups and submitting both fixed-weight studies...
ssh "%GL_HOST%" "set -e; stamp=$(date -u +%%Y%%m%%dT%%H%%M%%SZ); fast_repo_dir=$(dirname $(find /home/emmasmit -maxdepth 6 -type f -name Sequence.mat -print -quit)); test -d $fast_repo_dir; workflow=/home/emmasmit/HEA_OPS/great_lakes; mkdir -p $workflow; cp $fast_repo_dir/RunAllSequencesFullComparisonParallel.m $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.bak.$stamp; cp %REMOTE_STAGE%/RunAllSequencesFullComparisonParallel.m %REMOTE_STAGE%/Seq100Represent.mat %REMOTE_STAGE%/ERJ175LR_PHE_Fixed250Weight_500Whkg.mat %REMOTE_STAGE%/ERJ175LR_PHE_Fixed250Weight_1000Whkg.mat $fast_repo_dir/; for f in PrepareBatteryTechnologyRun.m prepare_battery_technology.sbatch submit_fixed_weight_battery_comparison.sh RunSelectedSequenceTask.m run_selected_sequence.sbatch ProcessSelectedSequenceResults.m CollectSelectedSequenceResults.m process_results.sbatch HEAOpsPaperResults.m CompareBatteryTechnologyRuns.m compare_battery_technology.sbatch; do if test -f $workflow/$f; then cp $workflow/$f $workflow/$f.bak.$stamp; fi; cp %REMOTE_STAGE%/$f $workflow/$f; done; bash $workflow/submit_fixed_weight_battery_comparison.sh %GL_ACCOUNT% $fast_repo_dir $fast_repo_dir/Seq100Represent.mat %RESULTS_PARENT%"
if errorlevel 1 goto :failed

echo.
echo Fixed-original-weight 500 and 1000 Wh/kg studies submitted.
echo Results parent: %RESULTS_PARENT%
pause
exit /b 0

:failed_popd
popd
:failed
echo.
echo Creation, upload, installation, or submission failed.
pause
exit /b 1
