TARGET = fft

AVRDUDE_PATH = /usr/local/bin
AVRDUDE_DRAGON = dragon_isp
AVRDUDE_MKII = avrispmkII
AVRDUDE_PORT = usb
AVRDUDE_CONF = /usr/local/etc/avrdude.conf
AVRDUDE_VERBOSITY = -vv -B0.13

NORMAL_LFUSE = 0xff
NORMAL_HFUSE = 0xdf
NORMAL_EFUSE = 0x04

DEBUGGING_LFUSE = 0xff
DEBUGGING_HFUSE = 0x9f
DEBUGGING_EFUSE = 0x04

AVRDUDE_MCU = m328p
MCU         = atmega328p
F_CPU       = 20000000

AVARICE_MCU = $(MCU)
AVARICE_PORT = 4242
AVARICE_FLAGS = --program --file $(TARGET).elf --part $(AVARICE_MCU) --debugwire --dragon -d localhost:$(AVARICE_PORT)

AVR_TOOLS_PATH = /usr/local/bin
LIBRARY_DIR = include
INCLUDE_DIR = include

SRC = main.c
ASRC = ffft.S lcd.S adc.S avg.S logtable.S

INCLUDE = \
			-I$(LIBRARY_DIR) \
			-I$(INCLUDE_DIR) \
			-I.

AS_INCLUDE = -I.


FORMAT = ihex


# Name of this Makefile (used for "make depend").
MAKEFILE = Makefile

# Debugging format.
# Native formats for AVR-GCC's -g are stabs [default], or dwarf-2.
# AVR (extended) COFF requires stabs, plus an avr-objcopy run.
# gdb3 is the most robust format available, allowing for even 
# proprocessor macros to be expanded
DEBUG = gdb3

OPT = s

# Place -D or -U options here
CDEFS   = -DF_CPU=$(F_CPU)
CXXDEFS = -DF_CPU=$(F_CPU)

# Place -I options here
CINCS   = $(INCLUDE)
CXXINCS = $(INCLUDE)
ASINCS  = $(AS_INCLUDE)

# Compiler flag to set the C Standard level.
# c89   - "ANSI" C
# gnu89 - c89 plus GCC extensions
# c99   - ISO C99 standard (not yet fully implemented)
# gnu99 - c99 plus GCC extensions

CSTANDARD = -std=gnu99
CDEBUG    = -g$(DEBUG)
CWARN     = -Wall -Wstrict-prototypes -Wa,-adhlns=$(subst $(suffix $<),.lst,$<)
CTUNING   = -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
#CEXTRA   = -Wa,-adhlns=$(<:.c=.lst)

ASFLAGS     = -mmcu=$(MCU) -Wa,-adhlns=$(<:.S=.lst),-gstabs 
CFLAGS      = -mmcu=$(MCU) $(CDEBUG) $(CDEFS) $(CINCS) -O$(OPT) $(CWARN) $(CSTANDARD) $(CEXTRA) -L.
CXXFLAGS    = -mmcu=$(MCU) $(CDEFS) $(CXXINCS) -O$(OPT) -L.
LDFLAGS     = #-lm

# AVRDUDE Settings
AVRDUDE_WRITE_FLASH = -Uflash:w:$(TARGET).hex:i
AVRDUDE_WRITE_NORMAL_HFUSE = -Uhfuse:w:$(NORMAL_HFUSE):m
AVRDUDE_WRITE_NORMAL_LFUSE = -Ulfuse:w:$(NORMAL_LFUSE):m
AVRDUDE_WRITE_NORMAL_EFUSE = -Uefuse:w:$(NORMAL_EFUSE):m
AVRDUDE_WRITE_DEBUGGING_HFUSE = -Uhfuse:w:$(DEBUGGING_HFUSE):m
AVRDUDE_WRITE_DEBUGGING_LFUSE = -Ulfuse:w:$(DEBUGGING_LFUSE):m
AVRDUDE_WRITE_DEBUGGING_EFUSE = -Uefuse:w:$(DEBUGGING_EFUSE):m

AVRDUDE_NORMAL_FUSES_FLAGS = $(AVRDUDE_WRITE_NORMAL_HFUSE) $(AVRDUDE_WRITE_NORMAL_LFUSE) $(AVRDUDE_WRITE_NORMAL_EFUSE)
AVRDUDE_DEBUGGING_FUSES_FLAGS = $(AVRDUDE_WRITE_DEBUGGING_HFUSE) $(AVRDUDE_WRITE_DEBUGGING_LFUSE) $(AVRDUDE_WRITE_DEBUGGING_EFUSE)

AVRDUDE_FLAGS       = $(AVRDUDE_EXTRA_FLAGS) $(AVRDUDE_VERBOSITY) -P$(AVRDUDE_PORT) -p$(AVRDUDE_MCU) -C$(AVRDUDE_CONF)

# Combine all necessary flags and optional flags.
# Add target processor to flags.
ALL_CFLAGS   = $(CFLAGS) 
ALL_CXXFLAGS = $(CXXFLAGS)
ALL_ASFLAGS  = -mmcu=$(MCU) -I. -x assembler-with-cpp $(ASFLAGS)

