PROGRAM = litten
ASM = builtin-words.s

CFLAGS = -no-pie -masm=intel

.PHONY: all
all: $(PROGRAM)

.PHONY: debug
debug: CFLAGS+=-g -O0
debug: clean all

$(PROGRAM): $(ASM)
	gcc $(CFLAGS) $(PROGRAM).s -o $(PROGRAM)

.PHONY: clean
clean:
	rm -f $(PROGRAM)
