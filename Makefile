# Stub Makefile for LPC54114, Cortex-M4 and Cortex-M0+ dual-core

# PROGRAMMER ?= lpc-link2
PROGRAMMER ?= j-link

LPCXPRESSO_DIR ?= /Applications/lpcxpresso_8.2.2_650/lpcxpresso

PROJECT_NAME = lpc54114-stub
LINKER_SCRIPT = LPC54114J256.ld
CPU = LPC54114J256
DEBUG ?= 0

# Location of the M4 core's stack. (SRAM0, SRAM1, SRAM2, or SRAMX)
M4_STACK_BANK = SRAMX

SRC_DIRS = source startup
M0_SRC_DIRS = m0
BUILD_DIRS = $(addprefix build/,$(SRC_DIRS))
M0_BUILD_DIRS = $(addprefix build/,$(M0_SRC_DIRS))
INCLUDE_DIRS = vendor-include vendor-include/CMSIS $(SRC_DIRS) $(M0_SRC_DIRS)

SRC = $(foreach sdir,$(SRC_DIRS),$(wildcard $(sdir)/*.c))
ASM = $(foreach sdir,$(SRC_DIRS),$(wildcard $(sdir)/*.S))
OBJ = $(patsubst %.c,build/%.o,$(SRC)) $(patsubst %.S,build/%.o,$(ASM))

M0_SRC = $(foreach sdir,$(M0_SRC_DIRS),$(wildcard $(sdir)/*.c))
M0_ASM = $(foreach sdir,$(M0_SRC_DIRS),$(wildcard $(sdir)/*.S))
M0_OBJ = $(patsubst %.c,build/%.o,$(M0_SRC)) $(patsubst %.S,build/%.o,$(M0_ASM))

DEPS = $(OBJ:.o=.d) $(M0_OBJ:.o=.d)

vpath %.c $(SRC_DIRS) $(M0_SRC_DIRS)
vpath %.S $(SRC_DIRS) $(M0_SRC_DIRS)

CC = arm-none-eabi-gcc
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size
GDB = arm-none-eabi-gdb

OUT = $(PROJECT_NAME).elf
HEX = $(PROJECT_NAME).hex
SIZ = $(PROJECT_NAME).siz
MAP = $(PROJECT_NAME).map
LST = $(PROJECT_NAME).lst

CFLAGS = -D__STARTUP_CLEAR_BSS -Wall -fno-common -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -mthumb -mapcs -std=gnu99 -MMD -MP
LDFLAGS = -Xlinker -print-memory-usage -T $(LINKER_SCRIPT) -Xlinker -gc-sections -Xlinker -static -Xlinker -z -Xlinker muldefs -Wl,-Map,"$(MAP)" --specs=nano.specs -specs=nosys.specs -Wl,--defsym=M4_STACK_IN_$(M4_STACK_BANK)=1

ifeq ($(DEBUG),1)
	CFLAGS += -g -O0 -DDEBUG
	LDFLAGS += -g
else
	CFLAGS += -DNDEBUG -O3
endif

CFLAGS += $(addprefix -I,$(INCLUDE_DIRS))

M4_CFLAGS = $(CFLAGS) -DCPU_$(CPU)_cm4 -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
M0_CFLAGS = $(CFLAGS) -DCPU_$(CPU)_cm0plus -mcpu=cortex-m0plus -nostartfiles -mfloat-abi=soft


all: checkdirs $(OUT) $(HEX) $(SIZ)

checkdirs: $(BUILD_DIRS) $(M0_BUILD_DIRS)

$(BUILD_DIRS):
	mkdir -p $@

$(M0_BUILD_DIRS):
	mkdir -p $@

$(OUT): $(OBJ) $(M0_OBJ)
	$(CC) $(M4_CFLAGS) $(LDFLAGS) -o $(OUT) $(OBJ) $(M0_OBJ)
	$(OBJDUMP) -D $(OUT) > $(LST)

define make-goal
$1/%.o: %.S
	$(CC) $(M4_CFLAGS) -x assembler-with-cpp -c $$< -o $$@

$1/%.o: %.c
	$(CC) $(M4_CFLAGS) -c $$< -o $$@
endef


define make-goal-m0
$1/%.m0: %.S
	$(CC) $(M0_CFLAGS) -x assembler-with-cpp -c $$< -o $$@

$1/%.m0: %.c
	$(CC) $(M0_CFLAGS) -Wl,-r -c $$< -o $$@

# The .ARM.attributes section needs to be deleted from M0+ object files,
# or ld will fail because it won't link together objects with different ABIs.
$1/%.o: $1/%.m0
	$(OBJCOPY) --remove-section=.ARM.attributes $$< $$@
endef


$(HEX): $(OUT)
	$(OBJCOPY) -O ihex $(OUT) $(HEX)

$(SIZ): $(OUT)
	$(SIZE) --format=berkeley $(OUT)

clean:
	rm -f $(OUT) $(HEX) $(SIZ) $(MAP) $(LST)
	rm -rf build

flash: $(OUT) $(HEX)
ifeq ($(PROGRAMMER),lpc-link2)
	$(LPCXPRESSO_DIR)/bin/boot_link2 || true
	$(LPCXPRESSO_DIR)/bin/crt_emu_cm_redlink --flash-load-exec $(OUT) -g --debug 2 -p $(CPU)
else ifeq ($(PROGRAMMER),j-link)
	echo "r" > jlinkscript
	echo "loadfile $(HEX)" >> jlinkscript
	echo "r" >> jlinkscript
	echo "q" >> jlinkscript
	JLinkExe -device $(CPU) -if SWD -speed 4000 -autoconnect 1 -commanderscript jlinkscript
	rm jlinkscript
else
	echo "Unsupported programmer"
	exit 1
endif

# start gdbserver for the M4 core
debugserver:
ifeq ($(PROGRAMMER),j-link)
	JLinkGDBServer -device $(CPU) -if SWD -speed 4000 -port 2331
endif

# start gdbserver for the M0+ core
debugserver_m0:
ifeq ($(PROGRAMMER),j-link)
	JLinkGDBServer -device $(CPU)_m0 -if SWD -speed 4000 -port 2334
endif

# debug the M4 core (for j-link, JLinkGDBServer must already be started)
debug: $(OUT)
ifeq ($(PROGRAMMER),lpc-link2)
	$(LPCXPRESSO_DIR)/bin/boot_link2 || true
	$(GDB) --eval-command="target extended-remote | $(LPCXPRESSO_DIR)/bin/crt_emu_cm_redlink -g -mi -2 -p $(CPU)" $(OUT)
else ifeq ($(PROGRAMMER),j-link)
	$(GDB) --eval-command='target remote :2331' $(OUT)
else
	echo "Unsupported programmer"
	exit 1
endif

# debug the M0+ core (for j-link, JLinkGDBServer must already be started)
debug_m0: $(OUT)
ifeq ($(PROGRAMMER),lpc-link2)
	$(LPCXPRESSO_DIR)/bin/boot_link2 || true
	$(GDB) --eval-command="target extended-remote | $(LPCXPRESSO_DIR)/bin/crt_emu_cm_redlink -g -mi -2 -p $(CPU) --coreindex=1:0" $(OUT)
else ifeq ($(PROGRAMMER),j-link)
	$(GDB) --eval-command='target remote :2334' $(OUT)
else
	echo "Unsupported programmer"
	exit 1
endif

.PHONY: all checkdirs clean debug debug_m0 debugserver debugserver_m0 flash

$(foreach bdir,$(M0_BUILD_DIRS),$(eval $(call make-goal-m0,$(bdir))))
$(foreach bdir,$(BUILD_DIRS),$(eval $(call make-goal,$(bdir))))

-include $(DEPS)
