MEMORY
{
  FLASH  (rx) : ORIGIN = 0x00000000, LENGTH = 256K
  RAMX  (rwx) : ORIGIN = 0x04000000, LENGTH = 32K
  RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 160K
}

SECTIONS
{
  .text : {
    . = 0;
    KEEP (*(.vectors))
    . = ALIGN(4);
    *(.text*)
    *(.rodata*)
    . = ALIGN(4);
    KEEP (*(.init))
    . = ALIGN(4);
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    __init_array_start = .;
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    __init_array_end = .;
  } > FLASH

  .ARM.exidx : {
    __exidx_start = .;
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    __exidx_end = .;
  } > FLASH
  __etext = .;

/* Contiguous banks SRAM0, SRAM1, SRAM2 */
  .data : AT(__etext) {
    . = ALIGN(4);
    __data_start__ = .;
    *(.ramfunc*)
    *(.data*)
    . = ALIGN(4);
    __data_end__ = .;
  } > RAM
  __edata = LOADADDR(.data)+SIZEOF(.data);

  .noinit (NOLOAD) : {
    *(.noinit*)
  } > RAM

  .bss : {
    . = ALIGN(4);
    __bss_start__ = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
  } > RAM

/* SRAMX is discontiguous with the rest of SRAM */
  .xdata : AT(LOADADDR(.data)+SIZEOF(.data)) {
    . = ALIGN(4);
    __xdata_start__ = .;
    *(.xramfunc*)
    *(.xdata*)
    . = ALIGN(4);
    __xdata_end__ = .;
  } > RAMX

  .xnoinit (NOLOAD) : {
    *(.xnoinit*)
  } > RAMX

  .xbss : {
    . = ALIGN(4);
    __xbss_start__ = .;
    *(.xbss*)
    . = ALIGN(4);
    __xbss_end__ = .;
  } > RAMX

  __estack = ORIGIN(RAM) + LENGTH(RAM);
}