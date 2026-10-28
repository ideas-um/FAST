#!/bin/bash
#SBATCH --job-name=fast-cache
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

set -euo pipefail
cd "${FAST_REPO_DIR}"
module load matlab
matlab -batch "RunGreatLakesPrepare"
