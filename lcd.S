#include <avr/io.h> 
#include "ports.h"
#include "constants.h"
#include "config.h"

#define CHIP1 _BV(CSEL1)
#define CHIP2 _BV(CSEL2)

;#define LOGSCALE

; Prints data very quickly to the lcd

#define ZERO            r1
#define REMAINING_BLANK r28
#define NON_BLANK_COUNT r29
#define DATAR           r16
#define TEMPR           r17
#define COL             r18
#define ROW             r19
#define MAXVAL          r20
#define DISPLAY_DATA    r21
#define TEMPR2          r22
#define CHIPNO          r23

#define NUM_COLS 0x40
#define NUM_ROWS 0x08

.macro STROBE
    sbi    _SFR_IO_ADDR(PORTC),EN
    cbi    _SFR_IO_ADDR(PORTC),EN
.endm

.macro WAIT_BUSY_PREP    val
    ;ldi    TEMPR,\val
    out    _SFR_IO_ADDR(PORTC),\val

    ; Port D input
    out    _SFR_IO_ADDR(DDRD),ZERO

    ; Set enable bit
    sbi    _SFR_IO_ADDR(PORTC),EN

    ; Optional delay(s):
    ; Need to wait about 4 clock cycles before we can wait for the busy bit
    ;nop                                            ; delay
.endm

.macro WAIT_BUSY
    sbic    _SFR_IO_ADDR(PIND),7 ; skip if bit 7 is clear
    rjmp    .-4
.endm

.macro SET_PAGE pagenum,chipsel

    ldi    TEMPR,_BV(RW)
    or     TEMPR,\chipsel

    WAIT_BUSY_PREP TEMPR
    
    mov    ZH,r25       ; r25:r24 will be set to the address of the end of the display data (odd, I know)
    mov    ZL,r24       ; move pointer to X

    ldi    COL,NUM_COLS ; COL counter counts down

    WAIT_BUSY

    out    _SFR_IO_ADDR(PORTC),\chipsel

    mov    TEMPR,\pagenum
    ori    TEMPR,LCD_PAGE
    out    _SFR_IO_ADDR(PORTD),TEMPR

    ldi    TEMPR,0xff
    out    _SFR_IO_ADDR(DDRD),TEMPR

    STROBE
.endm

.macro PRINT_DATA chipsel
    ldi    TEMPR,_BV(RW)
    or     TEMPR,\chipsel

    WAIT_BUSY_PREP TEMPR

    ldi    TEMPR,_BV(DI)
    or     TEMPR,\chipsel
    ldi    TEMPR2,0xff

    WAIT_BUSY

    out    _SFR_IO_ADDR(PORTC),TEMPR
    out    _SFR_IO_ADDR(PORTD),DISPLAY_DATA ; set data on data port
    out    _SFR_IO_ADDR(DDRD),TEMPR2        ; set data port as output

    STROBE
.endm



.global fastlcd
.func fastlcd
fastlcd: 
    push    TEMPR
    push    DATAR
    push    COL
    push    ROW
    push    DISPLAY_DATA
    push    TEMPR2
    push    REMAINING_BLANK
    push    XL
    push    XH
    push    YL
    push    YH
    push    ZL
    push    ZH
    push    CHIPNO

    clr    ZERO

    ldi    CHIPNO,CHIP1

    ; XXX INTERESTING!!!! addi
    subi    r24,-128 ; Set r24:r25 to end of data
    sbci    r25,-1        

displaystart:
    clr    REMAINING_BLANK
    clr    ROW ; Row has to count up instead of down because we use it to set the lcd row

rowloop0:
    ; Set the LCD page number and prepare some variables 
    clr    NON_BLANK_COUNT ; Using NON_BLANK_COUNT to keep track of if the row is completely blank
    SET_PAGE  ROW,CHIPNO

colloop0:
    sbrc    REMAINING_BLANK,0 ; If remaining_blank == 1, go straight to display_zero0
    rjmp    display_zero0

    ld      DATAR,-Z          ; Load data from pointer location and decrement

#ifdef LOGSCALE
    ldi    XL,lo8((display_log_table))
    ldi    XH,hi8((display_log_table))

    add    XL,DATAR
    adc    XH,ZERO

    lpm    DATAR,X
#endif

    cpi    DATAR,0x00
    breq   display_zero0

    cpi    DATAR,0x08
    brlo   display_datamiddle0

display_datahigh0:
    ldi    NON_BLANK_COUNT,0x01 ; inc non-zero display_data count since this row will not be blank

    subi   DATAR,0x08
    ldi    DISPLAY_DATA,0xff
    rjmp   printdata0


display_datamiddle0:
    
    ldi    XL,lo8((bar_lookup-1)) ; Load pointer to partial bar display data table
    ldi    XH,hi8((bar_lookup-1))

    add    XL,DATAR               ; increment pointer by the appropriate amount
    adc    XH,ZERO
    
    clr    DATAR

    ld     DISPLAY_DATA,X         ; load value from the table
    ldi    NON_BLANK_COUNT,0x01   ; inc non-zero display_data count since this row will not be blank
    rjmp   printdata0

display_zero0:
    clr    DISPLAY_DATA           ; display_data is 0x00

printdata0:
    st     Z,DATAR

    PRINT_DATA CHIPNO

    dec    COL      ; decrement the col number
    breq   endcol0  ; test if zero

    rjmp   colloop0 ; go back to start of loop for col

endcol0:
    inc    ROW
   
    ; check if ROW is maxed out
    cpi    ROW,NUM_ROWS           
    breq   endlcd0

    ; Check to see if the entire row was blank
    sbrs   NON_BLANK_COUNT,0
    ldi    REMAINING_BLANK,0x01

nonzero0:
    rjmp   rowloop0

endlcd0:
    ; Move the pointer to the middle of the data
    subi   r24,64                  
    sbci   r25,0

    ; If we just finished CHIP2, jump to the end
    cpi    CHIPNO,CHIP2
    breq    endlcd1

    ; Set to CHIP2 and start over
    ldi    CHIPNO,CHIP2
    rjmp    displaystart

endlcd1:
    ; cleanup
    pop    CHIPNO
    pop    ZH
    pop    ZL
    pop    YH
    pop    YL
    pop    XH
    pop    XL
    pop    REMAINING_BLANK
    pop    TEMPR2
    pop    DISPLAY_DATA
    pop    ROW
    pop    COL    
    pop    DATAR
    pop    TEMPR
    ret
.endfunc
