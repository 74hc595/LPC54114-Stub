# Stub Makefile for LPC54114, Cortex-M4 core only

# TODO: j-link support
PROGRAMMER ?= lpc-link2

LPCXPRESSO_DIR = /Applications/lpcxpresso_8.2.2_650/lpcxpresso

PROJECT_NAME = lpc54114-stub
LINKER_SCRIPT = LPC54114J256_cm4_flash.ld
CPU = LPC54114J256BD64_cm4
PROGRAMMER_CPU = LPC54114J256
DEBUG ?= 1

SRC_DIRS = board drivers source startup
BUILD_DIRS = $(addprefix build/,$(SRC_DIRS))
INCLUDE_DIRS = CMSIS $(SRC_DIRS)

SRC = $(foreach sdir,$(SRC_DIRS),$(wildcard $(sdir)/*.c))
ASM = $(foreach sdir,$(SRC_DIRS),$(wildcard $(sdir)/*.S))
OBJ = $(patsubst %.c,build/%.o,$(SRC)) $(patsubst %.S,build/%.o,$(ASM))
DEPS = $(OBJ:.o=.d)

vpath %.c $(SRC_DIRS)
vpath %.S $(SRC_DIRS)

CC = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size
GDB = arm-none-eabi-gdb

OUT = $(PROJECT_NAME).elf
HEX = $(PROJECT_NAME).hex
SIZ = $(PROJECT_NAME).siz
MAP = $(PROJECT_NAME).map
LST = $(PROJECT_NAME).lst

#CFLAGS = -mcpu=cortex-m0plus -mthumb -Os -ggdb -fmessage-length=0 -fsigned-char -fno-common -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -mapcs -std=gnu99 -Wall -DCPU_$(CPU) -D__STARTUP_CLEAR_BSS
CFLAGS = -DCPU_$(CPU) -D__STARTUP_CLEAR_BSS -Wall -fno-common -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -mthumb -mapcs -std=gnu99 -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -MMD -MP
LDFLAGS = -T $(LINKER_SCRIPT) -Xlinker -gc-sections -Xlinker -static -Xlinker -z -Xlinker muldefs -Wl,-Map,"$(MAP)" --specs=nano.specs -specs=nosys.specs

ifeq ($(DEBUG),1)
	CFLAGS += -g -O0 -DDEBUG
	LDFLAGS += -g
else
	CFLAGS += -DNDEBUG -O3
endif


CFLAGS += $(addprefix -I,$(INCLUDE_DIRS))

all: checkdirs $(OUT) $(HEX) $(SIZ)

checkdirs: $(BUILD_DIRS)

$(BUILD_DIRS):
	mkdir -p $@

# Tool invocations
$(OUT): $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(OUT) $(OBJ)
	$(OBJDUMP) -z -D $(OUT) > $(LST)

define make-goal
$1/%.o: %.S
	$(CC) $(CFLAGS) -x assembler-with-cpp -c $$< -o $$@

$1/%.o: %.c
	$(CC) $(CFLAGS) -MMD -MP -c $$< -o $$@

endef

$(HEX): $(OUT)
	$(OBJCOPY) -O ihex $(OUT) $(HEX)

$(SIZ): $(OUT)
	$(SIZE) --format=berkeley $(OUT)

# Other Targets
clean:
	rm -f $(OUT) $(HEX) $(SIZ) $(MAP) $(LST)
	rm -rf build

flash: $(OUT)
ifeq ($(PROGRAMMER),lpc-link2)
	$(LPCXPRESSO_DIR)/bin/boot_link2 || true
	$(LPCXPRESSO_DIR)/bin/crt_emu_cm_redlink --flash-load-exec $(OUT) -g --debug 2 -p $(PROGRAMMER_CPU)
else ifeq ($(PROGRAMMER),j-link)
	echo "TODO: J-Link support"
	exit 1
else
	echo "Unsupported programmer"
	exit 1
endif

debug: $(OUT)
ifeq ($(PROGRAMMER),lpc-link2)
	$(GDB) --eval-command="target extended-remote | $(LPCXPRESSO_DIR)/bin/crt_emu_cm_redlink -g -mi -2 -p $(PROGRAMMER_CPU)" $(OUT)
else ifeq ($(PROGRAMMER),j-link)
	echo "TODO: J-Link support"
	exit 1
else
	echo "Unsupported programmer"
	exit 1
endif



# Pin 33 (PTB1) to FTDI RX (yellow)
# Pin 34 (PTB0) to FTDI TX (orange)
#flash: $(HEX)
#	$(BLHOST) -n -d -V -p $(BLHOST_PORT) flash-erase-all-unsecure
#	$(BLHOST) -n -d -V -p $(BLHOST_PORT) flash-image $(HEX) erase
#	$(BLHOST) -n -d -V -p $(BLHOST_PORT) reset


.PHONY: all checkdirs clean 

$(foreach bdir,$(BUILD_DIRS),$(eval $(call make-goal,$(bdir))))

-include $(DEPS)
