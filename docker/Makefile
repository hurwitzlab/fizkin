build:
	docker build -t fizkin .

shell:
	docker run --rm -it fizkin /bin/bash

run:
	docker run --rm -v $(HOME)/data:/work fizkin -q /work/dolphin/fasta -o /work/dolphin/fizkin-out
