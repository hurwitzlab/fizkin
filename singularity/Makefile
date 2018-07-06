SINGULARITY = /usr/local/bin/singularity
IMG = fizkin-0.0.4.img
DEF = image.def
SIZE = 2048

run:
	sudo $(SINGULARITY) run $(IMG)

clean:
	rm -f $(IMG)

img: clean
	#sudo $(SINGULARITY) build $(IMG) $(DEF)
	sudo $(SINGULARITY) create --size $(SIZE) $(IMG)
	sudo $(SINGULARITY) bootstrap $(IMG) $(DEF)

shell:
	sudo $(SINGULARITY) shell --writable -B $(shell pwd):/home $(IMG)

myriam:
	sudo $(SINGULARITY) exec -B /data:/work -B $(HOME):/home1 $(IMG) fizkin.py \
	-q "/work/kyclark/myriam/filtered" -o "/home1/myriam-filtered"

pooled:
	sudo $(SINGULARITY) exec -B /data:/work -B $(HOME):/home1 $(IMG) fizkin.py \
	-q "/work/kyclark/myriam/pooled" -o "/work/kyclark/myriam/pooled-fizkin"

novirus:
	sudo $(SINGULARITY) exec -B /data:/work -B $(HOME):/home1 $(IMG) fizkin.py \
	-q "/work/kyclark/myriam/filtered-no-virus/fasta" \
	-o "/work/kyclark/myriam/filtered-no-virus/fizkin"
