#ifndef _PRESCALES_H_
#define _PRESCALES_H_

/* Prescales */
#if TIMER0_PRESCALE == 1024
#define TIMER0_PS_BITS ( _BV(CS02) | _BV(CS00) )
#elif TIMER0_PRESCALE == 256
#define TIMER0_PS_BITS ( _BV(CS02) )
#elif TIMER0_PRESCALE == 64
#define TIMER0_PS_BITS ( _BV(CS01) | _BV(CS00) )
#elif TIMER0_PRESCALE == 8
#define TIMER0_PS_BITS ( _BV(CS01) )
#elif TIMER0_PRESCALE == 1
#define TIMER0_PS_BITS ( _BV(CS00) )
#elif TIMER0_PRESCALE == 0
#define TIMER0_PS_BITS ( 0 )
#else 
#error "TIMER0_PRESCALE is invalid!"
#endif

#if TIMER1_PRESCALE == 1024
#define TIMER1_PS_BITS ( _BV(CS12) | _BV(CS10) )
#elif TIMER1_PRESCALE == 256
#define TIMER1_PS_BITS ( _BV(CS12) )
#elif TIMER1_PRESCALE == 64
#define TIMER1_PS_BITS ( _BV(CS11) | _BV(CS10) )
#elif TIMER1_PRESCALE == 8
#define TIMER1_PS_BITS ( _BV(CS11) )
#elif TIMER1_PRESCALE == 1
#define TIMER1_PS_BITS ( _BV(CS10) )
#elif TIMER1_PRESCALE == 0
#define TIMER1_PS_BITS ( 0 )
#else 
#error "TIMER1_PRESCALE is invalid!"
#endif

#if TIMER2_PRESCALE == 1024
#define TIMER2_PS_BITS ( _BV(CS22) | _BV(CS21) | _BV(CS20) )
#elif TIMER2_PRESCALE == 256
#define TIMER2_PS_BITS ( _BV(CS21) | _BV(CS22) )
#elif TIMER2_PRESCALE == 128
#define TIMER2_PS_BITS ( _BV(CS22) | _BV(CS20) )
#elif TIMER2_PRESCALE == 64
#define TIMER2_PS_BITS ( _BV(CS22) )
#elif TIMER2_PRESCALE == 32
#define TIMER2_PS_BITS ( _BV(CS21) | _BV(CS20) )
#elif TIMER2_PRESCALE == 8
#define TIMER2_PS_BITS ( _BV(CS21) )
#elif TIMER2_PRESCALE == 1
#define TIMER2_PS_BITS ( _BV(CS20) )
#elif TIMER2_PRESCALE == 1
#define TIMER2_PS_BITS ( 0 )
#else
#error "TIMER2_PRESCALE is invalid!"
#endif

#if ADC_PRESCALE == 128
#define ADC_PRESCALE_BITS (_BV(ADPS2) | _BV(ADPS1) | _BV(ADPS0))
#elif ADC_PRESCALE == 64
#define ADC_PRESCALE_BITS (_BV(ADPS2) | _BV(ADPS1))
#elif ADC_PRESCALE == 32
#define ADC_PRESCALE_BITS (_BV(ADPS2) | _BV(ADPS0))
#elif ADC_PRESCALE == 16
#define ADC_PRESCALE_BITS (_BV(ADPS2))
#elif ADC_PRESCALE == 8
#define ADC_PRESCALE_BITS (_BV(ADPS1) | _BV(ADPS0))
#elif ADC_PRESCALE == 4
#define ADC_PRESCALE_BITS (_BV(ADPS1))
#elif ADC_PRESCALE == 2
#define ADC_PRESCALE_BITS (_BV(ADPS0))
#else
#error "ADC prescale is invalid"
#endif

#endif
