IMAGE := kernel.elf

CROSS_COMPILE = aarch64-linux-gnu-

CC = clang -target aarch64-linux-gnu
LD = ld.lld 
OBJDUMP = llvm-objdump --arch-name=aarch64

CFLAGS = -Wall -fno-common -O0 -g \
         -nostdlib -nostartfiles -ffreestanding \
         -march=armv8-a

OBJS = hello.o

all: $(IMAGE)

boot.o: boot.S
	$(CC) boot.S -c -o boot.o

$(IMAGE): kernel.ld boot.o $(OBJS)
	$(LD) boot.o $(OBJS) -T kernel.ld -o $(IMAGE)
	$(OBJDUMP) -d kernel.elf > kernel.list
	$(OBJDUMP) -t kernel.elf | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

qemu: $(IMAGE)
	@qemu-system-aarch64 -M ? | grep virt >/dev/null || exit
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo
	qemu-system-aarch64 -machine virt -cpu cortex-a57 \
	                    -smp 4 -m 4096 \
			    -nographic -serial mon:stdio \
	                    -kernel $(IMAGE)

clean:
	rm -f $(IMAGE) *.o *.list *.sym

.PHONY: all qemu clean
