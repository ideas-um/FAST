# Selected-sequence Great Lakes workflow

This workflow runs any chosen subset of the 864 entries in `Sequence.mat`
against a selected, already-sized HEA/PHE baseline MAT file. It sizes a matching
conventional ERJ175LR once, builds the shared exact conventional-flight cache,
runs one isolated Slurm array task per selected sequence, and aggregates the
completed checkpoints into MAT, CSV, and index-list outputs.

The baseline MAT file must contain one complete, converged PHE aircraft named
`BasePHE`, `SizedAircraft`, `Aircraft`, `HEA`, or `PHEAircraft`. The selected HEA
is not resized. Its climb-rate, fuel-flow, and airframe-weight requirements must
match the current conventional ERJ175LR specification used for comparison.

## Submit

On Great Lakes:

```bash
chmod +x ~/great_lakes/*.sh ~/great_lakes/*.sbatch

~/great_lakes/submit_selected_sequences.sh \
    YOUR_SLURM_ACCOUNT \
    ~/FAST \
    ~/baselines/HEA.mat \
    /scratch/YOUR_ROOT/YOUR_ACCOUNT/$USER/hea_run_001 \
    1-500
```

The last argument may be a range or comma list such as `1-20,45,100-125`.
There is no array throttle by default. Set `FAST_GL_ARRAY_LIMIT` before
submission only when an explicit throttle is wanted.

The submission automatically schedules a processing job after the array ends.
Processing may also be rerun at any time:

```bash
~/great_lakes/submit_process_results.sh \
    /scratch/YOUR_ROOT/YOUR_ACCOUNT/$USER/hea_run_001
```

For a current or older run whose manifest is incomplete, process every valid
checkpoint currently available with:

```bash
~/great_lakes/reprocess_current_sequences.sh \
    YOUR_SLURM_ACCOUNT ~/FAST /scratch/PATH/TO/CURRENT_RESULTS 1-500
```

This does not modify, cancel, or rerun sequence optimizations. It only reads
finished checkpoints and replaces the derived combined and paper outputs.

Combined outputs are saved in the run's `combined` directory. Per-iteration
optimizer residuals and objective histories are written to
`SelectedSequences_OptimizationTrace.csv`; joint-versus-individual runtime,
iteration, and function-evaluation totals are written to
`SelectedSequences_OptimizationComparison.csv`. Relative fuel-saving metrics
are written to `SelectedSequences_RelativeFuelSavings.csv`. A negative relative
fuel error means the optimized case saved more fuel: for example, -5% means 5%
additional saving relative to the unoptimized HEA's original saving versus
conventional. Paper tables and figures are written below `PaperResults`.

See `COMMANDS.txt` for login, queue, progress, submission, and processing
commands.
