/**
 * Minimal LPC54114 dual-core example.
 *
 * This file contains the Cortex-M4 code.
 * m0/core1.c contains the Cortex-M0+ code.
 *
 * Each of the cores toggles a GPIO with no delay in between.
 * On the LPCXpresso54114 board, the Cortex-M4 core controls the green channel
 * of the RGB LED, and the Cortex-M0+ controls the blue channel.
 * When running properly, the RGB LED should appear cyan to the naked eye,
 * and inspecting pins 8 and 5 on connector J9 with a scope should show two
 * square waves.
 */
#include "LPC54114_cm4.h"

/* green and blue LEDs on LPCXpresso54114 */
#define LED1_PORT  1U
#define LED1_PIN   10U
#define LED2_PORT  1U
#define LED2_PIN   9U

#define M0_STACK_SIZE_WORDS  16
static unsigned m0_stack[M0_STACK_SIZE_WORDS];
extern void core1(void);


void main(void)
{
  /* enable IOCON, and GPIO clocks */
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

  /* configure and start the M0 core */
  SYSCON->CPBOOT  = (unsigned long)(core1);
  SYSCON->CPSTACK = (unsigned long)(m0_stack)+sizeof(m0_stack);
  uint32_t cpuctrl = SYSCON->CPUCTRL;
  cpuctrl |= 0xC0C48000U;
  SYSCON->CPUCTRL = cpuctrl | SYSCON_CPUCTRL_CM0RSTEN_MASK | SYSCON_CPUCTRL_CM0CLKEN_MASK;
  SYSCON->CPUCTRL = (cpuctrl | SYSCON_CPUCTRL_CM0CLKEN_MASK) & (~SYSCON_CPUCTRL_CM0RSTEN_MASK);

  /* rapidly toggle GPIO */
  while (1) {
    GPIO->NOT[LED1_PORT] = (1U << LED1_PIN);
  }
}
