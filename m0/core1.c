#include "LPC54114_cm0plus.h"

#define LED2_PORT  1U
#define LED2_PIN   9U

void _start(void)
{
  /* rapidly toggle GPIO */
  while (1) {
    GPIO->NOT[LED2_PORT] = (1U << LED2_PIN);
  }
}
