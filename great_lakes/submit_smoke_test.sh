#!/bin/bash
set -euo pipefail

ACCOUNT=${1:-${FAST_GL_ACCOUNT:-}}
if [[ -z "${ACCOUNT}" ]]; then
    echo "Usage: FAST_GL_RESULTS_DIR=/scratch/... $0 <slurm-account>" >&2
    exit 2
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export FAST_REPO_DIR=${FAST_REPO_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}
: "${FAST_GL_RESULTS_DIR:?Set FAST_GL_RESULTS_DIR to the intended production results directory.}"

for REQUIRED in \
    "${FAST_REPO_DIR}/Sequence.mat" \
    "${FAST_REPO_DIR}/RunGreatLakesSmokeTest.m" \
    "${FAST_REPO_DIR}/SizeERJ175LRBaseAircraft.m"; do
    if [[ ! -f "${REQUIRED}" ]]; then
        echo "Missing required file: ${REQUIRED}" >&2
        exit 2
    fi
done

PARTITION=${FAST_GL_PARTITION:-standard}
mkdir -p "${FAST_GL_RESULTS_DIR}/logs" "${FAST_GL_RESULTS_DIR}/smoke"

SMOKE_JOB=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --time="${FAST_GL_SMOKE_TIME:-02:00:00}" \
    --mem="${FAST_GL_SMOKE_MEMORY:-16G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/smoke-%j.out" \
    --export=ALL "${SCRIPT_DIR}/smoke_test.sbatch")

printf 'Smoke-test job: %s\n' "${SMOKE_JOB}"
printf 'Monitor:        squeue -j %s\n' "${SMOKE_JOB}"
printf 'Log:            %s/logs/smoke-%s.out\n' "${FAST_GL_RESULTS_DIR}" "${SMOKE_JOB}"
printf 'Pass marker:    %s/smoke/SmokeTest.passed\n' "${FAST_GL_RESULTS_DIR}"
