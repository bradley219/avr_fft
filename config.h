#ifndef _CONFIG_H_
#define _CONFIG_H_

// Backlight stuff
#define BACKLIGHT_FADE_SPEED 2 // higher values = slower fade rate
#define BACKLIGHT_TIMEOUT 1000
#define BACKLIGHT_CUTOFF 7
#define BACKLIGHT_BAR 127

#define FALL_SPEED 15

//#define DISPLAY_TEST_PATTERN

#define FFT_N	256		/* Number of samples (64,128,256,512). Don't forget to clean! */

/* Exponential display averaging */
#define AVG_SAMPLES 2 // best speeds are achieved with powers of 2 

/* Analog signal pre-processing */
#define SPI_PRESCALE 64
#define POT_GAIN 255
#define POT_BIAS 128

/* Low pass filter */
#define LPF_OCR 10

/* ADC Params */
#define ADC_PRESCALE 32 /* AVR ADC prescale value */
#define OVERSAMPS 8 /* Artificial oversampling in software */

/* Overall sampling rate will be F_CPU / (ADC_PRESCALE * OVERSAMPS * 13.5) 
 * see data.xlsx */

/* Triggering */
#define TRIGGERVAL 512 /* ADC trigger value */
#define TRIGGER_MARGIN 30 /* ADC trigger value fuzziness */

/* Timers */
#define TIMER0_PRESCALE 1024
#define TIMER1_PRESCALE 1
#define TIMER2_PRESCALE 1

#endif
