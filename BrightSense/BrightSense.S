#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

main:
  ; Setup I/O
  CBI DDRC, 2        ; PC2 (input) - LDR2
  CBI DDRC, 3        ; PC3 (input) - LDR1
  CBI DDRC, 4        ; PC4 (input) - LDR3
  SBI DDRB, 1        ; PB1 (output) - LED (OC1A)

  ; Setup ADC
  LDI R16, 0x60      ; AVcc, left-justified
  STS ADMUX, R16
  LDI R16, 0x86      ; enable ADC, prescaler 64
  STS ADCSRA, R16

  ; Setup USART
  CLR R24
  STS UCSR0A, R24
  STS UBRR0H, R24
  LDI R24, 103       ; 9600 baud
  STS UBRR0L, R24
  LDI R24, (1<<TXEN0)
  STS UCSR0B, R24
  LDI R24, (1<<UCSZ01) | (1<<UCSZ00)
  STS UCSR0C, R24

  ; Setup PWM (Timer1)
  LDI R16, (1<<COM1A1) | (1<<WGM10)
  STS TCCR1A, R16
  LDI R16, (1<<WGM12) | (1<<CS11)    ; prescaler 8
  STS TCCR1B, R16

main_loop:
  ; Baca LDR (ADC2)
  LDI R16, 0x62      ; channel ADC2
  STS ADMUX, R16
  RCALL start_adc
  LDS R21, ADCH      ; simpan hasil di R21

  ; Baca LDR (ADC3)
  LDI R16, 0x63      ; channel ADC3
  STS ADMUX, R16
  RCALL start_adc
  LDS R20, ADCH      ; simpan hasil di R20

  ; Baca LDR (ADC4)
  LDI R16, 0x64      ; channel ADC4
  STS ADMUX, R16
  RCALL start_adc
  LDS R22, ADCH      ; simpan hasil di R22

  ; Rata-rata pembacaan LDR
  ADD R20, R21       ; R20 = LDR1 + LDR2
  ADD R20, R22       ; R20 = (LDR1 + LDR2) + LDR3
  LDI R24, 3         ; bagi 3
  MOV R16, R20
  RCALL div_8bit_unsigned
  MOV R23, R16       ; simpan hasil ke R23

  ; Kirim ke USART
  RCALL print_3digit_decimal

  ; Atur PWM
  LDI R18, 255
  SUB R18, R23
  STS OCR1A, R18

  RCALL delay
  RJMP main_loop

; Subroutines
start_adc:
  LDI R16, 0xC6      ; start conversion, enable ADC, prescaler 64
  STS ADCSRA, R16
wait_adc:
  LDS R17, ADCSRA
  SBRS R17, 4        ; tunggu sampai ADIF flag set
  RJMP wait_adc
  LDI R18, 0xD6      ; clear ADIF flag
  STS ADCSRA, R18
  RET

; Logika pembagian
div_8bit_unsigned:
  CLR R23            ; clear remainder
  LDI R25, 8         ; 8 iterations
div_loop:
  LSL R16            ; shift dividend
  ROL R23            ; shift remainder with carry
  CP R23, R24        ; compare remainder dengan divisor
  BRLO div_skip      ; skip jika remainder < divisor
  SUB R23, R24       ; reminder - divisor
  INC R16            ; set bit quotient 
div_skip:
  DEC R25
  BRNE div_loop
  RET

; Decimal (3 digit) printing
print_3digit_decimal:
  PUSH R16
  PUSH R23
  PUSH R24
  PUSH R25
  
  MOV R16, R23       ; salin nilai ke R16
  
  ; Digit ratusan
  LDI R24, 100
  RCALL div_8bit_unsigned
  SUBI R16, -'0'     ; convert to ASCII (R16 + 48)
  RCALL usart_send

  ; Digit puluhan
  MOV R16, R23       ; pindahkan nilai remainder
  LDI R24, 10
  RCALL div_8bit_unsigned
  SUBI R16, -'0'     ; convert to ASCII (R16 + 48)
  RCALL usart_send

  ; Digit satuan
  MOV R16, R23
  SUBI R16, -'0'     ; convert to ASCII (R16 + 48)
  RCALL usart_send

  ; New line
  LDI R16, '\r'
  RCALL usart_send
  LDI R16, '\n'
  RCALL usart_send

  POP R25
  POP R24
  POP R23
  POP R16
  RET

usart_send:
wait_udre:
  LDS R17, UCSR0A
  SBRS R17, UDRE0    ; tunggu sampai UDR0 siap
  RJMP wait_udre
  STS UDR0, R16      ; kirim karakter
  RET

delay:
  LDI R19, 50
delay_loop1:
  LDI R20, 255
delay_loop2:
  DEC R20
  BRNE delay_loop2
  DEC R19
  BRNE delay_loop1
  RET