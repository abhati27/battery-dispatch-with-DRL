import os
import sys
import csv
import json
import statistics


# Summarize finished runs the same way as the paper's Tables 3 and 4: mean ± std across seeds of the
# average reward over the last 5 training episodes, in thousand C$. Only needs the Python standard library.
# Usage: python -m main.summarize_results <delf|abea>
ENV_NAMES = {'delf': 'de1_bat_hes', 'abea': 'al4_bat_ea'}

base = os.path.join('log', ENV_NAMES[sys.argv[1]])
print(f"{'model':6} {'seeds':>5} {'train (last 5 eps)':>20} {'final eval':>16}")
for algo in ['dqn', 'ppo', 'sac', 'ddpg']:
    path = os.path.join(base, algo, 'run', 'full')
    if not os.path.isdir(path):
        continue
    with open(os.path.join(path, 'inputs.json')) as f:
        n_episodes = json.load(f)['EXP_PARAMS']['n_episodes']

    train, final = [], []
    for run in sorted(d for d in os.listdir(path) if d.startswith('run_')):
        output = os.path.join(path, run, 'output.json')
        if not os.path.exists(output):  # run not finished
            continue
        with open(os.path.join(path, run, 'train_monitor.csv')) as f:
            next(f)  # Monitor header line
            rewards = [float(row['r']) for row in csv.DictReader(f)]
        # The final evaluation episode is appended after the training episodes
        train.append(sum(rewards[n_episodes - 5:n_episodes]) / 5 / 1e3)
        with open(output) as f:
            final.append(json.load(f)['reward_sum'] / 1e3)

    if train:
        print(f"{algo.upper():6} {len(train):>5} {statistics.mean(train):>12.0f} ± {statistics.pstdev(train):5.1f}"
              f" {statistics.mean(final):>8.0f} ± {statistics.pstdev(final):5.1f}")
