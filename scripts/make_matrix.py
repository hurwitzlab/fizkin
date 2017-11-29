#!/usr/bin/env python3

"""Make matrix from modes"""

import argparse
import glob
import os
import sys
from math import log

# --------------------------------------------------
def get_args():
    """get args"""
    parser = argparse.ArgumentParser(description='Make matrix from modes')
    parser.add_argument('-m', '--mode_dir', help='Mode directory',
                        metavar='DIR', type=str, required=True)
    parser.add_argument('-o', '--out_dir', help='Matrix output dir',
                        metavar='DIR', type=str, default=os.getcwd())
    return parser.parse_args()

# --------------------------------------------------
def main():
    """main"""
    args = get_args()
    mode_dir = args.mode_dir
    out_dir = args.out_dir

    if not mode_dir:
        print('--mode_dir is required')
        sys.exit(1)

    if not os.path.isdir(mode_dir):
        print('Bad --mode_dir "{}"'.format(mode_dir))
        sys.exit(1)

    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    mode_files = list(filter(os.path.isfile,
                             glob.iglob(mode_dir + '/**', recursive=True)))
    print('Found {} mode files'.format(len(mode_files)))

    counts = {}
    for file in mode_files:
        sample1 = os.path.basename(os.path.dirname(file))
        sample2 = os.path.basename(file)
        num = open(file).read().strip()
        if not sample1 in counts:
            counts[sample1] = {}
        counts[sample1][sample2] = int(num)

    all_keys = set(counts.keys())
    for key in all_keys:
        map(all_keys.add, counts[key].keys())

    all_samples = sorted(all_keys)

    raw_file = os.path.join(out_dir, 'matrix_raw.txt')
    raw_fh = open(raw_file, 'w')

    norm_file = os.path.join(out_dir, 'matrix_normalized.txt')
    norm_fh = open(norm_file, 'w')

    raw_fh.write('\t'.join([''] + all_samples) + '\n')
    norm_fh.write('\t'.join([''] + all_samples) + '\n')

    for sample1 in all_samples:
        raw = [sample1]
        norm = [sample1]
        for sample2 in all_samples:
            n1 = counts[sample1].get(sample2, 0)
            n2 = counts[sample2].get(sample1, 0)
            avg = (n1 + n2) / 2

            raw.append(str(n1))
            norm.append('{:.4f}'.format(log(avg)) if avg > 0 else '0')

        raw_fh.write('\t'.join(raw) + '\n')
        norm_fh.write('\t'.join(norm) + '\n')

    print('Done, see files in dir "{}"'.format(out_dir))

# --------------------------------------------------
if __name__ == '__main__':
    main()
