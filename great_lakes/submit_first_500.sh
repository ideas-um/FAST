#!/bin/bash
set -euo pipefail

ACCOUNT=${1:-${FAST_GL_ACCOUNT:-}}
if [[ -z "${ACCOUNT}" ]]; then
    echo "Usage: FAST_GL_RESULTS_DIR=/scratch/... $0 <slurm-account>" >&2
    exit 2
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export FAST_REPO_DIR=${FAST_REPO_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}
: "${FAST_GL_RESULTS_DIR:?Set FAST_GL_RESULTS_DIR to a durable Great Lakes results directory.}"

SMOKE_VERSION=all-sequences-v4-source-sized-base-aircraft
SMOKE_MARKER="${FAST_GL_RESULTS_DIR}/smoke/SmokeTest.passed"
if [[ "${FAST_SKIP_SMOKE_CHECK:-0}" != "1" ]]; then
    if [[ ! -f "${SMOKE_MARKER}" ]] || ! grep -qx "${SMOKE_VERSION}" "${SMOKE_MARKER}"; then
        echo "A passing current-version smoke test is required before the full submission." >&2
        echo "Run: ./great_lakes/submit_smoke_test.sh ${ACCOUNT}" >&2
        echo "Then wait for ${SMOKE_MARKER}." >&2
        exit 2
    fi
fi

for REQUIRED in "${FAST_REPO_DIR}/Sequence.mat"; do
    if [[ ! -f "${REQUIRED}" ]]; then
        echo "Missing required file: ${REQUIRED}" >&2
        exit 2
    fi
done

PARTITION=${FAST_GL_PARTITION:-standard}
ARRAY_LIMIT=${FAST_GL_ARRAY_LIMIT:-20}
mkdir -p "${FAST_GL_RESULTS_DIR}/logs" \
    "${FAST_GL_RESULTS_DIR}/tasks" \
    "${FAST_GL_RESULTS_DIR}/combined"

PREP_JOB=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --time="${FAST_GL_PREP_TIME:-12:00:00}" --mem="${FAST_GL_PREP_MEMORY:-16G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/cache-%j.out" \
    --export=ALL "${SCRIPT_DIR}/prepare_cache.sbatch")

ARRAY_JOB=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --dependency="afterok:${PREP_JOB}" --array="1-500%${ARRAY_LIMIT}" \
    --time="${FAST_GL_TASK_TIME:-3-00:00:00}" --mem="${FAST_GL_TASK_MEMORY:-24G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/sequence-%A_%a.out" \
    --export=ALL "${SCRIPT_DIR}/run_sequence.sbatch")

COLLECT_JOB=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --dependency="afterany:${ARRAY_JOB}" \
    --time="${FAST_GL_COLLECT_TIME:-02:00:00}" --mem="${FAST_GL_COLLECT_MEMORY:-8G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/collect-%j.out" \
    --export=ALL "${SCRIPT_DIR}/collect_results.sbatch")

printf 'Cache job:      %s\n' "${PREP_JOB}"
printf 'Sequence array: %s (500 tasks, at most %s concurrent)\n' "${ARRAY_JOB}" "${ARRAY_LIMIT}"
printf 'Collect job:    %s\n' "${COLLECT_JOB}"
printf 'Results root:   %s\n' "${FAST_GL_RESULTS_DIR}"
