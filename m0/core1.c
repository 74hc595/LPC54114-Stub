#include "LPC54114_cm0plus.h"

#define LED2_PORT  1U
#define LED2_PIN   9U

__attribute__((noinline,section(".ramfunc"))) void core1(void)
{
  /* rapidly toggle GPIO */
  while (1) {
    GPIO->NOT[LED2_PORT] = (1U << LED2_PIN);
  }
}
