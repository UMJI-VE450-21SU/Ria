CPPC = g++

FESVER450_SAMPLE_SRC = fesvr450.cc
FESVER450_SAMPLE_OBJ = fesvr450.o

include fesvr450.mk.in

all: $(fesvr450_obj) $(TB_TARGET_OBJ)

fesvr450 : $(fesvr450_obj) $(FESVER450_SAMPLE_OBJ)
	$(CPPC) -o $@ $^

%.o: %.c %.h
	$(CPPC) -c -o $@ $<

.PHONY: clean

clean:
	rm -rf *.o fesvr450
