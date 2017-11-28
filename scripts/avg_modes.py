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
                        metavar='str', type=str, required=True)
    parser.add_argument('-o', '--out_file', help='Matrix output file',
                        metavar='str', type=str, default='matrix.txt')
    return parser.parse_args()

# --------------------------------------------------
def main():
    """main"""
    args = get_args()
    mode_dir = args.mode_dir
    matrix_file = args.out_file

    if not mode_dir:
        print('--mode_dir is required')
        sys.exit(1)

    if not os.path.isdir(mode_dir):
        print('Bad --mode_dir "{}"'.format(mode_dir))
        sys.exit(1)

    out_dir = os.path.dirname(matrix_file)
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

    out_fh = open(matrix_file, 'w')
    out_fh.write('\t'.join([''] + all_samples) + '\n')

    for sample1 in all_samples:
        row = [sample1]
        for sample2 in all_samples:
            avg = (counts[sample1].get(sample2, 0)
                   + counts[sample2].get(sample1, 0)) / 2
            row.append('{:.4f}'.format(log(avg)) if avg > 0 else '0')

        out_fh.write('\t'.join(row) + '\n')

    print('Done, see matrix file "{}"'.format(matrix_file))

# --------------------------------------------------
if __name__ == '__main__':
    main()
