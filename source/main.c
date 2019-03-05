#include "LPC54114_cm4.h"

#define LED_PORT  1U
#define LED_PIN   10U

int main(void)
{
  /* enable IOCON and GPIO clocks */
  SYSCON->AHBCLKCTRLSET[0] = SYSCON_AHBCLKCTRL_IOCON_MASK | SYSCON_AHBCLKCTRL_GPIO0_MASK | SYSCON_AHBCLKCTRL_GPIO1_MASK;
  /* configure pin for GPIO */
  IOCON->PIO[LED_PORT][LED_PIN] =
    IOCON_PIO_FUNC(0) | /* configured as GPIO */
    IOCON_PIO_MODE(2) | /* pullup enabled */
    IOCON_PIO_DIGIMODE_MASK; /* digital mode */
  /* set GPIO pin as an output */
  GPIO->DIRSET[LED_PORT] = (1U << LED_PIN);

  /* rapidly toggle GPIO */
  while (1) {
    GPIO->NOT[LED_PORT] = (1U << LED_PIN);
  }
  return 0;
}
