ENTRY(kernel_main)

PHDRS
{
    requests PT_LOAD FLAGS(6);
    text     PT_LOAD FLAGS(5);
    data     PT_LOAD FLAGS(6);
}

SECTIONS
{
    . = 0xffffffff80000000;

    .limine_requests_start : {
        KEEP(*(.limine_requests_start))
    } :requests

    .limine_requests : {
        KEEP(*(.limine_requests))
    } :requests

    .limine_requests_end : {
        KEEP(*(.limine_requests_end))
    } :requests

    .text ALIGN(0x1000) : {
        *(.text .text.*)
    } :text

    .rodata ALIGN(0x1000) : {
        *(.rodata .rodata.*)
    } :text

    .data ALIGN(0x1000) : {
        *(.data .data.*)
	BYTE(0)
    } :data

    .bss ALIGN(0x1000) : {
        *(COMMON)
        *(.bss .bss.*)
    } :data

    /DISCARD/ : {
        *(.comment)
        *(.eh_frame*)
        *(.note*)
    }
}
