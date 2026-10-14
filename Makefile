ISOroot	:= build/iso
EFI	:= build/BOOTX64.EFI
IMG	:= build/iso/UP.img
ISO	:= build/UP.iso
KERNEL_ELF := build/kernel.elf
KERNEL_BIN := build/kernel.bin

.PHONY: all run clean

all: $(ISO)
	qemu-system-x86_64 -bios firmware/OVMF.fd -cdrom $(ISO) -debugcon stdio -global isa-debugcon.iobase=0xE9

build/kernel.o: src/kernel/kernel.asm
	mkdir -p build
	nasm -f elf64 $< -o $@

$(KERNEL_ELF): build/kernel.o src/kernel/linker.ld
	ld -T src/kernel/linker.ld $< -o $@

$(KERNEL_BIN): $(KERNEL_ELF)
	objcopy -O binary $< $@

$(EFI): src/loader/bootloader.asm $(KERNEL_BIN)
	mkdir -p $(ISOroot)
	nasm -f bin $< -o $@

$(IMG): $(EFI)
	dd if=/dev/zero of=$@ bs=1M count=64
	mkfs.fat -F 32 $@
	mmd -i $@ ::/EFI
	mmd -i $@ ::/EFI/BOOT
	mcopy -i $@ $< ::/EFI/BOOT/

$(ISO): $(IMG)
	xorriso -as mkisofs -e UP.img -no-emul-boot -o $@ $(ISOroot)

run:
	qemu-system-x86_64 -s -S -bios firmware/OVMF.fd -cdrom $(ISO)

gdb: 
	gdb -ex "target remote localhost:1234" -ex "shell clear"

clean:
	rm -rf build