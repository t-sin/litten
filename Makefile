PROGRAM = litten
ASM = litten.o syscall.o

ASFLAGS = -msyntax=intel

.PHONY: all
all: $(PROGRAM)

.PHONY: debug
debug: ASFLAGS+=-g
debug: clean all

.s.o:
	as $(ASFLAGS) $^ -o $@

$(PROGRAM): $(ASM)
	ld $(LDFLAGS) $^ -o $(PROGRAM)

.PHONY: clean
clean:
	rm -f *.o
	rm -f $(PROGRAM)
