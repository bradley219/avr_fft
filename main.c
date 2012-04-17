#ifndef _MAIN_SOURCE_
#define _MAIN_SOURCE_

#include "main.h"

/* Macros */
#define DATA_PORT_IS_INPUT() DATA_DDR = 0x00; DATA_PORT = 0xff;
#define DATA_PORT_IS_OUTPUT( MYDATA ) DATA_PORT = MYDATA; DATA_DDR = 0xff

#define STROBE() \
	asm volatile( "nop\n\t" ); \
	CONTROL_PORT |= _BV(EN); \
	CONTROL_PORT &= _BV(EN)

#define pot_set_gain( a ) pot_write_register( POT_REG_WIPER0, a )
#define pot_set_bias( a ) pot_write_register( POT_REG_WIPER1, a )

#define CS_HIGH() SPI_CS_PORT |= _BV(SPI_CS); SPI_REAL_CS_PORT |= _BV(SPI_REAL_CS)
#define CS_LOW() SPI_CS_PORT &= ~_BV(SPI_CS); SPI_REAL_CS_PORT &= ~_BV(SPI_REAL_CS); asm volatile( "nop\n" )

/**
 * ADC globals (needed by adc.S)
 */
int16_t capture[FFT_N];
volatile uint16_t sampleaccum = 0;
volatile uint8_t  osamp_count = 0;
volatile uint16_t last_sample = 0;

volatile int16_t *capPtr = capture;;
volatile prog_int16_t *adc_window = tbl_window;

/* Needed by lcd.S */
volatile uint8_t bar_lookup[] = { 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f };

/* FFT buffer */
complex_t bfly[FFT_N];

/* Spectrum output buffer */
uint8_t spectrum[FFT_N/2];
uint8_t spectrum_history[FFT_N/2];

int main(void)
{

	init();

	pot_set_gain( POT_GAIN );
	pot_set_bias( POT_BIAS );

	spi_deinit(); // disable spi unless we plan to adjust the digital pot later

	while(1)
	{
		// Apply window function and store in butterfly array
		fft_input( capture, bfly );

		// Execute forier transform
		fft_execute( bfly );

		// Bit reversal algorithm from butterfly array to output array
		fft_output( bfly, spectrum );
	
		// Do exponential/FIR filtering with history data
		exp_average( spectrum, spectrum_history );

		// Don't bother printing to lcd if the backlight isn't on
		if( backlight_timeout_task( spectrum[BACKLIGHT_BAR], BACKLIGHT_CUTOFF ) )
		{
			// Print resulting data to LCD 
			fastlcd( spectrum );
		}

	}
	return 0;
}

int backlight_timeout_task( uint8_t bar, uint8_t cutoff )
{
	static uint8_t backlight_state = 1;
	static unsigned long quiet_count = 0;

	uint8_t bl = backlight_state;
	if( bar < cutoff )
	{
		if( quiet_count >= BACKLIGHT_TIMEOUT )
		{
			bl = 0;
		}
		else
		{
			quiet_count++;
		}
	}
	else
	{
		bl = 1;
		quiet_count = 0;
	}

	if( bl != backlight_state )
	{
		if( bl )
		{
			lcd_init( CHIP1 );
			lcd_init( CHIP2 );
			backlight_task(LPF_OCR+1); // Fade up to full brightness
		}
		else
		{
			lcd_deinit( CHIP1 );
			lcd_deinit( CHIP2 );
			backlight_task(0);
		}

		backlight_state = bl;
	}
	else
	{
		backlight_task(-1);
	}
	return (backlight_state) ? 1 : 0;
}

