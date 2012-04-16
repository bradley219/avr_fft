#include <avr/io.h> 
#include "ports.h"
#include "config.h"

; ADC interrupt routine

#define	BH			r18
#define	BL			r19
#define	AH			r20
#define	AL			r21

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
	
	clr  	r1

	; Load ADCL and ADCH into A
	lds	AL,120
	lds	AH,121
	lds	YL,capPtr
	lds	YH,capPtr+1
	cpi	YL,lo8((capture))
	brne	carryon

	ldi	BL,lo8(TRIGGERVAL)
	ldi	BH,hi8(TRIGGERVAL)
	cp		AL,BL
	cpc	AH,BH
	brlo	tlow

	; Add margin 
	subi	BL,-TRIGGER_MARGIN
	sbci	BH,-1
	cp		AL,BL
	cpc	AH,BH
	brsh	pushlast ; get out if higher 
	lds	BL,last_sample
	lds	BH,last_sample+1
	cp		AL,BL
	cpc	AH,BH
	brsh	pushlast ; get out if rising
	rjmp	carryon

tlow: 
	subi	BL,TRIGGER_MARGIN
	sbci	BH,0
	cp		AL,BL
	cpc	AH,BH
	brlo	pushlast ; get out if lower
	
	lds	BL,last_sample
	lds	BH,last_sample+1
	cp		AL,BL
	cpc	AH,BH
	brlo	pushlast ; get out if falling
	
carryon: 
	lds	BL,sampleaccum
	lds	BH,sampleaccum+1
	add	AL,BL
	add	AH,BH
	sts	sampleaccum,AL
	sts	sampleaccum+1,AH

	lds	BL,osamp_count
	dec	BL
	breq	process_samp

	sts	osamp_count,BL
	rjmp	__end_vect21 	; exit

process_samp: 
	ldi	BL,OVERSAMPS+1
	sts	osamp_count,BL
	sts	sampleaccum,r1
	sts	sampleaccum+1,r1

	st		Y+,AL
	st		Y+,AH
	sts	capPtr,YL
	sts	capPtr+1,YH

	subi	YL,lo8(capture+512)
	sbci	YH,hi8(capture+512)
	brne	__end_vect21 

	ldi	AL,lo8(capture)
	ldi	AH,hi8(capture)
	sts	capPtr+1,AH
	sts	capPtr,AL

	rjmp	__end_vect21

pushlast: 
	sts	last_sample,AL
	sts	last_sample+1,AH

__end_vect21: 
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
