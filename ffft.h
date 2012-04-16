#ifndef FFT_H
#include "config.h"

#ifndef FFFT_ASM	
typedef struct {
	int16_t	r;
	int16_t i;
} complex_t;
void fft_input (const int16_t *, complex_t *);
void fft_input2 (const int16_t *, complex_t *);
void fft_execute (complex_t *);
void fft_output (const complex_t *, uint8_t *);
int16_t fmuls_f (int16_t, int16_t);
extern volatile prog_int16_t tbl_window[];
#else				/* for asm module */
#define T0L	r0
#define T0H	r1
#define T2L	r2
#define T2H	r3
#define T4L	r4
#define T4H	r5
#define T6L	r6
#define T6H	r7
#define T8L	r8
#define T8H	r9
#define T10L	r10
#define T10H	r11
#define T12L	r12
#define T12H	r13
#define T14L	r14
#define T14H	r15
#define AL	r16
#define AH	r17
#define BL	r18
#define BH	r19
#define CL	r20
#define CH	r21
#define DL	r22
#define DH	r23
#define EL	r24
#define EH	r25
#define XL	r26
#define XH	r27
#define YL	r28
#define YH	r29
#define ZL	r30
#define ZH	r31

.macro	ldiw	dh,dl, abs
	ldi	\dl, lo8(\abs)
	ldi	\dh, hi8(\abs)
.endm

.macro	subiw	dh,dl, abs
	subi	\dl, lo8(\abs)
	sbci	\dh, hi8(\abs)
.endm

.macro	addw	dh,dl, sh,sl
	add	\dl, \sl
	adc	\dh, \sh
.endm

.macro	addd	d3,d2,d1,d0, s3,s2,s1,s0
	add	\d0, \s0
	adc	\d1, \s1
	adc	\d2, \s2
	adc	\d3, \s3
.endm

.macro	subw	dh,dl, sh,sl
	sub	\dl, \sl
	sbc	\dh, \sh
.endm

.macro	subd	d3,d2,d1,d0, s3,s2,s1,s0
	sub	\d0, \s0
	sbc	\d1, \s1
	sbc	\d2, \s2
	sbc	\d3, \s3
.endm

.macro	lddw	dh,dl, src
	ldd	\dl, \src
	ldd	\dh, \src+1
.endm

.macro	ldw	dh,dl, src
	ld	\dl, \src
	ld	\dh, \src
.endm

.macro	stw	dst, sh,sl
	st	\dst, \sl
	st	\dst, \sh
.endm

.macro	clrw	dh, dl
	clr	\dh
	clr	\dl
.endm

.macro	lsrw	dh, dl
	lsr	\dh
	ror	\dl
.endm

.macro	asrw	dh, dl
	asr	\dh
	ror	\dl
.endm

.macro	lslw	dh, dl
	lsl	\dl
	rol	\dh
.endm

.macro	pushw	dh, dl
	push	\dh
	push	\dl
.endm

.macro	popw	dh, dl
	pop	\dl
	pop	\dh
.endm

.macro	lpmw	dh,dl, src
	lpm	\dl, \src
	lpm	\dh, \src
.endm

.macro	rjne	lbl
	breq	99f
	rjmp	\lbl
99:
.endm
.macro	FMULS16	d3,d2,d1,d0 ,s1h,s1l, s2h,s2l	;Fractional Multiply (19clk)
	fmuls	\s1h, \s2h
	movw	\d2, T0L
	fmul	\s1l, \s2l
	movw	\d0, T0L
	adc	\d2, EH ;EH: zero reg.
	fmulsu	\s1h, \s2l
	sbc	\d3, EH
	add	\d1, T0L
	adc	\d2, T0H
	adc	\d3, EH
	fmulsu	\s2h, \s1l
	sbc	\d3, EH
	add	\d1, T0L
	adc	\d2, T0H
	adc	\d3, EH
.endm
#endif
#endif
