ISOroot	:= build/iso
EFI	:= build/BOOTX64.EFI
IMG	:= build/iso/UP.img
ISO	:= build/UP.iso

.PHONY: all run clean

all: $(ISO)
	qemu-system-x86_64 -bios firmware/OVMF.fd -cdrom $(ISO)

$(EFI): src/loader/bootloader.asm
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
	qemu-system-x86_64 -bios firmware/OVMF.fd -cdrom $(ISO)

clean:
	rm -rf build