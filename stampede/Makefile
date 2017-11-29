APP = fizkin-0.0.1
EMAIL = kyclark@email.arizona.edu

clean:
	find . \( -name \*.out -o -name \*.param \) -exec rm {} \;

up: 
	copy_from_manifest.py

template:
	jobs-template $(APP) > job.json

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

pov:
	sbatch ./run.sh -q $(WORK)/data/pov/fasta -o $(WORK)/data/pov/fizkin-out -m $(WORK)/data/pov/meta.tab
