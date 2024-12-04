# Conway's Game of Life written in MIPS O32

This code is a project I was working on in CSCI 250 - Concepts of Computer Systems. It is a rendition of Conway's game of life written in MIPS32 assembly. The code was originally written to be executed in a MIPS Assembly simulator like SPIM or MARS, but in this repo I am adapting it to be emulated in qemu-mips running on Ubuntu in WSL.


## Compilation

### Requirements

To run code in this repo I am using WSL 2.0 Ubuntu with the gcc-mips-linux-gnu toolchain and the qemu emulator.

To compile code you need to intall the gcc-mips-linux-gnu toolchain:

```bash
sudo apt install gcc-mips-linux-gnu
```

To emulate mips you need to install qemu and qemu-user:

```bash
sudo apt install qemu qemu-user
```

### Compiling

To compile ASM code written in file.asm first you need to run the MIPS gnu assembler:

```bash
mips-linux-gnu-as file.asm -o file.o
```

then use gcc to compile it (and use a few arguments so that the binary doesn't do runtime linking and we don't get errors):

```bash
mips-linux-gnu-gcc file.o -nostdlib -static
```

this will create an a.out executable which can be run using qemu-mips:

```bash
qemu-mips ./a.out
```