#include "LPC54114_cm4.h"

/**

multicore observations:
- M0 core starts in the boot ROM

*/

/* green LED */
#define LED1_PORT  1U
#define LED1_PIN   10U

/* blue LED */
#define LED2_PORT  1U
#define LED2_PIN   9U

#define CM0_STACK_SIZE  256
static unsigned char cm0_stack[CM0_STACK_SIZE];
extern const char _binary_core1_m0_o_bin_start[];
extern const char _binary_core1_m0_o_bin_end[];

__attribute__((noreturn)) void core1_loop(void)
{
  while (1) {
    asm volatile(
      "ldr r0, =0x4008e304\n"
      "movs r1, #1\n"
      "lsls r1, #9\n"
      "str r1, [r0]\n"
      "nop\n"
    );
  }
}


int main(void)
{
  /* enable IOCON and GPIO clocks */
  SYSCON->AHBCLKCTRLSET[0] = SYSCON_AHBCLKCTRL_IOCON_MASK | SYSCON_AHBCLKCTRL_GPIO0_MASK | SYSCON_AHBCLKCTRL_GPIO1_MASK;
  /* configure pins for GPIO */
  IOCON->PIO[LED1_PORT][LED1_PIN] =
    IOCON_PIO_FUNC(0) | /* configured as GPIO */
    IOCON_PIO_MODE(2) | /* pullup enabled */
    IOCON_PIO_DIGIMODE_MASK; /* digital mode */
  IOCON->PIO[LED2_PORT][LED2_PIN] =
    IOCON_PIO_FUNC(0) | /* configured as GPIO */
    IOCON_PIO_MODE(2) | /* pullup enabled */
    IOCON_PIO_DIGIMODE_MASK; /* digital mode */

  /* set GPIO pins as outputs, initially off */
  GPIO->DIRSET[LED1_PORT] = (1U << LED1_PIN);
  GPIO->DIRSET[LED2_PORT] = (1U << LED2_PIN);
  GPIO->SET[LED1_PORT] = (1U << LED1_PIN);
  GPIO->SET[LED2_PORT] = (1U << LED2_PIN);

  // // // /* configure and start the M0 core */
  SYSCON->CPBOOT = (unsigned long)(core1_loop);
  SYSCON->CPSTACK = (unsigned long)(cm0_stack+sizeof(cm0_stack));

  uint32_t cpuctrl = SYSCON->CPUCTRL;
  cpuctrl |= 0xC0C48000U;
  SYSCON->CPUCTRL = cpuctrl | SYSCON_CPUCTRL_CM0RSTEN_MASK | SYSCON_CPUCTRL_CM0CLKEN_MASK;
  SYSCON->CPUCTRL = (cpuctrl | SYSCON_CPUCTRL_CM0CLKEN_MASK) & (~SYSCON_CPUCTRL_CM0RSTEN_MASK);

  /* rapidly toggle GPIO */
  while (1) {
    GPIO->NOT[LED1_PORT] = (1U << LED1_PIN);
  }
  return 0;
}
