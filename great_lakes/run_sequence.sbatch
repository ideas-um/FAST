#!/bin/bash
#SBATCH --job-name=fast-seq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

set -euo pipefail
cd "${FAST_REPO_DIR}"

# Map array positions 1:497 to sequence numbers 1:500 while omitting the
# three sequences that already have accepted results.
SEQUENCE_INDEX=${SLURM_ARRAY_TASK_ID}
for OMITTED in 24 50 52; do
    if (( SEQUENCE_INDEX >= OMITTED )); then
        SEQUENCE_INDEX=$((SEQUENCE_INDEX + 1))
    fi
done
export FAST_SEQUENCE_INDEX=${SEQUENCE_INDEX}

module load matlab

# A transient MATLAB startup/license/filesystem-service failure should not
# discard an otherwise valid array task. The MATLAB workflow is checkpointed,
# so retrying the same sequence is safe; a completed checkpoint is skipped.
MAX_MATLAB_START_ATTEMPTS=3
for ATTEMPT in $(seq 1 ${MAX_MATLAB_START_ATTEMPTS}); do
    echo "MATLAB attempt ${ATTEMPT}/${MAX_MATLAB_START_ATTEMPTS} for sequence ${FAST_SEQUENCE_INDEX}"
    ATTEMPT_LOG="${SLURM_TMPDIR:-/tmp}/fast_matlab_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}_${ATTEMPT}.log"
    if matlab -batch "RunGreatLakesSequenceTask" 2>&1 | tee "${ATTEMPT_LOG}"; then
        exit 0
    else
        MATLAB_STATUS=${PIPESTATUS[0]}
    fi
    if ! grep -Eiq "Fatal Startup Error|License Manager Error|license checkout failed" "${ATTEMPT_LOG}"; then
        echo "MATLAB reached the FAST workflow and failed with a non-startup error; not retrying." >&2
        exit "${MATLAB_STATUS}"
    fi
    if (( ATTEMPT < MAX_MATLAB_START_ATTEMPTS )); then
        sleep $((15 * ATTEMPT))
    fi
done

echo "MATLAB failed after ${MAX_MATLAB_START_ATTEMPTS} attempts for sequence ${FAST_SEQUENCE_INDEX}" >&2
exit 1
