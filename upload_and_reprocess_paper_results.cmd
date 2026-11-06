@echo off
setlocal

set "GL_HOST=emmasmit@greatlakes.arc-ts.umich.edu"
set "WORKFLOW_LOCAL=%~dp0..\great_lakes"

echo Uploading the revised clean reprocessing workflow to Great Lakes...
scp "%WORKFLOW_LOCAL%\HEAOpsPaperResults.m" "%WORKFLOW_LOCAL%\process_results.sbatch" "%WORKFLOW_LOCAL%\reprocess_current_sequences.sh" "%GL_HOST%:/home/emmasmit/"
if errorlevel 1 goto :failed

echo Installing the processor and submitting a 4-GiB reprocessing job...
ssh "%GL_HOST%" "set -e; stamp=$(date -u +%%Y%%m%%dT%%H%%M%%SZ); workflow=/home/emmasmit/HEA_OPS/great_lakes; for f in HEAOpsPaperResults.m process_results.sbatch reprocess_current_sequences.sh; do if test -f $workflow/$f; then cp $workflow/$f $workflow/$f.bak.$stamp; fi; cp /home/emmasmit/$f $workflow/$f; done; fast_repo_dir=$(dirname $(find /home/emmasmit -maxdepth 6 -type f -name Sequence.mat -print -quit)); test -d $fast_repo_dir; FAST_GL_PROCESS_MEMORY=4G FAST_GL_FRESH_PROCESS_OUTPUT=1 bash $workflow/reprocess_current_sequences.sh cinar0 $fast_repo_dir /scratch/cinar_root/cinar0/emmasmit/fast_first_500_v4 1-500"
if errorlevel 1 goto :failed

echo.
echo Clean processing job submitted successfully.
echo Previous combined and PaperResults folders will be archived at job start.
pause
exit /b 0

:failed
echo.
echo Upload or submission failed. Review the message above; the previous processor has a timestamped backup if installation was reached.
pause
exit /b 1
