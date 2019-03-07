.syntax unified
.section .vectors, "a"
.align 2
.globl __vectors
__vectors:
    .long   __estack
    .long   Reset_Handler
    .long   NMI_Handler
    .long   HardFault_Handler
    .long   MemManage_Handler
    .long   BusFault_Handler
    .long   UsageFault_Handler
    .long   Default_Handler @ reserved
    .long   Default_Handler @ reserved
    .long   Default_Handler @ reserved
    .long   Default_Handler @ reserved
    .long   SVC_Handler
    .long   DebugMon_Handler
    .long   Default_Handler @ reserved
    .long   PendSV_Handler
    .long   SysTick_Handler
    .long   WDT_BOD_Handler
    .long   DMA_Handler
    .long   GINT0_Handler
    .long   GINT1_Handler
    .long   PIN_INT0_Handler
    .long   PIN_INT1_Handler
    .long   PIN_INT2_Handler
    .long   PIN_INT3_Handler
    .long   UTICK_Handler
    .long   MRT_Handler
    .long   CT32B0_Handler
    .long   CT32B1_Handler
    .long   SCT0_Handler
    .long   CT32B3_Handler
    .long   FLEXCOMM0_Handler
    .long   FLEXCOMM1_Handler
    .long   FLEXCOMM2_Handler
    .long   FLEXCOMM3_Handler
    .long   FLEXCOMM4_Handler
    .long   FLEXCOMM5_Handler
    .long   FLEXCOMM6_Handler
    .long   FLEXCOMM7_Handler
    .long   ADC0_SEQA_Handler
    .long   ADC0_SEQB_Handler
    .long   ADC0_THCMP_Handler
    .long   DMIC_Handler
    .long   HWVAD_Handler
    .long   USB_WAKEUP_Handler
    .long   USB_Handler
    .long   RTC_Handler
    .long   Default_Handler @ resered
    .long   MAILBOX_Handler
    .long   PIN_INT4_Handler
    .long   PIN_INT5_Handler
    .long   PIN_INT6_Handler
    .long   PIN_INT7_Handler
    .long   CT32B2_Handler
    .long   CT32B4_Handler
    .long   Default_Handler @ reserved
    .long   Default_Handler @ reserved
    .size    __vectors, . - __vectors


.text
.thumb
.thumb_func
.align 2
.global Reset_Handler
.weak   Reset_Handler
.type   Reset_Handler, %function
@ This is the entry point for both M4 and M0+ code.
@ The M0+ does NOT automatically start at the address in SYSCON->CPBOOT when
@ booted by the master.
@ Instead, the reset handler needs to read the CPU ID and run the appropriate
@ startup code for the current core.
Reset_Handler:
    .arch armv6-m
    ldr     r0, =0xE000ED00 @ read CPUID register in System Control Block
    ldr     r0, [r0]
    ldr     r1, =0x410cc601 @ CPUID for Cortex-M0+
    cmp     r0, r1
    bne     m4_boot

