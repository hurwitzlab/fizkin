#!/usr/bin/env python3

"""Make matrix from modes"""

import argparse
import glob
import os
import sys
from math import log
import pandas as pd
from scipy.spatial.distance import pdist, squareform

# --------------------------------------------------
def get_args():
    """get args"""
    parser = argparse.ArgumentParser(
        description='Make matrix from modes',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument(
        '-d', '--distance_method', help='Distance method',
        metavar='STR', type=str, default="euclidean")

    parser.add_argument(
        '-m', '--mode_dir', help='Mode directory',
        metavar='DIR', type=str, required=True)

    parser.add_argument(
        '-o', '--out_dir', help='Matrix output dir',
        metavar='DIR', type=str, default=os.getcwd())

    return parser.parse_args()

# --------------------------------------------------
def main():
    """main"""
    args = get_args()
    mode_dir = args.mode_dir
    out_dir = args.out_dir
    distance_method = args.distance_method
    valid_distance = set("""
        braycurtis canberra chebyshev cityblock correlation cosine 
        dice euclidean hamming jaccard kulsinski matching rogerstanimoto 
        russellrao seuclidean sokalmichener sokalsneath sqeuclidean yule.
        """.split())

    if not mode_dir:
        print('--mode_dir is required')
        sys.exit(1)

    if not os.path.isdir(mode_dir):
        print('Bad --mode_dir "{}"'.format(mode_dir))
        sys.exit(1)

    if not distance_method in valid_distance:
        print('--distance_method "{}" is not valid'.format(distance_method))
        print('Please select from {}'.format(', '.join(valid_distance)))
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

    avg_file = os.path.join(out_dir, 'matrix_avg.txt')
    avg_fh = open(avg_file, 'w')

    log_avg_file = os.path.join(out_dir, 'matrix_log_avg.txt')
    log_avg_fh = open(log_avg_file, 'w')

    raw_fh.write('\t'.join([''] + all_samples) + '\n')
    avg_fh.write('\t'.join([''] + all_samples) + '\n')
    log_avg_fh.write('\t'.join([''] + all_samples) + '\n')

    for sample1 in all_samples:
        raw = [sample1]
        avgs = [sample1]
        log_avg = [sample1]

        for sample2 in all_samples:
            n1 = counts[sample1].get(sample2, 0)
            n2 = counts[sample2].get(sample1, 0)
            avg = (n1 + n2) / 2

            raw.append(str(n1))
            avgs.append('{:.0f}'.format(avg))
            log_avg.append('{:.4f}'.format(log(avg)) if avg > 0 else '0')

        raw_fh.write('\t'.join(raw) + '\n')
        avg_fh.write('\t'.join(avgs) + '\n')
        log_avg_fh.write('\t'.join(log_avg) + '\n')

    raw_fh.close()
    avg_fh.close()
    log_avg_fh.close()
    
    dat = pd.read_csv(avg_file, sep="\t", index_col=0)
    dist = pd.DataFrame(squareform(pdist(dat.values, distance_method)),
                        index=dat.index,
                        columns=dat.index)

    norm_file = os.path.join(out_dir, 'matrix_normalized.txt')
    dist.to_csv(norm_file, sep='\t')

    print('Done, see files in dir "{}"'.format(out_dir))

# --------------------------------------------------
if __name__ == '__main__':
    main()
