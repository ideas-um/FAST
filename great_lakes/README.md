# Great Lakes first-500 sequence run

This workflow runs sequence indices 1 through 500. Older results are not
reused because the base aircraft are freshly sized for this run. It submits:

1. one preparation job that sizes the conventional and PHE aircraft from
   their current specification functions and caches the 80 exact
   conventional FAST flights;
2. a 500-task Slurm array, with one sequence per MATLAB process; and
3. one dependent aggregation job that writes combined MAT and CSV results.

Each sequence has an isolated output directory, so concurrent MATLAB jobs
cannot overwrite another task's checkpoint or summary. Rerunning the same
submission is safe: a task whose valid checkpoint already exists is skipped.

No sized-aircraft MAT files are staged or transferred. The preparation job
runs `Main(AircraftSpecsPkg.ERJ175LR, ...)` and
`Main(AircraftSpecsPkg.ERJ175LR_PHE, ...)` once on Great Lakes, validates
that both converge, and saves a run-local pair for the dependent array jobs.

## Smoke test first

Use the same results directory planned for the production run:

```bash
cd /path/to/FAST
chmod +x great_lakes/*.sh great_lakes/*.sbatch
export FAST_GL_RESULTS_DIR=/scratch/YOUR_ACCOUNT/YOUR_UNIQNAME/fast_first_500
./great_lakes/submit_smoke_test.sh YOUR_SLURM_ACCOUNT
```

Wait for the job to leave the queue, then require both a successful Slurm
state and the current-version pass marker:

```bash
sacct -j SMOKE_JOB_ID --format=JobID,State,ExitCode,Elapsed,MaxRSS
cat "$FAST_GL_RESULTS_DIR/logs/smoke-SMOKE_JOB_ID.out"
cat "$FAST_GL_RESULTS_DIR/smoke/SmokeTest.passed"
```

The log must contain `GREAT_LAKES_SMOKE_TEST=PASS`. The full submission
script refuses to submit without this pass marker unless
`FAST_SKIP_SMOKE_CHECK=1` is explicitly set.

## Submit

On a Great Lakes login node, clone or update this branch and then run:

```bash
cd /path/to/FAST
chmod +x great_lakes/*.sh great_lakes/*.sbatch
export FAST_GL_RESULTS_DIR=/scratch/YOUR_ACCOUNT/YOUR_UNIQNAME/fast_first_500
export FAST_GL_ARRAY_LIMIT=20
./great_lakes/submit_first_500.sh YOUR_SLURM_ACCOUNT
```

`FAST_GL_ARRAY_LIMIT` controls simultaneous array tasks. The default is 20;
raise it only after observing memory, MATLAB-license, and account limits.
Optional overrides are `FAST_GL_PARTITION`, `FAST_GL_TASK_TIME`,
`FAST_GL_TASK_MEMORY`, `FAST_GL_PREP_TIME`, and `FAST_GL_PREP_MEMORY`.

Monitor jobs with `squeue -u "$USER"`. Logs are written below
`$FAST_GL_RESULTS_DIR/logs`. Final combined files are written below
`$FAST_GL_RESULTS_DIR/combined`, including a task-status CSV and explicit
completed/missing index lists for targeted retries.
