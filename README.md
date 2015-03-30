# Fizkin

K-mer analysis.

* "scripts/workers" - driver/worker scripts
* "bin" - necessary compiled tools, e.g., "faSplit"

# To Run

* Edit "scripts/config.sh" 
* Run "script/0*.sh" in order
* Profit

# HPC

These scripts expect to run on PBS, but I am also working on versions to 
submit to SLURM.

# Perl

A couple of scripts use Perl, some CPAN modules, and this:

  https://github.com/hurwitzlab/perl-lib

On the HPC systems I use, I find it easiest to use "local::lib" to install
the Perl modules I need:

  http://search.cpan.org/dist/local-lib/

To see what needs to be installed (assuming you have cpanminus installed):

  $ perl Makefile.PL
  $ cpanm --install-deps .

# Authors

* Bonnie Hurwitz <bhurwitz@email.arizona.edu>
* Ken Youens-Clark <kyclark@email.arizona.edu>
