# Master Makefile dependencies
TARGET := sobel
INCLUDE_LIB := false

prog: lena.img.bin sobel.elf

%.img.bin:
	python read_img.py $*.jpg

include ../Makefile.gcc.in
