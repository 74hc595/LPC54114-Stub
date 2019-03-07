LPC54114 Dual-Core Example Project for GCC
==========================================

NXP's LPC54114 is a dual-core ARM microcontroller. In addition to the primary
Cortex-M4F core, it also includes a Cortex-M0+ coprocessor core.

This is a minimal example project that does not require any vendor executable
code (just header files) and does not require a vendor IDE. It can be built from
the command line using Make and you're free to use whatever editor you like.


Runtime behavior
----------------

The M4 core rapidly toggles GPIO pin `PIO1_10`, and the M0+
simultaneously rapidly toggles pin `PIO1_9`. On the LPCXpresso54114 evaluation
board, these pins are connected to the green and blue channels (respectively)
of an RGB LED. When working properly, the RGB LED should appear cyan, and square
waves should be visible by putting an oscillope on pins 8 and 5 of connector J9.

Unlike the dual-core example programs provided by NXP, which take up tens of
kilobytes of flash and require numerous libraries, this example project uses
only a few hundred bytes.


Caveats
-------

I'd like to reiterate that this is a **minimal** project:

- The default clock settings (12 MHz internal oscillator) are used. The PLL is
  not configured.
- The only peripherals configured are SRAM, IOCON, and GPIO.
- SysTick timer is not configured.
- No interrupts are configured.


Included is a Makefile for GCC. It includes rules for flashing and debugging
using either an LPC-Link2 probe (included onboard the LPCXpresso54114) or a
J-Link.

NXP's MCUXpresso/LPCXpresso software does **not** have to be installed if using
a J-Link. It _is_ required if using LPC-Link2, as it contains the necessary
command-line utilities for communicating with the debug probe.


Building and Running
--------------------

1. In the Makefile, make sure the `PROGRAMMER` variable is set to your choice of
   `lpc-link2` or `j-link`.

2. If using `lpc-link2`, make sure the `LPCXPRESSO_DIR` variable is set to the
   directory where you have insalled LPCXpresso.

3. Run `make`. This produces executable images `lpc54114-stub.elf` and
   `lpc54114-stub.hex`.

4. Run `make flash` to upload the code to the microcontroller.


Debugging
---------

The Makefile includes rules for debugging the M4 and M0+ cores simultaneously.
Each core needs its own instance of GDB and the approproate GDB server.

### To debug the M4 core:

1. If using a J-Link, run `make debugserver` in a separate terminal window.
   (Not necessary for LPC-Link2.)

2. Run `make debug` to start GDB.


### To debug the M0+ core:

1. If using a J-Link, run `make debugserver_m0` in a separate terminal window.
   (Not necessary for LPC-Link2.)

2. Run `make debug_m0` to start GDB.


Controlling placement of data and code
--------------------------------------

The LPC54114 has four banks of SRAM: SRAM0 (64 KB), SRAM1 (64 KB), SRAM2 (32 KB)
and SRAMX (32KB):

```
SRAM0: [0x20000000,0x2000FFFF] (64KB)
SRAM1: [0x20010000,0x2001FFFF] (64KB)
SRAM2: [0x20020000,0x20027FFF] (32KB)
SRAMX: [0x04000000,0x04007FFF] (32KB)
```

Banks SRAM0, SRAM1, and SRAM2 are on separate AHB matrix ports. This allows
memory to be divided between bus masters (M4, M0+, DMA, etc.) to prevent bus
stalls and improve performance. In this case, it's useful to specify the bank in
which a variable or buffer is located.

By default, data (`.data`, `.ramfunc`, `.bss`, and `.noinit` sections) is placed
in SRAM0. If more than 64KB of data is specified, these sections will overflow
into SRAM1 and SRAM2 as needed. This allows creation of contiguous arrays larger
than 64KB.

If data needs to go into a specific RAM bank, use `__attribute__((section(...)))`
to place it in the appropriate section:

