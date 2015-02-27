/*
 * Copyright 2015 Bradley J. Snyder <snyder.bradleyj@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef _MAIN_H_
#define _MAIN_H_

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <avr/io.h>
#include <avr/eeprom.h>
#include <stdio.h>
#include <util/delay.h> 
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#include "constants.h"	
#include "ffft.h"
#include "ports.h"
#include "config.h"
#include "prescales.h"
#include "avg.h"
#include "config.h"
#include "lcd.h"

void init(void);
void io_init(void);
void backlight_init(void);
void lcd_init( uint8_t chip );
void lcd_deinit( uint8_t chip );
void lcd_wait_ready( uint8_t chip );
void lcd_write_data( uint8_t data, uint8_t chip );
void lcd_write_instruction( uint8_t data, uint8_t chip );
void lcd_set_chip( uint8_t chip, uint8_t data );
void lcd_set_screen( uint8_t data );
void lpf_init(void);
void adc_init(void);
void set_bl( uint16_t val ); // set backlight to val between 0 and OCR1A
void backlight_task( int val );
int  backlight_timeout_task( uint8_t bar, uint8_t cutoff );
void spi_init(void); 
void spi_deinit(void); 
uint16_t pot_dec_register( uint8_t address );
uint16_t pot_inc_register( uint8_t address );
uint16_t pot_read_register( uint8_t address );
void pot_write_register( uint8_t address, uint16_t data );
uint16_t pot_16_bit_cmd( uint8_t address, uint8_t command, uint16_t data );
uint8_t spi_swap( uint8_t send );


#endif 
