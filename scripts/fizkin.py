#!/usr/bin/env python3
"""docstring"""

# vim: set ft=python

import argparse
import glob
import os
import sys
import tempfile as tmp
import subprocess

# --------------------------------------------------
def get_args():
    """get args"""
    parser = argparse.ArgumentParser(
        description='Fizkin -- Pairwise sequence comparison with kmers',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-q', '--query',
                        help='Input files or directories',
                        nargs='+',
                        metavar='str',
                        type=str,
                        required=True)

    parser.add_argument('-o', '--outdir',
                        help='Output directory',
                        metavar='str',
                        type=str,
                        default=os.path.join(os.path.abspath(os.getcwd()),
                                             'fizkin-out'))

    parser.add_argument('-t', '--num_threads',
                        help='Number of threads',
                        metavar='int',
                        type=int,
                        default=12)

    parser.add_argument('-k', '--kmer_size',
                        help='Kmer size',
                        metavar='int',
                        type=int,
                        default=20)

    parser.add_argument('-x', '--max_seqs',
                        help='Max num of sequences per input file',
                        metavar='int',
                        type=int,
                        default=500000)

    parser.add_argument('-s', '--hash_size',
                        help='Jellyfish hash size',
                        metavar='str',
                        type=str,
                        default='100M')

#    parser.add_argument('-f', '--flag', help='A boolean flag',
#                        action='store_true')
    return parser.parse_args()

# --------------------------------------------------
def line_count(fname):
    """Count the number of lines in a file"""
    n = 0
    for _ in open(fname):
        n += 1

    return n

# --------------------------------------------------
def warn(msg):
    """Print a message to STDERR"""
    print(msg, file=sys.stderr)

# --------------------------------------------------
def die(msg='Something went wrong'):
    """Print a message to STDERR and exit with error"""
    warn('Error: {}'.format(msg))
    sys.exit(1)

# --------------------------------------------------
def run_job_file(jobfile, msg='Running job'):
    """Run a job file if there are jobs"""
    num_jobs = line_count(jobfile)
    warn('{} (# jobs = {})'.format(msg, num_jobs))

    if num_jobs > 0:
        subprocess.run('parallel < ' + jobfile, shell=True)

    os.remove(jobfile)

    return True

# --------------------------------------------------
def find_input_files(query):
    """Find input files from list of files/dirs"""
    files = []
    for qry in query:
        if os.path.isdir(qry):
            for filename in os.scandir(qry):
                if filename.is_file():
                    files.append(filename.path)
        elif os.path.isfile(qry):
            files.append(qry)
        else:
            warn('--query "{}" neither file nor directory'.format(qry))
    return files

# --------------------------------------------------
def jellyfish_count(files, out_dir, kmer_size, hash_size, num_threads):
    """Use Jellyfish to count kmers in files"""

    jf_dir = os.path.join(out_dir, 'jellyfish')
    if not os.path.isdir(jf_dir):
        os.makedirs(jf_dir)

    cmd_tmpl = 'jellyfish count -m {} -t {} -s {}'.format(kmer_size,
                                                          num_threads,
                                                          hash_size)

    jobfile = tmp.NamedTemporaryFile(delete=False, mode='wt')
    for file in files:
        jf_file = os.path.join(jf_dir, os.path.basename(file))
        if not os.path.isfile(jf_file):
            jobfile.write(cmd_tmpl + ' -o {} {}\n'.format(jf_file, file))

    jobfile.close()

    if not run_job_file(jobfile=jobfile.name, msg='Counting kmers'):
        die()

    return jf_dir

