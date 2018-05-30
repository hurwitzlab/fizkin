#!/usr/bin/env python3
"""docstring"""

import argparse
import os
import sys
import tempfile as tmp
import subprocess

# --------------------------------------------------
def get_args():
    """get args"""
    parser = argparse.ArgumentParser(
        description='Argparse Python script',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-q', '--query', help='Input files or directories',
                        nargs='+', metavar='str', type=str, required=True)

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
            print('--query "{}" neither file nor directory'.format(qry),
                  file=sys.stderr)
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
    num_jobs = line_count(jobfile.name)

    if num_jobs > 0:
        print('Counting files (jobs = {})'.format(num_jobs), file=sys.stderr)
        subprocess.run('parallel < ' + jobfile.name, shell=True)
    else:
        print('No counting to be done')

    os.remove(jobfile.name)

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
        print('Found no Jellyfish indexes in "{}"'.format(jf_dir))
        sys.exit(1)

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

    num_jobs = line_count(jobfile.name)
    if num_jobs > 0:
        print('Pairwise comp (jobs = {})'.format(num_jobs), file=sys.stderr)
        subprocess.run('parallel < ' + jobfile.name, shell=True)
    else:
        print('No comp jobs to run')

    os.remove(jobfile.name)

    return keep_dir

# --------------------------------------------------
def count_kept_reads(keep_dir, out_dir):
    """Count the kept reads"""

    jobfile = tmp.NamedTemporaryFile(delete=False, mode='wt')

    for index_dir in os.scandir(keep_dir):
        index_name = os.path.basename(index_dir)
        mode_dir = os.path.join(out_dir, 'mode', index_name)

        if not os.path.isdir(mode_dir):
            os.makedirs(mode_dir)

        for kept in os.scandir(index_dir):
            out_file = os.path.join(mode_dir, os.path.basename(kept))
            if not os.path.isfile(out_file):
                jobfile.write("grep -ce '^>' {} > {}\n".format(kept.path, 
                                                               out_file))

    jobfile.close()

    num_jobs = line_count(jobfile.name)
    if num_jobs > 0:
        print('Finding modes (jobs = {})'.format(num_jobs), file=sys.stderr)
        subprocess.run('parallel < ' + jobfile.name, shell=True)
    else:
        print('No mode jobs to run')

    os.remove(jobfile.name)


# --------------------------------------------------
def main():
    """main"""
    args = get_args()
    out_dir = args.outdir

    print('outdir "{}"'.format(out_dir))
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    input_files = find_input_files(args.query)

    num_files = len(input_files)
    print('Found {} file{}'.format(num_files, '' if num_files == 1 else 's'))

    if num_files == 0:
        print('No usable files from --query')
        sys.exit(1)

    jf_dir = jellyfish_count(files=input_files,
                             out_dir=out_dir,
                             kmer_size=args.kmer_size,
                             hash_size=args.hash_size,
                             num_threads=args.num_threads)

    keep_dir = pairwise_compare(input_files=input_files,
                                jf_dir=jf_dir,
                                out_dir=out_dir)

    count_kept_reads(keep_dir=keep_dir, out_dir=out_dir)

    print('Done.')

# --------------------------------------------------
if __name__ == '__main__':
    main()
