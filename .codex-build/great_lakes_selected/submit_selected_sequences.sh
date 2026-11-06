#!/bin/bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  submit_selected_sequences.sh ACCOUNT FAST_REPO_DIR HEA_MAT RESULTS_DIR [SEQUENCES]

Example:
  ./submit_selected_sequences.sh myaccount ~/FAST ~/baselines/HEA.mat \
      /scratch/myaccount/$USER/hea_run_001 1-500

SEQUENCES defaults to 1-500 and accepts Slurm array syntax made from integer
ranges and comma lists, for example: 1-20,45,100-125. Valid indices are 1-864.
No array throttle is applied unless FAST_GL_ARRAY_LIMIT is explicitly set.
EOF
}

if [[ $# -lt 4 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 2
fi

ACCOUNT=$1
export FAST_REPO_DIR=$(cd "$2" && pwd)
export FAST_HEA_BASELINE_FILE=$(realpath "$3")
export FAST_GL_RESULTS_DIR=$4
export FAST_GL_SEQUENCE_SPEC=${5:-1-500}
export FAST_GL_MAX_ITERATIONS=${FAST_GL_MAX_ITERATIONS:-500}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export FAST_GL_WORKFLOW_DIR=${SCRIPT_DIR}

for REQUIRED in \
    "${FAST_REPO_DIR}/Sequence.mat" \
    "${FAST_REPO_DIR}/RunAllSequencesFullComparisonParallel.m" \
    "${FAST_HEA_BASELINE_FILE}" \
    "${SCRIPT_DIR}/PrepareSelectedSequenceRun.m" \
    "${SCRIPT_DIR}/RunSelectedSequenceTask.m" \
    "${SCRIPT_DIR}/CollectSelectedSequenceResults.m"; do
    if [[ ! -f "${REQUIRED}" ]]; then
        echo "Missing required file: ${REQUIRED}" >&2
        exit 2
    fi
done

IFS=',' read -ra SELECTION_PARTS <<< "${FAST_GL_SEQUENCE_SPEC}"
for PART in "${SELECTION_PARTS[@]}"; do
    if [[ "${PART}" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        FIRST=${BASH_REMATCH[1]}
        LAST=${BASH_REMATCH[2]}
    elif [[ "${PART}" =~ ^[0-9]+$ ]]; then
        FIRST=${PART}
        LAST=${PART}
    else
        echo "Invalid sequence selection: ${FAST_GL_SEQUENCE_SPEC}" >&2
        exit 2
    fi
    if (( FIRST < 1 || LAST > 864 || FIRST > LAST )); then
        echo "Sequence indices must be ordered and between 1 and 864: ${PART}" >&2
        exit 2
    fi
done

ARRAY_SPEC=${FAST_GL_SEQUENCE_SPEC}
if [[ -n "${FAST_GL_ARRAY_LIMIT:-}" ]]; then
    if [[ ! "${FAST_GL_ARRAY_LIMIT}" =~ ^[1-9][0-9]*$ ]]; then
        echo "FAST_GL_ARRAY_LIMIT must be a positive integer when set." >&2
        exit 2
    fi
    ARRAY_SPEC="${ARRAY_SPEC}%${FAST_GL_ARRAY_LIMIT}"
fi

PARTITION=${FAST_GL_PARTITION:-standard}
mkdir -p "${FAST_GL_RESULTS_DIR}/logs" \
    "${FAST_GL_RESULTS_DIR}/tasks" \
    "${FAST_GL_RESULTS_DIR}/combined" \
    "${FAST_GL_RESULTS_DIR}/prepared"

PREP_JOB=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --time="${FAST_GL_PREP_TIME:-12:00:00}" \
    --mem="${FAST_GL_PREP_MEMORY:-24G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/prepare-%j.out" \
    --export=ALL "${SCRIPT_DIR}/prepare_selected.sbatch")

ARRAY_JOB=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --dependency="afterok:${PREP_JOB}" --array="${ARRAY_SPEC}" \
    --time="${FAST_GL_TASK_TIME:-3-00:00:00}" \
    --mem="${FAST_GL_TASK_MEMORY:-24G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/sequence-%A_%a.out" \
    --export=ALL "${SCRIPT_DIR}/run_selected_sequence.sbatch")

PROCESS_JOB=$(sbatch --parsable \
    --account="${ACCOUNT}" --partition="${PARTITION}" \
    --dependency="afterany:${ARRAY_JOB}" \
    --time="${FAST_GL_PROCESS_TIME:-02:00:00}" \
    --mem="${FAST_GL_PROCESS_MEMORY:-8G}" \
    --output="${FAST_GL_RESULTS_DIR}/logs/process-%j.out" \
    --export=ALL "${SCRIPT_DIR}/process_results.sbatch")

MANIFEST_TMP="${FAST_GL_RESULTS_DIR}/.current_run.env.$$"
{
    printf 'FAST_GL_RUN_SUBMITTED_UTC=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'FAST_GL_RUN_ACCOUNT=%q\n' "${ACCOUNT}"
    printf 'FAST_GL_RUN_PARTITION=%q\n' "${PARTITION}"
    printf 'FAST_GL_RUN_RESULTS_DIR=%q\n' "${FAST_GL_RESULTS_DIR}"
    printf 'FAST_GL_RESULTS_DIR=%q\n' "${FAST_GL_RESULTS_DIR}"
    printf 'FAST_REPO_DIR=%q\n' "${FAST_REPO_DIR}"
    printf 'FAST_GL_WORKFLOW_DIR=%q\n' "${FAST_GL_WORKFLOW_DIR}"
    printf 'FAST_HEA_BASELINE_FILE=%q\n' "${FAST_HEA_BASELINE_FILE}"
    printf 'FAST_GL_SEQUENCE_SPEC=%q\n' "${FAST_GL_SEQUENCE_SPEC}"
    printf 'FAST_GL_MAX_ITERATIONS=%q\n' "${FAST_GL_MAX_ITERATIONS}"
    printf 'FAST_GL_RUN_PREP_JOB=%q\n' "${PREP_JOB}"
    printf 'FAST_GL_RUN_ARRAY_JOB=%q\n' "${ARRAY_JOB}"
    printf 'FAST_GL_RUN_PROCESS_JOB=%q\n' "${PROCESS_JOB}"
} > "${MANIFEST_TMP}"
mv "${MANIFEST_TMP}" "${FAST_GL_RESULTS_DIR}/current_run.env"

printf 'Preparation job: %s\n' "${PREP_JOB}"
printf 'Sequence array:  %s (%s)\n' "${ARRAY_JOB}" "${ARRAY_SPEC}"
printf 'Processing job:  %s\n' "${PROCESS_JOB}"
printf 'Baseline HEA:    %s\n' "${FAST_HEA_BASELINE_FILE}"
printf 'Results:         %s\n' "${FAST_GL_RESULTS_DIR}"
if [[ -z "${FAST_GL_ARRAY_LIMIT:-}" ]]; then
    printf 'Array throttle:  none (Great Lakes scheduling limits apply)\n'
fi
