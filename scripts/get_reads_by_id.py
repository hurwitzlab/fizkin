#!/usr/bin/env python3
"""Extract reads from FASTA based on IDs in file"""

import argparse
import os
    
import sys
from Bio import SeqIO

# --------------------------------------------------
def get_args():
    """get args"""
    parser = argparse.ArgumentParser(
        description='Argparse Python script',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-r', '--reads', help='FASTA reads file',
                        metavar='FILE', type=str, required=True)

    parser.add_argument('-i', '--ids', help='IDs file',
                        metavar='FILE', type=str, required=True)

    parser.add_argument('-o', '--out', help='Output file',
                        metavar='DIR', type=str, required=True)

    return parser.parse_args()

# --------------------------------------------------
def main():
    """main"""
    args = get_args()
    reads_file = args.reads
    ids_file = args.ids
    out_file = args.out

    if not os.path.isfile(reads_file):
        print('--reads "{}" is not a file'.format(reads_file))
        sys.exit(1)

    if not os.path.isfile(ids_file):
        print('--ids "{}" is not a file'.format(ids_file))
        sys.exit(1)

    out_dir = os.path.dirname(os.path.abspath(out_file))
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    take_id = set()
    for line in open(ids_file):
        take_id.add(line.rstrip().split(' ')[0]) # remove anything after " "

    checked = 0
    took = 0
    with open(out_file, "wt") as out_fh:
        for record in SeqIO.parse(reads_file, "fasta"):
            checked += 1
            if record.id in take_id:
                SeqIO.write(record, out_fh, "fasta")
                took += 1

    print('Done, checked {} took {}, see {}'.format(checked, took, out_file))

# --------------------------------------------------
if __name__ == '__main__':
    main()
