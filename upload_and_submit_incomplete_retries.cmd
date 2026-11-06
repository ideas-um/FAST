@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "FAST_LOCAL=%~dp0"
set "WORKFLOW_LOCAL=%~dp0..\great_lakes"

echo Uploading the retry-policy and failure-reporting update to Great Lakes...
scp "%FAST_LOCAL%+OptimizationPkg\SequencePowerOpt.m" "%FAST_LOCAL%+OptimizationPkg\OptimizationTraceRecorder.m" "%FAST_LOCAL%RunAllSequencesFullComparisonParallel.m" "%FAST_LOCAL%RunGreatLakesSequenceTask.m" "%WORKFLOW_LOCAL%\resubmit_incomplete_current.sh" "%GL_HOST%:/home/emmasmit/"
if errorlevel 1 goto :failed

echo Installing only when no FAST sequence jobs are active, then submitting incomplete retries...
ssh "%GL_HOST%" "set -e; if squeue -h -u emmasmit -n fast-seq | grep -q .; then echo 'INSTALLATION STOPPED: fast-seq jobs are still running or pending. No live code was changed and no retries were submitted.'; exit 3; fi; fast_repo_dir=$(dirname $(find /home/emmasmit -maxdepth 6 -type f -name Sequence.mat -print -quit)); test -d $fast_repo_dir; stamp=$(date -u +%%Y%%m%%dT%%H%%M%%SZ); cp $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m.bak.$stamp; cp $fast_repo_dir/RunAllSequencesFullComparisonParallel.m $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.bak.$stamp; cp $fast_repo_dir/RunGreatLakesSequenceTask.m $fast_repo_dir/RunGreatLakesSequenceTask.m.bak.$stamp; if test -f $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m; then cp $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m.bak.$stamp; fi; cp /home/emmasmit/SequencePowerOpt.m $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m.new.$stamp; cp /home/emmasmit/OptimizationTraceRecorder.m $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m.new.$stamp; cp /home/emmasmit/RunAllSequencesFullComparisonParallel.m $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.new.$stamp; cp /home/emmasmit/RunGreatLakesSequenceTask.m $fast_repo_dir/RunGreatLakesSequenceTask.m.new.$stamp; mv $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m.new.$stamp $fast_repo_dir/+OptimizationPkg/SequencePowerOpt.m; mv $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m.new.$stamp $fast_repo_dir/+OptimizationPkg/OptimizationTraceRecorder.m; mv $fast_repo_dir/RunAllSequencesFullComparisonParallel.m.new.$stamp $fast_repo_dir/RunAllSequencesFullComparisonParallel.m; mv $fast_repo_dir/RunGreatLakesSequenceTask.m.new.$stamp $fast_repo_dir/RunGreatLakesSequenceTask.m; cp /home/emmasmit/resubmit_incomplete_current.sh /home/emmasmit/HEA_OPS/great_lakes/resubmit_incomplete_current.sh; sed -i 's/\r$//' /home/emmasmit/HEA_OPS/great_lakes/resubmit_incomplete_current.sh; bash /home/emmasmit/HEA_OPS/great_lakes/resubmit_incomplete_current.sh"
if errorlevel 1 goto :failed

echo.
echo Update and retry submission completed successfully.
pause
exit /b 0

:failed
echo.
echo The update or submission failed. Review the message above; no existing MATLAB file was overwritten without a timestamped backup.
pause
exit /b 1
