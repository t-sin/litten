PROGRAM=litten

.PHONY: all
all: $(PROGRAM)

$(PROGRAM): litten.s
	gcc -no-pie -masm=intel $^ -o $(PROGRAM)

.PHONY: clean
clean:
	rm -f $(PROGRAM)
