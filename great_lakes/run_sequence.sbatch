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
matlab -batch "RunGreatLakesSequenceTask"
