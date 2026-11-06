#!/bin/bash
# Install a consistent code snapshot, then submit a fresh representative-100 run.

set -euo pipefail

STAGE_DIR=${1:-/home/emmasmit/hea250_rep100_stage}
ACCOUNT=${2:-cinar0}
RESULTS_PARENT=${3:-/scratch/cinar_root/cinar0/emmasmit/hea_250_representative100}

if squeue -h -u emmasmit -o '%j' | grep -q '^fast-'; then
    echo "INSTALLATION STOPPED: FAST jobs are still running or pending." >&2
    echo "No live FAST or workflow file was changed and no job was submitted." >&2
    exit 3
fi

for REQUIRED in \
    RunAllSequencesFullComparisonParallel.m RunGreatLakesSequenceTask.m \
    MissionPowerOpt.m SequencePowerOpt.m OptimizationTraceRecorder.m \
    ERJ175LR.m ERJ175LR_PHE.m \
    ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat Seq100Represent.mat \
    PrepareSelectedSequenceRun.m RunSelectedSequenceTask.m \
    CollectSelectedSequenceResults.m ProcessSelectedSequenceResults.m \
    HEAOpsPaperResults.m prepare_selected.sbatch run_selected_sequence.sbatch \
    process_results.sbatch submit_selected_sequences.sh \
    submit_250_representative100.sh; do
    if [[ ! -f "${STAGE_DIR}/${REQUIRED}" ]]; then
        echo "Missing staged file: ${STAGE_DIR}/${REQUIRED}" >&2
        exit 2
    fi
done

BASELINE=$(find /home/emmasmit -maxdepth 6 -type f \
    -name ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat -print -quit \
    2>/dev/null || true)
if [[ -n "${BASELINE}" ]]; then
    FAST_REPO_DIR=${BASELINE%/ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat}
else
    SEQUENCE=$(find /home/emmasmit -maxdepth 6 -type f -name Sequence.mat \
        -print -quit 2>/dev/null || true)
    FAST_REPO_DIR=${SEQUENCE%/Sequence.mat}
fi
if [[ -z "${FAST_REPO_DIR}" || ! -d "${FAST_REPO_DIR}/+OptimizationPkg" ]]; then
    echo "Could not locate the FAST repository." >&2
    exit 2
fi

WORKFLOW_DIR=/home/emmasmit/HEA_OPS/great_lakes
mkdir -p "${WORKFLOW_DIR}"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)

install_atomic() {
    local source=$1 target=$2
    if [[ -f "${target}" ]]; then
        cp "${target}" "${target}.bak.${STAMP}"
    fi
    cp "${source}" "${target}.new.${STAMP}"
    mv "${target}.new.${STAMP}" "${target}"
}

install_atomic "${STAGE_DIR}/RunAllSequencesFullComparisonParallel.m" \
    "${FAST_REPO_DIR}/RunAllSequencesFullComparisonParallel.m"
install_atomic "${STAGE_DIR}/RunGreatLakesSequenceTask.m" \
    "${FAST_REPO_DIR}/RunGreatLakesSequenceTask.m"
install_atomic "${STAGE_DIR}/MissionPowerOpt.m" \
    "${FAST_REPO_DIR}/+OptimizationPkg/MissionPowerOpt.m"
install_atomic "${STAGE_DIR}/SequencePowerOpt.m" \
    "${FAST_REPO_DIR}/+OptimizationPkg/SequencePowerOpt.m"
install_atomic "${STAGE_DIR}/OptimizationTraceRecorder.m" \
    "${FAST_REPO_DIR}/+OptimizationPkg/OptimizationTraceRecorder.m"
install_atomic "${STAGE_DIR}/ERJ175LR.m" \
    "${FAST_REPO_DIR}/+AircraftSpecsPkg/ERJ175LR.m"
install_atomic "${STAGE_DIR}/ERJ175LR_PHE.m" \
    "${FAST_REPO_DIR}/+AircraftSpecsPkg/ERJ175LR_PHE.m"
install_atomic "${STAGE_DIR}/ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat" \
    "${FAST_REPO_DIR}/ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat"
install_atomic "${STAGE_DIR}/Seq100Represent.mat" \
    "${FAST_REPO_DIR}/Seq100Represent.mat"

for FILE in PrepareSelectedSequenceRun.m RunSelectedSequenceTask.m \
        CollectSelectedSequenceResults.m ProcessSelectedSequenceResults.m \
        HEAOpsPaperResults.m prepare_selected.sbatch run_selected_sequence.sbatch \
        process_results.sbatch submit_selected_sequences.sh \
        submit_250_representative100.sh; do
    install_atomic "${STAGE_DIR}/${FILE}" "${WORKFLOW_DIR}/${FILE}"
done
chmod u+x "${WORKFLOW_DIR}"/*.sh "${WORKFLOW_DIR}"/*.sbatch

echo "Installed consistent code snapshot ${STAMP}."
bash "${WORKFLOW_DIR}/submit_250_representative100.sh" \
    "${ACCOUNT}" "${FAST_REPO_DIR}" "${RESULTS_PARENT}"
