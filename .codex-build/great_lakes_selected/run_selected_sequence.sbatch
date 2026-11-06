#!/bin/bash
#SBATCH --job-name=fast-seq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

set -euo pipefail
cd "${FAST_REPO_DIR}"
export FAST_SEQUENCE_INDEX=${SLURM_ARRAY_TASK_ID}
module load matlab

MAX_MATLAB_START_ATTEMPTS=3
for ATTEMPT in $(seq 1 ${MAX_MATLAB_START_ATTEMPTS}); do
    echo "MATLAB attempt ${ATTEMPT}/${MAX_MATLAB_START_ATTEMPTS} for sequence ${FAST_SEQUENCE_INDEX}"
    ATTEMPT_LOG="${SLURM_TMPDIR:-/tmp}/fast_matlab_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}_${ATTEMPT}.log"
    if matlab -batch "addpath('${FAST_GL_WORKFLOW_DIR}'); RunSelectedSequenceTask" \
            2>&1 | tee "${ATTEMPT_LOG}"; then
        exit 0
    else
        MATLAB_STATUS=${PIPESTATUS[0]}
    fi
    if ! grep -Eiq "Fatal Startup Error|License Manager Error|license checkout failed" \
            "${ATTEMPT_LOG}"; then
        echo "MATLAB reached FAST and failed; not retrying a model error." >&2
        exit "${MATLAB_STATUS}"
    fi
    if (( ATTEMPT < MAX_MATLAB_START_ATTEMPTS )); then
        sleep $((15 * ATTEMPT))
    fi
done

echo "MATLAB startup failed after ${MAX_MATLAB_START_ATTEMPTS} attempts." >&2
exit 1
