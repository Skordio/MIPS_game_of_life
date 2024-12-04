# Define the assembler and the compiler
AS = mips-linux-gnu-as
CC = mips-linux-gnu-gcc

# Define the source file and the output executable
MAIN_SRC = main.asm
LIB_SRCS = $(wildcard lib/*.asm)

# Create list of object files
MAIN_OBJ = $(MAIN_SRC:.asm=.o)
LIB_OBJS = $(LIB_SRCS:.asm=.o)

# Define output executable
EXE = main.out

# Default target
all: $(EXE)

# Rule to create object file from assembly
%.o: %.asm
	$(AS) -o $@ $<

# Rule to link object file and create executable
$(EXE): $(MAIN_OBJ) $(LIB_OBJS)
	$(CC) -o $@ $^ -nostdlib -static

# Clean up
clean:
	rm -f $(MAIN_OBJ) $(LIB_OBJS) $(EXE)

run:
	make; qemu-mips $(EXE); make clean

.PHONY: all clean