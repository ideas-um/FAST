@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "FAST_LOCAL=%~dp0"

echo Uploading the failure-reporting and replay fixes to a staging area...
scp "%FAST_LOCAL%RunAllSequencesFullComparisonParallel.m" "%FAST_LOCAL%RunGreatLakesSequenceTask.m" "%FAST_LOCAL%+OptimizationPkg\SequencePowerOpt.m" "%FAST_LOCAL%+OptimizationPkg\OptimizationTraceRecorder.m" "%GL_HOST%:/home/emmasmit/"
if errorlevel 1 goto :failed

echo Checking that no FAST sequence tasks are running before installation...
ssh "%GL_HOST%" "set -e; if squeue -h -u emmasmit -n fast-seq | grep -q .; then echo 'INSTALLATION STOPPED: fast-seq jobs are still running or pending. No live code was changed.'; exit 3; fi; fast_repo_dir=$(dirname $(find /home/emmasmit -maxdepth 6 -type f -name Sequence.mat -print -quit)); test -d $fast_repo_dir; stamp=$(date -u +%%Y%%m%%dT%%H%%M%%SZ); cp $fast_repo_dir/RunAllSequencesFullComparisonParallel.m $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.bak.$stamp; cp $fast_repo_dir/RunGreatLakesSequenceTask.m $fast_repo_dir/RunGreatLakesSequenceTask.m.bak.$stamp; cp $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m.bak.$stamp; if test -f $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m; then cp $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m.bak.$stamp; fi; cp /home/emmasmit/RunAllSequencesFullComparisonParallel.m $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.new.$stamp; cp /home/emmasmit/RunGreatLakesSequenceTask.m $fast_repo_dir/RunGreatLakesSequenceTask.m.new.$stamp; cp /home/emmasmit/SequencePowerOpt.m $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m.new.$stamp; cp /home/emmasmit/OptimizationTraceRecorder.m $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m.new.$stamp; mv $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.new.$stamp $fast_repo_dir/RunAllSequencesFullComparisonParallel.m; mv $fast_repo_dir/RunGreatLakesSequenceTask.m.new.$stamp $fast_repo_dir/RunGreatLakesSequenceTask.m; mv $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m.new.$stamp $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m; mv $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m.new.$stamp $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m; echo INSTALLED_FAILURE_FIX=$stamp"
if errorlevel 1 goto :blocked_or_failed

echo.
echo Fix installed. No jobs were submitted.
pause
exit /b 0

:blocked_or_failed
echo.
echo Installation was blocked or failed. If fast-seq jobs are active, wait for them or cancel them before trying again.
pause
exit /b 1

:failed
echo.
echo Upload failed. No live Great Lakes code was changed.
pause
exit /b 1
