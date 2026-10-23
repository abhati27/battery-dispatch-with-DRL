#!/bin/bash
# Submits the full experiment for one task: 5 seeds per algorithm, plus a stats job
# that starts once all of them have finished. PPO and DDPG run on CPU, DQN and SAC on GPU.
# Usage: bash hpc/submit_all.sh <delf|abea> [algorithms...]
#   bash hpc/submit_all.sh abea          # all four algorithms
#   bash hpc/submit_all.sh delf ddpg     # only DDPG
set -e
cd "$(dirname "$0")/.."

TASK=$1
shift
if [ "$TASK" != delf ] && [ "$TASK" != abea ]; then
    echo "Usage: bash hpc/submit_all.sh <delf|abea> [algorithms...]"
    exit 1
fi
ALGOS=("$@")
if [ ${#ALGOS[@]} -eq 0 ]; then
    ALGOS=(dqn ppo sac ddpg)
fi

GPU="--partition=course_gpu --gres=gpu:a100_10g:1 --cpus-per-task=1"

ids=""
for algo in "${ALGOS[@]}"; do
    case $algo in
        ppo)  opts="--time=02:00:00" ;;
        ddpg) opts="--time=03:00:00" ;;
        dqn)  opts="--time=05:00:00 $GPU" ;;
        sac)  opts="--time=06:00:00 $GPU" ;;
        *) echo "Unknown algorithm: $algo"; exit 1 ;;
    esac
    id=$(sbatch --parsable --job-name=${TASK}_${algo} $opts hpc/train.sbatch $TASK $algo)
    echo "Submitted $TASK $algo: $id"
    ids="$ids:$id"
done

stats=$(sbatch --parsable --dependency=afterok$ids hpc/stats.sbatch $TASK "${ALGOS[@]}")
echo "Submitted stats: $stats (starts when all runs finish)"
echo "Check progress with: bash hpc/status.sh"