void init(void)
{
	lpf_init(); // init low-pass filter
	backlight_init(); // init backlight

	io_init(); // init i/o for lcd

	// initialize each lcd driver chip
	lcd_init(CHIP1);
	lcd_init(CHIP2);

#ifdef DISPLAY_TEST_PATTERN
	// Display test pattern for a few seconds to allow contrast adjustment
	set_bl(0xffff); // backlight on full immediately
	lcd_set_screen( 0xf0 ); // print test pattern
	_delay_ms(1000); // delay
	set_bl(0); // backlight off immediately
#endif
	
	adc_init(); // Analog-to-digital converter init	
	spi_init(); // Serial interface to digital potentiometer init

	backlight_task(LPF_OCR+1); // Fade up to full brightness
	
	sei(); // enable interrupts

	return;
}
void adc_init(void)
{
	ADMUX = _BV(REFS0); // reference is AVcc with external cap 

	ADCSRB = 0;

	ADCSRA = _BV(ADEN) | _BV(ADATE) | _BV(ADIE) | ADC_PRESCALE_BITS;
	
	ADCSRA |= _BV(ADSC); // start first conversion
	
	return;
}
void lpf_init(void)
{
	/* ~2.2MHz output (with 16Mhz crystal) on OC1A */
	OCR1A  = LPF_OCR;
	TCCR1A = _BV(COM1A0) | _BV(WGM10) | _BV(WGM11);
	TCCR1B = _BV(WGM12) | _BV(WGM13) | _BV(CS10);

	LPF_OUTPUT_DDR |= _BV(LPF_OUTPUT);

	return;
}
void io_init(void)
{
	// LCD PORTs
	CSEL1_PORT &= ~_BV(CSEL1);
	CSEL2_PORT &= ~_BV(CSEL2);
	RW_PORT &= ~_BV(RW);
	EN_PORT &= ~_BV(EN);
	DI_PORT &= ~_BV(DI);

	// LCD DDRs
	CSEL1_DDR |= _BV(CSEL1);
	CSEL2_DDR |= _BV(CSEL2);
	RW_DDR |= _BV(RW);
	EN_DDR |= _BV(EN);
	DI_DDR |= _BV(DI);

	return;
}
void backlight_init(void)
{

	// Timer 1 is already used for LPF's 2.2MHz input; init just in case it isn't called elsewhere
	lpf_init();

	set_bl(0); // start with backlight off
	TCCR1A |= _BV(COM1B1); // add output compare to the timer's config

	return;
}
void set_bl( uint16_t val ) // set backlight to val between 0 and OCR1A
{
	if( val == 0 )
	{
		BACKLIGHT_DDR &= ~_BV(BACKLIGHT);
		OCR1B = 0;
	}
	else
	{
		BACKLIGHT_DDR |= _BV(BACKLIGHT);
		OCR1B = val;
	}


	return;
}
void backlight_task( int val )
{
	static uint16_t current_val = 0;
	static uint16_t target_val = 0;
	static unsigned call_counter = 0;

	if( val >= 0 ) // if val is non-negative, we're changing the target value
	{
		target_val = val;
		call_counter = 0;
	}
	if( current_val != target_val )
	{
		if( call_counter++ >= BACKLIGHT_FADE_SPEED )
		{
			current_val += (target_val>current_val) ? 1 : -1;
			set_bl(current_val);
			call_counter = 0;
		}
	}
	return;
}
void lcd_init( uint8_t chip )
{
	_delay_ms(10);
	lcd_write_instruction( LCD_ON, chip );
	lcd_write_instruction( LCD_START_LINE | 0, chip );
	lcd_write_instruction( LCD_ADDR | 0, chip );
	return;
}
void lcd_deinit( uint8_t chip )
{
	_delay_ms(10);
	lcd_write_instruction( LCD_OFF, chip );
	return;
}
void lcd_wait_ready( uint8_t chip )
{
	CONTROL_PORT = chip | _BV(RW);

	DATA_PORT_IS_INPUT(); // release control of pins

	CONTROL_PORT = chip | _BV(RW) | _BV(EN);

	asm volatile( "nop\n\tnop\n\tnop\n\t" ); // 100 ns

	while( DATA_PIN & LCD_STATUS_BUSY ); // wait for bit to go low

	CONTROL_PORT = chip | _BV(RW) | _BV(EN);
	
	return;
}
uint8_t lcd_read_data( uint8_t chip )
{
	lcd_wait_ready(chip);

	CONTROL_PORT = chip | _BV(DI) | _BV(RW);
	
	DATA_PORT_IS_INPUT(); // prob not necessary

	CONTROL_PORT = chip | _BV(DI) | _BV(RW) | _BV(EN);

	asm volatile( "nop\n\tnop\n\tnop\n\t" ); // 100 ns
	uint8_t data = DATA_PIN;

	CONTROL_PORT = chip | _BV(DI) | _BV(RW);

	return data;
}
void lcd_write_data( uint8_t data, uint8_t chip )
{
	lcd_wait_ready(chip);

	CONTROL_PORT = chip | _BV(DI);
	
	DATA_PORT_IS_OUTPUT(data);

	STROBE();
	return;
}
void lcd_write_instruction( uint8_t data, uint8_t chip )
{
	lcd_wait_ready(chip);

	CONTROL_PORT = chip;

	DATA_PORT_IS_OUTPUT(data);

	STROBE();
	return;
}
void lcd_set_chip( uint8_t chip, uint8_t data )
{
	for( uint8_t page = 0; page <= 7; page++ )
	{
		lcd_write_instruction( LCD_PAGE | page, chip );

		for( uint8_t addr = 0; addr < 64; addr++ )
		{
			lcd_write_data( data, chip );
		}
	}
	lcd_write_instruction( LCD_START_LINE | 0, chip );
	return;
}
void lcd_set_screen( uint8_t data )
{
	lcd_set_chip( CHIP1, data );
	lcd_set_chip( CHIP2, data );
	return;
}