m0_boot:
    ldr     r0, =0x40000804 @ coprocessor boot register
    ldr     r1, [r0]
    cmp     r1, #0          @ sleep if boot address is not set
    beq     m0_sleep
    ldr     r0, [r0, #4]    @ coprocessor stack pointer
    mov     sp, r0
    bx      r1              @ jump to coprocessor code
m0_sleep:
    wfi
    b       m0_sleep

m4_boot:
    .arch armv7-m
    adr     r7, m4_boot_constants
    ldmia   r7!, {r0, r1, r2, r3, r4, r5, r6}
    @ enable clocks for all SRAM
    str     r1, [r0]
    @ initialize SRAM0
    ldr     r0, =copy_data_and_clear_bss
    blx     r0
    @ initialize SRAM1
    ldmia   r7!, {r2, r3, r4, r5, r6}
    blx     r0
    @ initialize SRAM2
    ldmia   r7!, {r2, r3, r4, r5, r6}
    blx     r0
    @ initialize SRAMX
    ldmia   r7, {r2, r3, r4, r5, r6, r7}
    blx     r0
    @ start C code
    @ r7: address of __libc_init_array
    blx     r7
    ldr     r0, =main
    bx      r0

.thumb_func
copy_data_and_clear_bss:
    @ r2: data source address
    @ r3: data destination start address
    @ r4: data destination end address
1:  cmp     r3, r4
    ittt    lt
    ldrlt   r1, [r2], #4
    strlt   r1, [r3], #4
    blt     1b
    @ clear bss
    @ r5: bss start address
    @ r6: bss end address
    movs    r1, 0
2:  cmp     r5, r6
    itt     lt
    strlt   r1, [r5], #4
    blt     2b
    bx      lr

    .pool
m4_boot_constants:
    .long   0x40000220  @ SYSCON->AHBCLKCTRL0SET
    .long   0x18        @ enable SRAM1 and SRAM2
    .long   __etext
    .long   __data_start__
    .long   __data_end__
    .long   __bss_start__
    .long   __bss_end__
    .long   __edata
    .long   __sram1_data_start__
    .long   __sram1_data_end__
    .long   __sram1_bss_start__
    .long   __sram1_bss_end__
    .long   __edata1
    .long   __sram2_data_start__
    .long   __sram2_data_end__
    .long   __sram2_bss_start__
    .long   __sram2_bss_end__
    .long   __edata2
    .long   __sramx_data_start__
    .long   __sramx_data_end__
    .long   __sramx_bss_start__
    .long   __sramx_bss_end__
    .long   __libc_init_array
.pool
.size Reset_Handler, . - Reset_Handler

.align  1
.thumb_func
.type Default_Handler, %function
Default_Handler:
    b Default_Handler
.size Default_Handler, . - Default_Handler

.macro def_stub_isr handler_name
    .weak \handler_name
    .thumb_func
    .type \handler_name, %function
    .equiv \handler_name, Default_Handler
.endm

def_stub_isr NMI_Handler
def_stub_isr HardFault_Handler
def_stub_isr MemManage_Handler
def_stub_isr BusFault_Handler
def_stub_isr UsageFault_Handler
def_stub_isr SVC_Handler
def_stub_isr DebugMon_Handler
def_stub_isr PendSV_Handler
def_stub_isr SysTick_Handler
def_stub_isr WDT_BOD_Handler
def_stub_isr DMA_Handler
def_stub_isr GINT0_Handler
def_stub_isr GINT1_Handler
def_stub_isr PIN_INT0_Handler
def_stub_isr PIN_INT1_Handler
def_stub_isr PIN_INT2_Handler
def_stub_isr PIN_INT3_Handler
def_stub_isr UTICK_Handler
def_stub_isr MRT_Handler
def_stub_isr CT32B0_Handler
def_stub_isr CT32B1_Handler
def_stub_isr SCT0_Handler
def_stub_isr CT32B3_Handler
def_stub_isr FLEXCOMM0_Handler
def_stub_isr FLEXCOMM1_Handler
def_stub_isr FLEXCOMM2_Handler
def_stub_isr FLEXCOMM3_Handler
def_stub_isr FLEXCOMM4_Handler
def_stub_isr FLEXCOMM5_Handler
def_stub_isr FLEXCOMM6_Handler
def_stub_isr FLEXCOMM7_Handler
def_stub_isr ADC0_SEQA_Handler
def_stub_isr ADC0_SEQB_Handler
def_stub_isr ADC0_THCMP_Handler
def_stub_isr DMIC_Handler
def_stub_isr HWVAD_Handler
def_stub_isr USB_WAKEUP_Handler
def_stub_isr USB_Handler
def_stub_isr RTC_Handler
def_stub_isr MAILBOX_Handler
def_stub_isr PIN_INT4_Handler
def_stub_isr PIN_INT5_Handler
def_stub_isr PIN_INT6_Handler
def_stub_isr PIN_INT7_Handler
def_stub_isr CT32B2_Handler
def_stub_isr CT32B4_Handler

.end
