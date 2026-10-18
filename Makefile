.SUFFIXES:
.DELETE_ON_ERROR:

CROSS_BIN ?= $(HOME)/opt/cross/bin
TOOLCHAIN_PREFIX ?= $(if $(wildcard $(CROSS_BIN)/x86_64-elf-gcc),$(CROSS_BIN)/x86_64-elf-,x86_64-elf-)
CC := $(TOOLCHAIN_PREFIX)gcc
LD := $(TOOLCHAIN_PREFIX)ld

BUILD_DIR := build
DOWNLOAD_DIR := $(BUILD_DIR)/downloads
DEPS_DIR := $(BUILD_DIR)/deps
ISO_ROOT := $(BUILD_DIR)/iso_root

KERNEL_OBJECT := $(BUILD_DIR)/kernel.o
KERNEL_ELF := $(BUILD_DIR)/kernel.elf
ISO_IMAGE := $(BUILD_DIR)/myos.iso

LIMINE_VERSION := 12.9.3
LIMINE_ARCHIVE := $(DOWNLOAD_DIR)/limine-binary-$(LIMINE_VERSION).tar.gz
LIMINE_URL := https://github.com/Limine-Bootloader/Limine/releases/download/v$(LIMINE_VERSION)/limine-binary.tar.gz
LIMINE_SHA256 := 9f42fe9ea2e84d71056529969b1d5c24ba9a2287ffcc01bcce58b0ef8aa98b1d
LIMINE_DIR := $(DEPS_DIR)/limine-binary
LIMINE_TOOL := $(LIMINE_DIR)/limine

PROTOCOL_COMMIT := 3a0526b700e356f0eac1b71a77697b3fd1c707a3
PROTOCOL_HEADER := $(DEPS_DIR)/limine-protocol/limine.h
PROTOCOL_URL := https://raw.githubusercontent.com/Limine-Bootloader/limine-protocol/$(PROTOCOL_COMMIT)/include/limine.h
PROTOCOL_SHA256 := 0aadf2633c85d8cb145344c968add158aeb1deb68af567d55ba8431c492b6d4c

CFLAGS := \
	-std=gnu11 \
	-Wall \
	-Wextra \
	-ffreestanding \
	-fno-stack-protector \
	-fno-pic \
	-fno-pie \
	-mno-red-zone \
	-fno-asynchronous-unwind-tables \
	-fno-unwind-tables

.PHONY: all run clean distclean

all: $(ISO_IMAGE)

$(PROTOCOL_HEADER):
	mkdir -p "$(dir $@)"
	curl -fL "$(PROTOCOL_URL)" -o "$@.tmp"
	printf '%s  %s\n' "$(PROTOCOL_SHA256)" "$@.tmp" | sha256sum -c -
	mv "$@.tmp" "$@"

$(LIMINE_ARCHIVE):
	mkdir -p "$(dir $@)"
	curl -fL "$(LIMINE_URL)" -o "$@"
	printf '%s  %s\n' "$(LIMINE_SHA256)" "$@" | sha256sum -c -

$(LIMINE_DIR)/limine.c: $(LIMINE_ARCHIVE)
	rm -rf "$(LIMINE_DIR)"
	mkdir -p "$(DEPS_DIR)"
	tar -xzf "$<" -C "$(DEPS_DIR)"
	touch "$@"

$(LIMINE_TOOL): $(LIMINE_DIR)/limine.c
	$(MAKE) -C "$(LIMINE_DIR)"

$(KERNEL_OBJECT): src/kernel.c $(PROTOCOL_HEADER)
	mkdir -p "$(BUILD_DIR)"
	$(CC) $(CFLAGS) -I"$(dir $(PROTOCOL_HEADER))" -c "$<" -o "$@"

$(KERNEL_ELF): $(KERNEL_OBJECT) linker.ld
	$(LD) -T linker.ld -o "$@" "$(KERNEL_OBJECT)"

$(ISO_IMAGE): $(KERNEL_ELF) $(LIMINE_TOOL) iso/limine.conf
	rm -rf "$(ISO_ROOT)"
	mkdir -p "$(ISO_ROOT)/boot/limine" "$(ISO_ROOT)/EFI/BOOT"
	cp "$(KERNEL_ELF)" "$(ISO_ROOT)/boot/kernel.elf"
	cp iso/limine.conf "$(ISO_ROOT)/boot/limine/limine.conf"
	cp "$(LIMINE_DIR)/limine-bios-cd.bin" "$(ISO_ROOT)/boot/limine/limine-bios-cd.bin"
	cp "$(LIMINE_DIR)/limine-bios.sys" "$(ISO_ROOT)/boot/limine/limine-bios.sys"
	cp "$(LIMINE_DIR)/limine-uefi-cd.bin" "$(ISO_ROOT)/boot/limine/limine-uefi-cd.bin"
	cp "$(LIMINE_DIR)/BOOTX64.EFI" "$(ISO_ROOT)/EFI/BOOT/BOOTX64.EFI"
	cp "$(LIMINE_DIR)/BOOTIA32.EFI" "$(ISO_ROOT)/EFI/BOOT/BOOTIA32.EFI"
	xorriso -as mkisofs \
		-R -r -J \
		-b boot/limine/limine-bios-cd.bin \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		-hfsplus \
		-apm-block-size 2048 \
		--efi-boot boot/limine/limine-uefi-cd.bin \
		-efi-boot-part \
		--efi-boot-image \
		--protective-msdos-label \
		"$(ISO_ROOT)" \
		-o "$@"
	"$(LIMINE_TOOL)" bios-install "$@"
	rm -rf "$(ISO_ROOT)"

run: $(ISO_IMAGE)
	qemu-system-x86_64 -m 256M -cdrom "$(ISO_IMAGE)"

clean:
	rm -f "$(KERNEL_OBJECT)" "$(KERNEL_ELF)" "$(ISO_IMAGE)"
	rm -rf "$(ISO_ROOT)"

distclean:
	rm -rf "$(BUILD_DIR)"