```
Section name   | Destination range       | Contents     | Startup behavior
---------------+-------------------------+--------------+-----------------
.data          | [0x20000000,0x20027FFF] | Data or code | Initialized
.ramfunc       | [0x20000000,0x20027FFF] | Data or code | Initialized
.bss           | [0x20000000,0x20027FFF] | Data         | Zeroed
.noinit        | [0x20000000,0x20027FFF] | Data         | None
               |                         |              | 
.sram1.data    | [0x20010000,0x2001FFFF] | Data or code | Initialized
.sram1.ramfunc | [0x20010000,0x2001FFFF] | Data or code | Initialized
.sram1.bss     | [0x20010000,0x2001FFFF] | Data         | Zeroed
.sram1.noinit  | [0x20010000,0x2001FFFF] | Data         | None
               |                         |              |
.sram2.data    | [0x20020000,0x20027FFF] | Data or code | Initialized
.sram2.ramfunc | [0x20020000,0x20027FFF] | Data or code | Initialized
.sram2.bss     | [0x20020000,0x20027FFF] | Data         | Zeroed
.sram2.noinit  | [0x20020000,0x20027FFF] | Data         | None
               |                         |              |
.sramx.data    | [0x04000000,0x04007FFF] | Data or code | Initialized
.sramx.ramfunc | [0x04000000,0x04007FFF] | Data or code | Initialized
.sramx.bss     | [0x04000000,0x04007FFF] | Data         | Zeroed
.sramx.noinit  | [0x04000000,0x04007FFF] | Data         | None
               |                         |              |
.text          | [0x00000000,0x0403FFFF] | Code and read-only data (flash ROM)
```

Examples:
```
/* place a 16KB buffer in SRAM2 */
__attribute__((section(".sram2.bss"))) char buf[16384];

/* place an initialized data table in SRAM1 */
__attribute__((section(".sram1.data"))) int table[] = {0,1,2,3,4,5,6,7};

/* define a function that runs from SRAMX */
__attribute__((section(".sramx.ramfunc"))) void fastfunction(void) { /* ... */ }

/* allocate an 100KB buffer that starts in SRAM0 but overflows into SRAM1 */
int big_buffer[102400];
```

If more than 64KB of data is placed in SRAM0, it will overflow into SRAM1 and
SRAM2 if necessary. This allows creation of contiguous arrays larger than 64KB.
The linker will assert an error if there is insufficient room in SRAM1 and/or
SRAM2 to accommodate the data in `.sram1*` and `.sram2*` sections.

The M4 core's stack may be placed in SRAM2 or SRAMX. If `M4_STACK_IN_SRAMX` is
set to `1` in the Makefile, the M4's stack is placed at the end of SRAMX. (The
M0+'s stack can be anywhere; it's up to the M4 master to specify the location
of the coprocessor stack.)

If both cores are executing code from flash, or the same RAM bank, performance
will be reduced due to bus contention. It's typically recommended that
time-critical M0+ and/or M4 code be placed in SRAM. For optimal performance,
each core should run code from a separate bank. Functions can be placed in RAM
using one of the `*ramfunc` sections described above. Example:

```
__attribute__((section(".sramx.ramfunc"))) void core0_code(void) { /* ... */ }
__attribute__((section(".sram1.ramfunc"))) void core1_code(void) { /* ... */ }
```

allows the functions `core0_code()` and `core1_code()` to be run simultaneously
with minimal contention.


Dynamically loading code from flash to RAM
------------------------------------------

In some cases, it may be desired that one or both cores execute a different
chunk of code from RAM based on runtime conditions, but you don't want to pay
the RAM penalty of keeping all possible executable chunks of code in RAM all the
time.

For example, you may want to have the M0+ coprocessor executing one of several
functions depending on the current situation, but you only want to keep the
currently-executing function in RAM, swapping in new code from flash as needed.
In this case, you can use the numbered `.dyncode` sections. The contents of
dyncode sections are placed in flash, but additional symbols are defined
indicating the start and length of each chunk.

```
__attribute__((section(".dyncode0"))) coprocessor_code_a(void) { /* ... */ }
__attribute__((section(".dyncode1"))) coprocessor_code_b(void) { /* ... */ }

/* These are exposed by the linker script */
extern const char   __dyncode0_start__[];
extern const size_t __dyncode0_size__;
extern const char   __dyncode1_start__[];
extern const size_t __dyncode1_size__;

char coprocessor_ram_code[4096]; /* needs to be large enough */

void load_coprocessor_code(int program_number) {
  switch (program_number) {
    case 0:
      memcpy(coprocessor_ram_code, __dyncode0_start__, __dyncode0_size__);
      break;
    case 1: default:
      memcpy(coprocessor_ram_code, __dyncode1_start__, __dyncode1_size__);
      break;
  }
  /* start coprocessor... */
}
```

The linker script provides four dyncode sections: `.dyncode0` through `.dyncode3`.
If more are required, or more symbolic names are needed, the linker script must
be edited appropriately (or generated programmatically).