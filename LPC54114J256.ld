MEMORY
{
  FLASH  (rx) : ORIGIN = 0x00000000, LENGTH = 256K
  SRAMX (rwx) : ORIGIN = 0x04000000, LENGTH = 32K
  SRAM  (rwx) : ORIGIN = 0x20000000, LENGTH = 160K
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

    /* Sections for chunks of code that are stored in flash but dynamically */
    /* loaded into RAM. (Add/remove/rename if desired) */
    . = ALIGN(4);
    __dyncode0_start__ = .;
    KEEP (*(.dyncode0*))
    . = ALIGN(4);
    __dyncode0_size__ = . - __dyncode0_start__;
    __dyncode1_start__ = .;
    KEEP (*(.dyncode1*))
    . = ALIGN(4);
    __dyncode1_size__ = . - __dyncode1_start__;
    __dyncode2_start__ = .;
    KEEP (*(.dyncode2*))
    . = ALIGN(4);
    __dyncode2_size__ = . - __dyncode2_start__;
    __dyncode3_start__ = .;
    KEEP (*(.dyncode3*))
    . = ALIGN(4);
    __dyncode3_size__ = . - __dyncode3_start__;
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
  } > SRAM

  .noinit (NOLOAD) : {
    *(.noinit*)
  } > SRAM

  .bss (NOLOAD) : {
    . = ALIGN(4);
    __bss_start__ = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
  } > SRAM
  __edata = LOADADDR(.data)+SIZEOF(.data);

  /* For buffers that must be placed in SRAM bank 1. */
  /* Allow .data/.noinit/.bss to overflow into SRAM1, but error if there */
  /* is not enough room for the symbols that must go into SRAM1. */
  .sram1.data MAX(., ABSOLUTE(0x20010000)) : AT(__edata) {
    . = ALIGN(4);
    __sram1_data_start__ = .;
    *(.sram1.ramfunc*)
    *(.sram1.data*)
    . = ALIGN(4);
    __sram1_data_end__ = .;
    . = ALIGN(4);
  } > SRAM
  __edata1 = LOADADDR(.sram1.data)+SIZEOF(.sram1.data);

  .sram1.noinit (NOLOAD) : {
    *(.sram1.noinit*)
  } > SRAM

  .sram1.bss (NOLOAD) : {
    . = ALIGN(4);
    __sram1_bss_start__ = .;
    *(.sram1.bss*)
    . = ALIGN(4);
    __sram1_bss_end__ = .;
  } > SRAM

  SRAM1_SIZE = SIZEOF(.sram1.data)+SIZEOF(.sram1.noinit)+SIZEOF(.sram1.bss);
/*  ASSERT(!SRAM1_SIZE && (ADDR(.sram1.data)+SRAM1_SIZE > ABSOLUTE(0x20020000)), "Not enough room in SRAM1") */

  /* For buffers that must be placed in SRAM bank 2. */
  /* Allow .data/.noinit/.bss to completely overflow SRAM1 and into SRAM2, */
  /* but error if there is not enough room for the symbols that must go into SRAM2. */
  .sram2.data MAX(., ABSOLUTE(0x20020000)) : AT(__edata1) {
    . = ALIGN(4);
    __sram2_data_start__ = .;
    *(.sram2.ramfunc*)
    *(.sram2.data*)
    . = ALIGN(4);
    __sram2_data_end__ = .;
  } > SRAM
  __edata2 = LOADADDR(.sram2.data)+SIZEOF(.sram2.data);

  .sram2.noinit (NOLOAD) : {
    *(.sram2.noinit*)
  } > SRAM

  .sram2.bss (NOLOAD) : {
    . = ALIGN(4);
    __sram2_bss_start__ = .;
    *(.sram2.bss*)
    . = ALIGN(4);
    __sram2_bss_end__ = .;
  } > SRAM


  /* SRAMX is discontiguous with the rest of SRAM */
  .sramx.data : AT(__edata2) {
    . = ALIGN(4);
    __sramx_data_start__ = .;
    *(.sramx.ramfunc*)
    *(.sramx.data*)
    . = ALIGN(4);
    __sramx_data_end__ = .;
    . = ALIGN(4);
  } > SRAMX

  .sramx.noinit (NOLOAD) : {
    *(.sramx.noinit*)
  } > SRAMX

  .sramx.bss (NOLOAD) : {
    . = ALIGN(4);
    __sramx_bss_start__ = .;
    *(.sramx.bss*)
    . = ALIGN(4);
    __sramx_bss_end__ = .;
  } > SRAMX

  /* M4 stack defaults to the end of the contiguous SRAM region (i.e. end of SRAM2) */
  /* unless specified otherwise. */
  __estack = DEFINED(M4_STACK_IN_SRAM0) ? ABSOLUTE(0x20010000) : (
             DEFINED(M4_STACK_IN_SRAM1) ? ABSOLUTE(0x20020000) : (
             DEFINED(M4_STACK_IN_SRAMX) ? ABSOLUTE(0x04008000) : ABSOLUTE(0x20028000)));
}