#include <avr/io.h> 
#include "ports.h"
#include "config.h"

; ADC interrupt routine

#define	BH			r18
#define	BL			r19
#define	AH			r20
#define	AL			r21
#define	TMP			r22

.global __vector_21
__vector_21:
	sei

	push	r1
	push	BH
	push	BL
	push	AH
	push	AL
	
	in		AL,_SFR_IO_ADDR(SREG)
	push	AL

	push	YH
	push	YL
#ifdef LOG_VALUES
	push	ZH
	push	ZL
#endif
	push	TMP
	
	clr  	r1

	; Load ADCL and ADCH into A
	lds	AL,120
	lds	AH,121
	
	;; Compare to raw trigger val minus something
	ldi	BL,lo8(SLEEP_TRIGGER)
	ldi	BH,hi8(SLEEP_TRIGGER)

	lds	YL,sleeping
	cpi	YL,0
	breq 1f
	
	;; If sleeping
	cp	AL,BL
	cpc	AH,BH
	brsh 2f 

	;; Wake up
	ldi BL,2
	sts	sleeping,BL
2:	
	rjmp __end_vect21

1:	;; If not sleeping
	;; Check against sleep trigger
	cp	AL,BL
	cpc	AH,BH
	brlo 3f ; if lower than trigger, go to 3:

	;; higher than trigger
	lds	YL,quiet_count ; load quiet count... 32-bit math!
	lds	YH,quiet_count+1
	lds	BL,quiet_count+2
	lds	BH,quiet_count+3

	;; increment count
	subi YL,-1
	sbci YH,-1
	sbci BL,-1
	sbci BH,-1

	;; store back
	sts quiet_count,YL
	sts quiet_count+1,YH
	sts quiet_count+2,BL
	sts quiet_count+3,BH

	;; ldi does not change any status register flags
	ldi	TMP,lo8(BACKLIGHT_TIMEOUT)
	cp	YL,TMP
	ldi	TMP,hi8(BACKLIGHT_TIMEOUT)
	cpc	YH,TMP
	ldi	TMP,lo8(BACKLIGHT_TIMEOUT>>16)
	cpc BL,TMP
	ldi	TMP,hi8(BACKLIGHT_TIMEOUT>>16)
	cpc	BH,TMP
	brlo 4f ; If not yet at the limit, continue

	; If at the limit, set sleeping to 3 to trigger sleep
	ldi BL,3
	sts sleeping,BL
	rjmp 3f

3:
	sts quiet_count,r1 ;; reset the quiet count
	sts quiet_count+1,r1
	sts quiet_count+2,r1
	sts quiet_count+3,r1
4:
	; Load pointer location
	lds	YL,capPtr
	lds	YH,capPtr+1

	; Check if pointer is at index 0
	cpi	YL,lo8((capture))
	brne	carryon

triggercheck:
	; We are at index 0, so we're waiting for a trigger
	; Check if value is trigger

	; load trigger value
	ldi	BL,lo8(TRIGGERVAL)
	ldi	BH,hi8(TRIGGERVAL)
	cp		AL,BL
	cpc	 	AH,BH
	brlo	trigger_low

trigger_high: ; sample is above trigger (same or higher)
	
	; Add margin to trigger value
	subi	BL,-TRIGGER_MARGIN
	sbci	BH,-1

	cp		AL,BL
	cpc		AH,BH
	brsh	push_last_sample ; get out if higher 

	; Load last_sample
	lds	BL,last_sample
	lds	BH,last_sample+1

	cp		AL,BL
	cpc		AH,BH
	brsh	push_last_sample ; get out if rising

	rjmp	carryon

trigger_low: ; sample is below trigger
	; Subtract margin from trigger value
	subi	BL,TRIGGER_MARGIN
	sbci	BH,0

	cp		AL,BL
	cpc	AH,BH
	brlo	push_last_sample ; get out if lower
	
	; Load last_sample
	lds	BL,last_sample
	lds	BH,last_sample+1

	cp		AL,BL
	cpc	    AH,BH
	brlo	push_last_sample ; get out if falling

	sts	missed_triggers,r1
	sts	missed_triggers+1,r1
	; If we've made it this far, trigger is ready
	rjmp carryon
	
push_last_sample: 
	lds	BL,missed_triggers
	lds	BH,missed_triggers+1
	subi BL,-1
	sbci BH,-1
	sts	missed_triggers,BL
	sts	missed_triggers+1,BH

	; Move A into last_sample
	sts	last_sample,AL
	sts	last_sample+1,AH
	rjmp __end_vect21

carryon: ; If pointer is not at index 0
#if OVERSAMPS > 1
	; Add sample to accumulator
	lds	BL,sampleaccum
	lds	BH,sampleaccum+1

	add	AL,BL
	add	AH,BH

	sts	sampleaccum,AL
	sts	sampleaccum+1,AH

	lds	BL,osamp_count
	dec	BL
	breq	process_data

	sts	osamp_count,BL
	rjmp	__end_vect21 	; exit

	
process_data:  ; If we have OVERSAMPS samples added

	; Reset osamp_count
	ldi	BL,OVERSAMPS+1
	sts	osamp_count,BL

	; Reset sampleaccum
	sts	sampleaccum,r1
	sts	sampleaccum+1,r1
#endif

storeval:

#ifdef LOG_VALUES
	;;; Lookup log value

	; Load table location
	ldi	ZH,hi8(adc_log_table)
	ldi	ZL,lo8(adc_log_table)

	; Increment pointer by A * 2
	add	ZL,AL
	adc	ZH,AH
	add	ZL,AL
	adc	ZH,AH

	; Load value
	lpm	AL,Z+
	lpm	AH,Z+

#endif

	; Store result and post-inc
	st		Y+,AL
	st		Y+,AH

	; Store new pointer value
	sts	capPtr,YL
	sts	capPtr+1,YH

	; Check for end of buffer
	subi	YL,lo8(capture+512)
	sbci	YH,hi8(capture+512)
	brne	__end_vect21 ; get out if not at the end yet

	; If at the end of buffer, reset capture and window pointers
	; reset capture pointer
	ldi	AL,lo8(capture)
	ldi	AH,hi8(capture)
	sts	capPtr+1,AH
	sts	capPtr,AL

	rjmp	__end_vect21


__end_vect21: ; get out

	pop	TMP
#ifdef LOG_VALUES
	pop	ZL
	pop	ZH
#endif
	pop	YL
	pop	YH

	pop	AL
	out	_SFR_IO_ADDR(SREG),AL
	
	pop	AL
	pop	AH
	pop	BL
	pop	BH
	
	pop	r1
	
	reti
