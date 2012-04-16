TARGET = fft

AVRDUDE_PATH = /usr/local/bin
AVRDUDE_PROGRAMMER = avrispmkII
AVRDUDE_PORT = usb
AVRDUDE_CONF = /usr/local/etc/avrdude.conf
AVRDUDE_VERBOSITY = -vv -B0.13

HFUSE = 0xdf
LFUSE = 0xff
EFUSE = 0x04

AVRDUDE_MCU = m328p
MCU         = atmega328p
F_CPU       = 20000000

AVR_TOOLS_PATH = /usr/local/bin
LIBRARY_DIR = include
INCLUDE_DIR = include

SRC = main.c
ASRC = ffft.S lcd.S adc.S avg.S

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
DEBUG = stabs

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
AVRDUDE_WRITE_HFUSE = -Uhfuse:w:$(HFUSE):m
AVRDUDE_WRITE_LFUSE = -Uhfuse:w:$(LFUSE):m
AVRDUDE_WRITE_EFUSE = -Uhfuse:w:$(EFUSE):m
AVRDUDE_FUSES_FLAGS = $(AVRDUDE_WRITE_HFUSE) $(AVRDUDE_WRITE_LFUSE) $(AVRDUDE_WRITE_EFUSE)
AVRDUDE_FLAGS       = $(AVRDUDE_EXTRA_FLAGS) $(AVRDUDE_VERBOSITY) -c$(AVRDUDE_PROGRAMMER) -P$(AVRDUDE_PORT) -p$(AVRDUDE_MCU) -C$(AVRDUDE_CONF)

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


# Define all object files.
OBJ = $(SRC:.c=.o) $(CXXSRC:.cpp=.o) $(ASRC:.S=.o)

# Define all listing files.
LST = $(ASRC:.S=.lst) $(CXXSRC:.cpp=.lst) $(SRC:.c=.lst)

OBJCOPY_FLAGS = -j .text -j .data -O$(FORMAT)

# Default target.
all: sizebefore build sizeafter

build: hex

printobj: 
	@echo $(OBJ)

elf: $(TARGET).elf
lst: $(TARGET).lst
hex: $(TARGET).hex 
eep: $(TARGET).eep
lss: $(TARGET).lss
sym: $(TARGET).sym

# Program the device.
program: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)
fuses:
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_FUSES_FLAGS)


# Display size of file.
HEXSIZE = $(SIZE) --target=$(FORMAT) $(TARGET).hex
ELFSIZE = $(SIZE) $(TARGET).elf

sizebefore: 
	@if [ -f $(TARGET).elf ]; then echo; echo $(MSG_SIZE_BEFORE); $(HEXSIZE); echo; fi 
sizeafter:
	@if [ -f $(TARGET).elf ]; then echo; echo $(MSG_SIZE_AFTER); $(HEXSIZE); echo; fi

%.hex: %.elf
	$(OBJCOPY) $(OBJCOPY_FLAGS) $< $@

%.o: %.cpp
	$(CXX) -c $(ALL_CXXFLAGS) $< -o $@

$(TARGET).elf: $(OBJ)
	$(CC) $(ALL_CFLAGS) $(OBJ) -o $@ $(LDFLAGS)


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
	$(OBJ) $(LST) $(SRC:.c=.s) $(SRC:.c=.d) $(CXXSRC:.cpp=.s) $(CXXSRC:.cpp=.d) \

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
