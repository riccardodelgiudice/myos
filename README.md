# MyOS

MyOS is a small educational kernel for the **x86-64** architecture. It is written in C and booted with the [Limine](https://limine-bootloader.org/) bootloader inside QEMU.

The project explores the complete path from C source code to bare-metal execution: freestanding compilation, ELF linking, ISO creation, kernel loading, and direct framebuffer access.

## Current status

The kernel currently:

- is compiled as a freestanding x86-64 program;
- is linked as a higher-half ELF executable;
- requests a framebuffer through the Limine protocol;
- fills the entire screen with blue pixels;
- finishes by entering a loop that executes the `hlt` instruction.

This is not yet a complete operating system. Memory management, interrupts, drivers, processes, and a filesystem have not been implemented yet.

## Project structure

- `src/kernel.c` — kernel entry point and framebuffer handling.
- `linker.ld` — defines the layout of the ELF sections and segments.
- `iso/limine.conf` — tells Limine where to find the kernel.
- `Makefile` — downloads verified dependencies and builds the kernel and BIOS/UEFI bootable ISO.
- `build/` — generated build artifacts, excluded from Git.

## Requirements

- GNU Make;
- the `x86_64-elf-gcc` cross-compiler and binutils;
- a host C compiler;
- `curl` and `sha256sum`;
- `xorriso`;
- `qemu-system-x86_64`.

The build downloads pinned versions of the Limine binary release and protocol header, then verifies both files with SHA-256 before using them. Third-party binaries are not stored in this repository.

## Build and run

```bash
make
make run
```

If the boot process succeeds, QEMU displays a completely blue screen.

The Makefile automatically detects a cross-compiler installed in `~/opt/cross/bin`. A different location can be selected with `make TOOLCHAIN_PREFIX=/path/to/x86_64-elf-`.

Generated files can be removed with `make clean`. Use `make distclean` to also remove downloaded dependencies.

## Dependencies and licensing

MyOS is released under the [MIT License](LICENSE).

The build system downloads Limine from its official release archive and the Limine protocol header from its official repository. These third-party components remain subject to their respective upstream licenses and are not redistributed as part of this repository.
