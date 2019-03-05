#include "LPC54114_cm4.h"

#define LED_PORT  1U
#define LED_PIN   10U

int main(void)
{
  /* enable IOCON and GPIO clocks */
  SYSCON->AHBCLKCTRLSET[0] = (1U << 13) | (1U << (14+(LED_PORT)));
  /* configure pin for GPIO */
  IOCON->PIO[LED_PORT][LED_PIN] =
    (0U << 0) | /* configured as GPIO */
    (2U << 3) | /* pullup enabled */
    (1U << 7);  /* digital mode */
  /* set GPIO pin as an output */
  GPIO->DIRSET[LED_PORT] = (1U << LED_PIN);

  /* rapidly toggle GPIO */
  while (1) {
    GPIO->NOT[LED_PORT] = (1U << LED_PIN);
  }
  return 0;
}
