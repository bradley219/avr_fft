AVR FFT
=======

Summary
-------
Real-time audio spectrum analyzer using a 16-bit fast fourier transform implmented on an 8-bit AVR ATmega328P running at 20MHz. Analog signal is preprocessed and amplified by a MAX293 low-pass filter. Audio is sampled at 40.3kHz by the AVR's built-in 10-bit analog-to-digital converter. Data is processed by a Cooley-Tukey FFT algorithm, which is then visualized as 128 discrete frequency levels on a KS0108-driven LCD display.

Two video demos below:

* [Demo 1](https://www.youtube.com/watch?v=WKGsNnFIzcc&t=2s)
* [Demo 2](https://www.youtube.com/watch?v=HTRjjKfaV00&t=146s)

Schematic
---------
![](https://raw.github.com/bradley219/avr_fft/master/schematic/schematic.png)
