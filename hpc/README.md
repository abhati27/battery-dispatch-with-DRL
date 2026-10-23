# Running on Wulver (NJIT HPC)

All files live in the course directory `/course/2026/fall/cs/669/tn294/ab3367`. Submit every job from the repo root; Slurm logs go to `hpc/out/`.

1. Build the environment (once):

   ```bash
   sbatch hpc/setup_env.sbatch
   ```

2. Short check, 1 seed x 1 episode per algorithm:

   ```bash
   sbatch hpc/smoke.sbatch
   sbatch --partition=course_gpu --gres=gpu:a100_10g:1 --job-name=smoke_gpu hpc/smoke.sbatch dqn sac
   ```

   `compute_time` in `log/de1_bat_hes/<algo>/run/smoke_<partition>/run_0/output.json` is the time for one episode; multiply by 50 (plus margin) to set `--time` for the full run.

3. Full run, 5 seeds per algorithm as a job array:

   ```bash
   sbatch --job-name=delf_dqn hpc/delf.sbatch dqn
   sbatch --job-name=delf_ppo hpc/delf.sbatch ppo
   sbatch --job-name=delf_sac hpc/delf.sbatch sac
   ```

4. Stats once all seeds finish:

   ```bash
   sbatch --dependency=afterok:<dqn_id>:<ppo_id>:<sac_id> hpc/stats.sbatch dqn ppo sac
   ```

Monitor with `squeue -u $USER`, `seff <jobid>`, and cancel with `scancel <jobid>`.
