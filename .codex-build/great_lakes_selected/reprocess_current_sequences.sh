#!/bin/bash
set -euo pipefail

if [[ $# -lt 3 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat >&2 <<'EOF'
Usage:
  reprocess_current_sequences.sh ACCOUNT FAST_REPO_DIR RESULTS_DIR [SEQUENCES]

Example:
  ~/great_lakes/reprocess_current_sequences.sh myaccount ~/FAST \
      /scratch/myroot/myaccount/$USER/fast_first_500 1-500

Only checkpoints that are already complete and valid are processed. Running
or pending sequences are left untouched. Rerun this command whenever desired.
EOF
    exit 2
fi

ACCOUNT=$1
export FAST_REPO_DIR=$(cd "$2" && pwd)
export FAST_GL_RESULTS_DIR=$3
export FAST_GL_SEQUENCE_SPEC=${4:-1-500}
export FAST_GL_MAX_ITERATIONS=${FAST_GL_MAX_ITERATIONS:-500}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export FAST_GL_WORKFLOW_DIR=${SCRIPT_DIR}
PARTITION=${FAST_GL_PARTITION:-standard}

if [[ ! -d "${FAST_GL_RESULTS_DIR}/tasks" ]]; then
    echo "Missing task directory: ${FAST_GL_RESULTS_DIR}/tasks" >&2
    exit 2
fi
for REQUIRED in \
    "${FAST_REPO_DIR}/Sequence.mat" \
    "${SCRIPT_DIR}/ProcessSelectedSequenceResults.m" \
    "${SCRIPT_DIR}/HEAOpsPaperResults.m" \
    "${SCRIPT_DIR}/process_results.sbatch"; do
    if [[ ! -f "${REQUIRED}" ]]; then
        echo "Missing required file: ${REQUIRED}" >&2
        exit 2
    fi
done

mkdir -p "${FAST_GL_RESULTS_DIR}/logs" \
    "${FAST_GL_RESULTS_DIR}/combined" \
    "${FAST_GL_RESULTS_DIR}/PaperResults"

JOB_ID=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --time="${FAST_GL_PROCESS_TIME:-04:00:00}" \
    --mem="${FAST_GL_PROCESS_MEMORY:-16G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/reprocess-%j.out" \
    --export=ALL "${SCRIPT_DIR}/process_results.sbatch")

printf 'Reprocessing job: %s\n' "${JOB_ID}"
printf 'Completed now:    '
find "${FAST_GL_RESULTS_DIR}/tasks" \
    -path '*/checkpoints/Sequence_*.mat' -type f | wc -l
printf 'Log:              %s/logs/reprocess-%s.out\n' \
    "${FAST_GL_RESULTS_DIR}" "${JOB_ID}"
printf 'Combined output:  %s/combined\n' "${FAST_GL_RESULTS_DIR}"
printf 'Paper output:     %s/PaperResults\n' "${FAST_GL_RESULTS_DIR}"