# Programs
CC      = $(AVR_TOOLS_PATH)/avr-gcc
CXX     = $(AVR_TOOLS_PATH)/avr-g++
OBJCOPY = $(AVR_TOOLS_PATH)/avr-objcopy
OBJDUMP = $(AVR_TOOLS_PATH)/avr-objdump
AR      = $(AVR_TOOLS_PATH)/avr-ar
SIZE    = $(AVR_TOOLS_PATH)/avr-size
NM 	    = $(AVR_TOOLS_PATH)/avr-nm
AS 	    = $(AVR_TOOLS_PATH)/avr-as
AVRDUDE = $(AVRDUDE_PATH)/avrdude
REMOVE  = rm -fv
MV      = mv -f
AVARICE = avarice
GDB		= avr-gdb


# Define all object files.
OBJ = $(SRC:.c=.o) $(CXXSRC:.cpp=.o) $(ASRC:.S=.o)

# Preprocessor files
PP =  $(SRC:.c=.i) $(CXXSRC:.cpp=.i) $(ASRC:.S=.i)

# Define all listing files.
LST = $(ASRC:.S=.lst) $(CXXSRC:.cpp=.lst) $(SRC:.c=.lst)

OBJCOPY_FLAGS = -j .text -j .data -O$(FORMAT)

# Default target.
all: sizebefore build sizeafter

build: hex

printobj: 
	@echo $(OBJ)
printpp:
	@echo $(PP)

elf: $(TARGET).elf
lst: $(TARGET).lst
hex: $(TARGET).hex 
eep: $(TARGET).eep
lss: $(TARGET).lss
sym: $(TARGET).sym

# Program the device.
program: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -c$(AVRDUDE_MKII) $(AVRDUDE_WRITE_FLASH) || \
	$(AVRDUDE) $(AVRDUDE_FLAGS) -c$(AVRDUDE_DRAGON) $(AVRDUDE_WRITE_FLASH) 
program2: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -c$(AVRDUDE_MKII) $(AVRDUDE_WRITE_FLASH)

fuses:
	$(AVRDUDE) -c$(AVRDUDE_DRAGON) $(AVRDUDE_FLAGS) $(AVRDUDE_NORMAL_FUSES_FLAGS); sleep 5; \
	$(AVRDUDE) -c$(AVRDUDE_DRAGON) $(AVRDUDE_FLAGS) $(AVRDUDE_NORMAL_FUSES_FLAGS)
debug-fuses:
	$(AVRDUDE) -c$(AVRDUDE_DRAGON) $(AVRDUDE_FLAGS) $(AVRDUDE_DEBUGGING_FUSES_FLAGS) \
		@echo "Power cycle the target to enable debugwire"

debug: $(TARGET).elf 
	$(AVARICE) $(AVARICE_FLAGS)
gdb:
	$(GDB) $(TARGET).elf

# Display size of file.
HEXSIZE = $(SIZE) --target=$(FORMAT) $(TARGET).hex
ELFSIZE = $(SIZE) $(TARGET).elf

sizebefore: 
	@if [ -f $(TARGET).elf ]; then echo; echo $(MSG_SIZE_BEFORE); $(HEXSIZE); echo; fi 
sizeafter:
	@if [ -f $(TARGET).elf ]; then echo; echo $(MSG_SIZE_AFTER); $(HEXSIZE); echo; fi

adc.S: logtable.S

logtable.S: scripts/log_table_adc.php config.h
	scripts/log_table_adc.php > $@

adc.o: config.h
avg.o: config.h
ffft.o: config.h
lcd.o: config.h
main.o: config.h

%.hex: %.elf
	$(OBJCOPY) $(OBJCOPY_FLAGS) $< $@

%.o: %.cpp
	$(CXX) -c $(ALL_CXXFLAGS) $< -o $@

$(TARGET).elf: $(OBJ) $(PP)
	$(CC) $(ALL_CFLAGS) $(OBJ) -o $@ $(LDFLAGS)

%.i: %.c 
	$(CC) -E $(ALL_CFLAGS) $< -o $@

%.i: %.S 
	$(CC) -E $(ALL_CFLAGS) $< -o $@

%.o: %.c %.h
	$(CC) -c $(ALL_CFLAGS) $< -o $@

%.s: %.c
	$(CC) -S $(ALL_CFLAGS) $< -o $@

%.o: %.S %.h
	$(CC) -c $(ALL_ASFLAGS) $< -o $@

# Target: clean project.
clean:
	@$(REMOVE) $(TARGET).hex $(TARGET).eep $(TARGET).cof $(TARGET).elf \
	$(TARGET).map $(TARGET).sym $(TARGET).lss core.a \
	$(OBJ) $(LST) $(PP) $(SRC:.c=.s) $(SRC:.c=.d) $(CXXSRC:.cpp=.s) $(CXXSRC:.cpp=.d) \

depend:
	if grep '^# DO NOT DELETE' $(MAKEFILE) >/dev/null; \
	then \
		sed -e '/^# DO NOT DELETE/,$$d' $(MAKEFILE) > \
			$(MAKEFILE).$$$$ && \
		$(MV) $(MAKEFILE).$$$$ $(MAKEFILE); \
	fi
	echo '# DO NOT DELETE THIS LINE -- make depend depends on it.' \
		>> $(MAKEFILE); \
	$(CC) -M -mmcu=$(MCU) $(CDEFS) $(CINCS) $(SRC) $(ASRC) >> $(MAKEFILE)

.PHONY:	all build elf hex eep lss sym program coff extcoff clean depend sizebefore sizeafter
