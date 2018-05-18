#!/usr/bin/env python3
"""Subset sequence files"""

# Author: Ken Youens-Clark <kyclark@email.arizona.edu>

import argparse
from random import random
import os
import sys
from Bio import SeqIO

# --------------------------------------------------
def get_args():
    """get args"""
    parser = argparse.ArgumentParser(
        description='Split FASTA files',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('file', help='FASTQ/A input file', metavar='FILE')

    parser.add_argument('-n', '--num', help='Number of records per file',
                        type=int, metavar='NUM', default=500000)

    parser.add_argument('-m', '--min', help='Min. number, delete if below',
                        type=int, metavar='NUM', default=0)

    parser.add_argument('-o', '--out_dir', help='Output directory',
                        type=str, metavar='DIR', default='subset')

    parser.add_argument('-i', '--input_format', help='Input file format',
                        type=str, metavar='FMT', default='fasta')

    parser.add_argument('-t', '--output_format', help='Output file format',
                        type=str, metavar='FMT', default='fasta')

    return parser.parse_args()

# --------------------------------------------------
def main():
    """main"""
    args = get_args()
    infile = args.file
    out_dir = args.out_dir
    num_seqs = args.num
    min_num = args.min
    input_format = args.input_format
    output_format = args.output_format

    if not os.path.isfile(infile):
        print('Input file "{}" is not valid'.format(infile))
        sys.exit(1)

    if os.path.dirname(infile) == out_dir:
        print('--outdir cannot be the same as input files')
        sys.exit(1)

    if num_seqs < 1:
        print("--num cannot be less than one")
        sys.exit(1)

    if not os.path.isdir(out_dir):
        os.mkdir(out_dir)

    count_seqs = 0
    for record in SeqIO.parse(infile, input_format):
        count_seqs += 1

    if count_seqs == 0:
        print('Found no records in "{}"'.format(infile))
        sys.exit(1)

    out_file = os.path.join(out_dir, os.path.basename(infile))
    take_pct = round(num_seqs / count_seqs, 4) if count_seqs > num_seqs else 1
    num_taken = 0

    with open(out_file, 'wt') as out_fh:
        for record in SeqIO.parse(infile, input_format):
            if random() <= take_pct:
                SeqIO.write(record, out_fh, output_format)
                num_taken += 1

            if num_taken >= num_seqs:
                break

    if num_taken < min_num:
        print('Only took {}, so removing "{}"'.format(num_taken, out_file))
        os.remove(out_file)
    else:
        print('Done, wrote {} sequence{} to "{}"'.format(
            num_taken, '' if num_taken == 1 else 's', out_file))

# --------------------------------------------------
if __name__ == '__main__':
    main()