void spi_init(void) // SPI Setup
{

	SPI_REAL_CS_PORT 	|= _BV(SPI_REAL_CS);
	SPI_CS_PORT 		|= _BV(SPI_CS);

	SPI_REAL_CS_DDR 	|=  _BV(SPI_REAL_CS);
	SPI_CS_DDR 			|=  _BV(SPI_CS);
	MISO_DDR   &= ~_BV(MISO);
	MISO_PORT  |=  _BV(MISO); // pullup
	
	MOSI_DDR   |=  _BV(MOSI);
	SCK_DDR    |=  _BV(SCK);


	SPCR = _BV(MSTR) | _BV(SPE) | _BV(CPOL) | _BV(CPHA);

#if SPI_PRESCALE == 2
	SPSR |= _BV(SPI2X);
#elif SPI_PRESCALE == 4
#elif SPI_PRESCALE == 8
	SPSR |= _BV(SPI2X);
	SPCR |= _BV(SPR0);
#elif SPI_PRESCALE == 16
	SPCR |= _BV(SPR0);
#elif SPI_PRESCALE == 32
	SPSR |= _BV(SPI2X);
	SPCR |= _BV(SPR1);
#elif SPI_PRESCALE == 64
	SPCR |= _BV(SPR1);
#elif SPI_PRESCALE == 128
	SPCR |= _BV(SPR1) | _BV(SPR0);
#else
#error "SPI_PRESCALE is not valid"
#endif

	uint8_t clr;
	clr = SPDR;
	clr = SPDR;

	return;
}
void spi_deinit(void) // SPI Setup
{

	SPI_CS_PORT 		&= ~_BV(SPI_CS);
	
	MISO_DDR   |= _BV(MISO);
	
	MISO_PORT  &= ~_BV(MISO); 
	MOSI_PORT  &= ~_BV(MOSI);
	SCK_PORT   &= ~_BV(SCK);

	SPCR = 0;

	return;
}
uint8_t spi_swap( uint8_t send )
{
	uint8_t recv;
	
	if( SPSR & (_BV(SPIF) | _BV(WCOL)) )
		recv = SPDR;

	SPDR = send;

	while( !(SPSR & (_BV(SPIF) | _BV(WCOL))) );

	recv = SPDR;

	return recv;
}
uint16_t pot_16_bit_cmd( uint8_t address, uint8_t command, uint16_t data )
{
	uint8_t cmd_high,cmd_low;
	uint16_t recv;

	cmd_high = 0;
	cmd_high |= (address & 0xf) << 4;
	cmd_high |= (command & 0x3) << 2;
	cmd_high |= (data & 0x100) >> 8;

	cmd_low = data & 0xff;

	CS_LOW();

	recv  = spi_swap(cmd_high) << 8;
	recv |= spi_swap(cmd_low);
	
	CS_HIGH();

	return recv;
}
void pot_write_register( uint8_t address, uint16_t data )
{
	uint16_t recv;

	recv = pot_16_bit_cmd( address, POT_WRITE_DATA, data );

	return;
}
uint16_t pot_read_register( uint8_t address )
{
	uint16_t recv;

	recv = pot_16_bit_cmd( address, POT_READ_DATA, 0x55 );

	return recv;
}
uint16_t pot_inc_register( uint8_t address )
{
	uint16_t recv;

	recv = pot_16_bit_cmd( address, POT_INC, 0x00 );

	return recv;
}
uint16_t pot_dec_register( uint8_t address )
{
	uint16_t recv;

	recv = pot_16_bit_cmd( address, POT_INC, 0x00 );

	return recv;
}
#endif
