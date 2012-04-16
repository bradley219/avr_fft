#include <avr/io.h> 
#include "config.h"

#if AVG_SAMPLES == 4
#define DIV8_ROUTINE
#endif

; Exponential averaging function
#define 	ZERO					r1
#define  LOOP_COUNT			r18
#define  BUF_TEMP				r19
#define  AVG_TEMP				r20
#define  MUL1					r21
#define  MUL2					r22

#ifdef DIV8_ROUTINE

#define	DIV8_TEMPR1			r24
#define	DIV8_RESULT			r25

.macro DIV8 val1,val2
	ldi	DIV8_RESULT,0x01
	clr	DIV8_TEMPR1
1:
	clc
	rol	\val1
	rol	DIV8_TEMPR1
	brcs	2f
	cp		DIV8_TEMPR1,\val2
	brcs	3f
2:
	sub	DIV8_TEMPR1,\val2
	sec
	rjmp	4f
3:
	clc
4:
	rol	DIV8_RESULT
	brcc 	1b
.endm

#endif

.global exp_average
.func exp_average
exp_average: 

	; main buffer in r24:r25
	mov	XL,r24
	mov	XH,r25

	; history buffer in r22:r23
	mov 	ZL,r22
	mov	ZH,r23

#ifdef DIV8_ROUTINE
	ldi	MUL1,(AVG_SAMPLES-1)
	ldi	MUL2,AVG_SAMPLES
#else
	ldi	MUL1,3
#endif

	; Load count
	ldi	LOOP_COUNT,FFT_N/2

exp_avg_loop:
	; uint8_t tmp = aspektrum[i] * (AVG_SAMPLES-1);
	; tmp /= AVG_SAMPLES;
	ld		AVG_TEMP,Z

#ifdef DIV8_ROUTINE
	mul	AVG_TEMP,MUL1
	mov	AVG_TEMP,r0
	DIV8	AVG_TEMP,MUL2
	mov	AVG_TEMP,DIV8_RESULT
#else
	mul	AVG_TEMP,MUL1
	mov	AVG_TEMP,r0
	mov	MUL2,r1

#if AVG_SAMPLES >= 16
	lsr	MUL2
	ror	AVG_TEMP
#endif
#if AVG_SAMPLES >= 8
	lsr	MUL2
	ror	AVG_TEMP
#endif
#if AVG_SAMPLES >= 4
	lsr	MUL2
	ror	AVG_TEMP
#endif
#if AVG_SAMPLES >= 2
	lsr	MUL2
	ror	AVG_TEMP
#endif

#endif

	; aspektrum[i] = spektrum[i] / AVG_SAMPLES + tmp;
	ld		BUF_TEMP,X

#ifdef DIV8_ROUTINE
	DIV8	BUF_TEMP,MUL2
	mov	BUF_TEMP,r0
	add	AVG_TEMP,DIV8_RESULT
#else

#if AVG_SAMPLES >= 16
	lsr	BUF_TEMP
#endif
#if AVG_SAMPLES >= 8
	lsr	BUF_TEMP
#endif
#if AVG_SAMPLES >= 4
	lsr	BUF_TEMP
#endif
#if AVG_SAMPLES >= 2
	lsr	BUF_TEMP
#endif

	add	AVG_TEMP,BUF_TEMP
#endif

	st		Z+,AVG_TEMP
	; spektrum[i] = aspektrum[i];
	st		X+,AVG_TEMP

	dec	LOOP_COUNT
	brne	exp_avg_loop

	ret
.endfunc