# --------------------------------------------------
def pairwise_compare(input_files, jf_dir, out_dir):
    """Compare all Jellyfish indexes to all the input files"""

    keep_dir = os.path.join(out_dir, 'reads_kept')
    reject_dir = os.path.join(out_dir, 'reads_rejected')

    for dirname in [keep_dir, reject_dir]:
        if not os.path.isdir(dirname):
            os.makedirs(dirname)

    jf_files = [file.path for file in os.scandir(jf_dir) if file.is_file()]

    if not jf_files:
        die('Found no Jellyfish indexes in "{}"'.format(jf_dir))

    jobfile = tmp.NamedTemporaryFile(delete=False, mode='wt')

    for jf_file in jf_files:
        index_name = os.path.basename(jf_file)
        keep = os.path.join(keep_dir, index_name)
        reject = os.path.join(reject_dir, index_name)

        for dirname in [keep, reject]:
            if not os.path.isdir(dirname):
                os.makedirs(dirname)

        tmpl = 'query_per_sequence 1 10 {} {} 1>{} 2>{}\n'
        for qry_file in input_files:
            qry_name = os.path.basename(qry_file)
            keep_file = os.path.join(keep, qry_name)
            reject_file = os.path.join(reject, qry_name)

            if not os.path.isfile(keep_file):
                jobfile.write(tmpl.format(jf_file,
                                          qry_file,
                                          keep_file,
                                          reject_file))

    jobfile.close()

    if not run_job_file(jobfile=jobfile.name, msg='Pairwise comparison'):
        die()

    return keep_dir

# --------------------------------------------------
def count_kept_reads(keep_dir, out_dir):
    """Count the kept reads"""

    jobfile = tmp.NamedTemporaryFile(delete=False, mode='wt')
    base_mode_dir = os.path.join(out_dir, 'mode')

    for index_dir in os.scandir(keep_dir):
        index_name = os.path.basename(index_dir)
        mode_dir = os.path.join(base_mode_dir, index_name)

        if not os.path.isdir(mode_dir):
            os.makedirs(mode_dir)

        for kept in os.scandir(index_dir):
            out_file = os.path.join(mode_dir, os.path.basename(kept))
            if not os.path.isfile(out_file):
                jobfile.write("grep -ce '^>' {} > {}\n".format(kept.path,
                                                               out_file))

    jobfile.close()

    if not run_job_file(jobfile=jobfile.name, msg='Counting taken seqs'):
        die()

    return base_mode_dir

# --------------------------------------------------
def get_input_file_counts(input_files, out_dir):
    """Count how many sequences were used in the input files"""
    counts_dir = os.path.join(out_dir, 'counts')
    if not os.path.isdir(counts_dir):
        os.makedirs(counts_dir)

    jobfile = tmp.NamedTemporaryFile(delete=False, mode='wt')
    for qry_file in input_files:
        out_file = os.path.join(counts_dir, os.path.basename(qry_file))
        if not os.path.isfile(out_file):
            jobfile.write("grep -ce '^>' {} > {}\n".format(qry_file,
                                                           out_file))
    jobfile.close()

    if not run_job_file(jobfile=jobfile.name, msg='Counting input seqs'):
        die()

    input_counts = {}
    for count_file in os.scandir(counts_dir):
        basename = os.path.basename(count_file)
        num_seqs = int(open(count_file.path).read().rstrip())
        if num_seqs < 1:
            die('Cannot have zero-count for input "{}"'.format(basename))
        input_counts[basename] = num_seqs

    return input_counts

# --------------------------------------------------
def matrix_from_mode(mode_dir):
    """Read all the files in "mode" dir and create count matrix"""

    mode_files = list(filter(os.path.isfile,
                             glob.iglob(mode_dir + '/**', recursive=True)))
    print('Creating matrices from {} mode files'.format(len(mode_files)))

    counts = {}
    for file in sorted(mode_files):
        index_name = os.path.basename(os.path.dirname(file))
        qry_name = os.path.basename(file)
        num = open(file).read().strip()
        if not index_name in counts:
            counts[index_name] = {}
        counts[index_name][qry_name] = int(num)

    return counts

