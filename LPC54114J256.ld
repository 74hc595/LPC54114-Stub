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

  /* For buffers that must be placed in SRAM bank 1. */
  /* Allow .data/.noinit/.bss to overflow into SRAM1, but error if there */
  /* is not enough room for the symbols that must go into SRAM1. */
  .sram1 MAX(., ABSOLUTE(0x20010000)) (NOLOAD) : {
    *(.sram1*)
  } > RAM
  ASSERT(!(SIZEOF(.sram1) && ((ADDR(.sram1)+SIZEOF(.sram1)) > ABSOLUTE(0x20020000))), "Not enough room in SRAM1")

  /* For buffers that must be placed in SRAM bank 2. */
  /* Allow .data/.noinit/.bss to completely overflow SRAM1 and into SRAM2, */
  /* but error if there is not enough room for the symbols that must go into SRAM2. */
  .sram2 MAX(., ABSOLUTE(0x20020000)) (NOLOAD) : {
    *(.sram2*)
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