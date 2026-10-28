# Great Lakes first-500 sequence run

This workflow runs sequence indices 1 through 500, excluding 24, 50, and
52 because those results already exist. It submits:

1. one cache-preparation job for the 80 exact conventional FAST flights;
2. a 497-task Slurm array, with one sequence per MATLAB process; and
3. one dependent aggregation job that writes combined MAT and CSV results.

Each sequence has an isolated output directory, so concurrent MATLAB jobs
cannot overwrite another task's checkpoint or summary. Rerunning the same
submission is safe: a task whose valid checkpoint already exists is skipped.

## Required staged inputs

The sized aircraft files are intentionally excluded from Git. Copy the exact
files used on `emmascodemachin` into a Great Lakes input directory:

```text
ERJ175LR_PHE_Sized.mat
ERJ175LR_Conventional_RegularTakeoff_Calibrated.mat
```

The first file must contain `SizedAircraft`; the second must contain `C`.

## Submit

On a Great Lakes login node, clone or update this branch and then run:

```bash
cd /path/to/FAST
chmod +x great_lakes/*.sh great_lakes/*.sbatch
export FAST_GL_RESULTS_DIR=/scratch/YOUR_ACCOUNT/YOUR_UNIQNAME/fast_first_500
export FAST_GL_INPUT_DIR=/path/to/staged/aircraft_inputs
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