# --------------------------------------------------
def make_matrix(input_files, mode_dir, out_dir):
    """Find all the mode files, create matrix output into "figures" dir"""
    figs_dir = os.path.join(out_dir, 'figures')
    if not os.path.isdir(figs_dir):
        os.makedirs(figs_dir)

    input_counts = get_input_file_counts(input_files, out_dir)
    counts = matrix_from_mode(mode_dir)

    all_keys = set(counts.keys())
    for key in all_keys:
        map(all_keys.add, counts[key].keys())

    all_samples = sorted(all_keys)

    raw_fh = open(os.path.join(figs_dir, 'matrix_raw.txt'), 'wt')
    norm_fh = open(os.path.join(figs_dir, 'matrix_norm.txt'), 'wt')
    norm_avg_fh = open(os.path.join(figs_dir, 'matrix_norm_avg.txt'), 'wt')

    hdr = '\t'.join([''] + all_samples) + '\n'
    raw_fh.write(hdr)
    norm_fh.write(hdr)
    norm_avg_fh.write(hdr)

    for qry_name in all_samples:
        raw = [qry_name]
        norm = [qry_name]
        norm_avg = [qry_name]

        for idx_name in all_samples:
            qry_to_idx = counts[idx_name].get(qry_name, 0)
            idx_to_qry = counts[qry_name].get(idx_name, 0)
            norm_idx_to_qry = idx_to_qry / input_counts[idx_name]
            norm_qry_to_idx = qry_to_idx / input_counts[qry_name]
            raw.append(str(qry_to_idx))
            norm.append('{:.6f}'.format(norm_qry_to_idx))
            norm_avg.append('{:.6f}'.format((norm_qry_to_idx + norm_idx_to_qry)/2))

        raw_fh.write('\t'.join(raw) + '\n')
        norm_fh.write('\t'.join(norm) + '\n')
        norm_avg_fh.write('\t'.join(norm_avg) + '\n')

    raw_fh.close()
    norm_fh.close()
    norm_avg_fh.close()

    return figs_dir

# --------------------------------------------------
def make_figures(figures_dir):
    """Run R program to generate figures"""
    matrix = os.path.join(figures_dir, 'matrix_norm_avg.txt')
    if not os.path.isfile(matrix):
        die('Failed to create "{}"'.format(matrix))

    curdir = os.path.dirname(os.path.realpath(__file__))

    warn('Making figures')
    subprocess.run('{}/make_figures.r -m {}'.format(curdir, matrix), shell=True)

    warn('Running GBME')
    subprocess.run('{}/sna.r -m {}'.format(curdir, matrix), shell=True)

    return True
# --------------------------------------------------
def subset_input(input_files, out_dir, max_seqs):
    """Subset the input files, if necessary"""
    subset_files = []
    if max_seqs > 0:
        warn('Subsetting input to {}'.format(max_seqs))
        subset_dir = os.path.join(out_dir, 'subset')

        if not os.path.isdir(subset_dir):
            os.makedirs(subset_dir)

        jobfile = tmp.NamedTemporaryFile(delete=False, mode='wt')
        tmpl = 'fa_subset.py -o {} -n {} {}\n'
        for input_file in input_files:
            out_file = os.path.join(subset_dir, os.path.basename(input_file))
            subset_files.append(out_file)
            if not os.path.isfile(out_file):
                jobfile.write(tmpl.format(out_file, max_seqs, input_file))

        if not run_job_file(jobfile.name, msg='Subsetting input files'):
            die()
    else:
        warn('No max_seqs, using input files as-is')
        subset_files = input_files

    return subset_files

# --------------------------------------------------
def main():
    """main"""
    args = get_args()
    out_dir = args.outdir

    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    input_files = find_input_files(args.query)

    num_files = len(input_files)
    warn('Found {} input file{}'.format(num_files,
                                        '' if num_files == 1 else 's'))

    if num_files == 0:
        die('No usable files from --query')

    subset_files = subset_input(input_files=input_files,
                                out_dir=out_dir,
                                max_seqs=args.max_seqs)


    jf_dir = jellyfish_count(files=subset_files,
                             out_dir=out_dir,
                             kmer_size=args.kmer_size,
                             hash_size=args.hash_size,
                             num_threads=args.num_threads)

    keep_dir = pairwise_compare(input_files=subset_files,
                                jf_dir=jf_dir,
                                out_dir=out_dir)

    mode_dir = count_kept_reads(keep_dir=keep_dir,
                                out_dir=out_dir)

    figures_dir = make_matrix(input_files=subset_files,
                              mode_dir=mode_dir,
                              out_dir=out_dir)

    make_figures(figures_dir=figures_dir)

    warn('Done, see output dir "{}"'.format(out_dir))

# --------------------------------------------------
if __name__ == '__main__':
    main()
