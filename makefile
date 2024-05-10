name=main
lib=lib
macro=macros
# Program to use as the assembler (you could use NASM or YASM for this makefile)
ASM=nasm
# Flags for the assembler
ASM_F=-f elf64 # for x86-64 architecture use ASM_F=-f elf64 besides ASM_F=-f elf

# Program to use as linker
LINKER=ld

# Link executable
$(name): $(name).o $(lib).o
	$(LINKER) -o $(name) $(name).o $(lib).o

# Assemble source code for library
$(lib).o: $(lib).asm
	$(ASM) $(ASM_F) -o $(lib).o $(lib).asm
	
# Assemble source code for main program
$(name).o: $(name).asm
	$(ASM) $(ASM_F) -o $(name).o $(name).asm


# Clean up intermediate files
clean:
	rm -f *.o $(name)
