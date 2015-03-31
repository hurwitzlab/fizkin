use inc::Module::Install;

name           'Fizkin';
abstract       'kmer analysis';
author         'Ken Youens-Clark <kyclark@email.arizona.edu>';
version        '0.01';
license        'GPL';

requires 'common::sense';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::CountLines';
requires 'Hurwitz::Utils';
requires 'List::MoreUtils';
requires 'Pod::Usage';
requires 'Readonly';
requires 'Statistics::Descriptive::Discrete';

WriteAll;
