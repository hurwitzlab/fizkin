APP = fizkin-0.0.2
EMAIL = kyclark@email.arizona.edu

clean:
	find . \( -name \*.out -o -name \*.param \) -exec rm {} \;

up: 
	copy_from_manifest.py

template:
	jobs-template -A $(APP) > job.json

job:
	jobs-submit -F job.json

rmbin:
	rm -rf bin

scriptsgz:
	(cd scripts && tar cvf ../scripts.tgz *)

app:
	apps-addupdate -F app.json

test: clean
	sbatch test.sh

pov0:
	sbatch -J pov0 ./run.sh -x 0 -q $(WORK)/data/pov/fasta -o $(WORK)/data/pov/fizkin-out-0 -m $(WORK)/data/pov/meta.tab

pov100:
	sbatch -J pov100 ./run.sh -x 100000 -q $(WORK)/data/pov/fasta -o $(WORK)/data/pov/fizkin-out-100 -m $(WORK)/data/pov/meta.tab

pov250:
	sbatch -J pov250 ./run.sh -x 250000 -q $(WORK)/data/pov/fasta -o $(WORK)/data/pov/fizkin-out-250 -m $(WORK)/data/pov/meta.tab

pov500:
	sbatch -J pov500 ./run.sh -x 500000 -q $(WORK)/data/pov/fasta -o $(WORK)/data/pov/fizkin-out-500 -m $(WORK)/data/pov/meta.tab

ecoli_flex:
	sbatch -J ecflex ./run.sh -x 300000 -q $(WORK)/data/bugs/ecoli_flex/fasta -o $(WORK)/data/bugs/ecoli_flex/fizkin-out-300

ecoli_sap:
	sbatch -J ecsap ./run.sh -x 300000 -q $(WORK)/data/bugs/ecoli_sap/fasta -o $(WORK)/data/bugs/ecoli_sap/fizkin-out-300

mssa_mrsa:
	sbatch -J mssamrsa ./run.sh -x 300000 -q $(WORK)/data/bugs/mssa_mrsa/fasta -o $(WORK)/data/bugs/mssa_mrsa/fizkin-out-300

sap_pyo:
	sbatch -J sap_pyo ./run.sh -x 300000 -q $(WORK)/data/bugs/sap_pyo/fasta -o $(WORK)/data/bugs/sap_pyo/fizkin-out-300

myriam:
	sbatch -J myriam ./run.sh -r -q $(WORK)/myriam/lake_a/corrected -o $(WORK)/myriam/lake_a/fizkin #-m $(SCRATCH)/myriam/DiversityLakeA/samplesmetadata.tab 

mock250:
	sbatch -J fizmck ./run.sh -q $(WORK)/data/mock_communities/test -o $(WORK)/data/mock_communities/fizkin-250 -x 250000

mock500:
	sbatch -J fizmck ./run.sh -q $(WORK)/data/mock_communities/test -o $(WORK)/data/mock_communities/fizkin-500 -x 500000

mock1M:
	sbatch -J fizmck ./run.sh -q $(WORK)/data/mock_communities/test -o $(WORK)/data/mock_communities/fizkin-1M -x 1000000

icu:
	sbatch -J fizicu ./run.sh -q $(SCRATCH)/icu/fasta -o $(SCRATCH)/icu/fizkin

grice:
	sbatch -J grice ./run.sh -q $(SCRATCH)/grice-skin/fasta -o $(SCRATCH)/grice-skin/fizkin
