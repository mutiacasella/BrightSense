#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main
.global INT0_vect

;================================================================

main:
  ; Initsialisasi Stack Pointer ++++++++++++++++++++
  LDI R16, hi8(RAMEND)
  OUT SPH, R16
  LDI R16, lo8(RAMEND)
  OUT SPL, R16 ;++++++++++++++++++++

  ; Setup register untuk LED mode manual
  CLR R15
  CLR R19

  ; Setup I/O
  CBI DDRC, 2        ; PC2 (input) - LDR2
  CBI DDRC, 3        ; PC3 (input) - LDR1
  CBI DDRC, 4        ; PC4 (input) - LDR3
  SBI DDRB, 1        ; PB1 (output) - LED (OC1A)
  CBI DDRD, 2        ; PD2 (input) - button (INT0)
  SBI PORTD, 2       ; pull up input
  CBI DDRD, 3        ; PD3 (input) - button decrement
  SBI PORTD, 3       ; pull up input
  CBI DDRD, 4        ; PD4 (input) - button increment
  SBI PORTD, 4       ; pull up input

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

  ; Setup INT0 (interrupt external pada PD2)
  LDI R16, (1 << ISC01)
  STS EICRA, R16
  LDI R16, (1<<INT0)                ; enable INT0
  STS EIMSK, R16
  SEI                               ; global interrupt enable

;================================================================

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

  ; Rata-rata pembacaan LDR (16 bit)
  CLR R17            ; high byte
  MOV R16, R21       ; LDR2
  ADD R16, R20       ; LDR1 + LDR2
  ADC R17, R1        ; carry ke high byte
  ADD R16, R22       ; (LDR1 + LDR2) + LDR3
  ADC R17, R1        ; carry ke high byte

  LDI R25, 0         ; high byte pembagi
  LDI R24, 3         ; low byte pembagi

  RCALL div_16bit
  MOV R23, R18       ; simpan hasil ke R23 (low byte hasil)

  ; Kirim ke USART
  RCALL print_3digit_decimal

  ; Atur PWM
  LDI R18, 255
  SUB R18, R23
  STS OCR1A, R18

  LDI R21, 3          ; memberikan delay 1000 ms (1 detik)
  LDI R22, 232        ; R21 & R22 (3*256 + 232 = 1000)
  RCALL timer0_delay_ms
  CPI R19, 0
  BREQ main_loop
  RJMP manual_loop

;================================================================

manual_loop:
  SBIC  PIND, 4       ; skip line berikutnya jika tombol tidak ditekan
  DEC   R15
  SBIC  PIND, 3       ; skip line berikutnya jika tombol tidak ditekan
  INC   R15
  
  ; Atur PWM
  STS OCR1A, R15

  CP R23, R15
  BREQ manual_loop_skip_print
  MOV R23, R15        ; simpan hasil ke R23

  ; Kirim ke USART
  RCALL print_3digit_decimal

manual_loop_skip_print:
  CLR R21             ; memberikan delay 10ms 
  LDI R22, 10
  RCALL timer0_delay_ms
  CPI R19, 1
  BREQ manual_loop
  RJMP main_loop

;================================================================

; Subroutines
start_adc:
  LDI R16, 0xC6       ; start conversion, enable ADC, prescaler 64
  STS ADCSRA, R16
wait_adc:
  LDS R17, ADCSRA
  SBRS R17, 4         ; tunggu sampai ADIF flag set
  RJMP wait_adc
  LDI R18, 0xD6       ; clear ADIF flag
  STS ADCSRA, R18
  RET

;================================================================

; Pembagian unsigned 16 bit -> (R17:R16) ÷ (R25:R24) = R19:R18, sisa = R21:R20
div_16bit:
  CLR R19        ; clear high byte hasil
  CLR R18        ; clear low byte hasil
  CLR R21        ; clear high byte sisa
  CLR R20        ; clear low byte sisa
  LDI R22, 16    ; 16 bit loop

div_16bit_loop:
  ; Shift dividend (R17:R16)
  LSL R16
  ROL R17

  ; Shift remainder (R21:R20)
  ROL R20
  ROL R21

  ; Simpan sementara remainder untuk restore
  MOV R23, R21
  MOV R26, R20

  ; Kurangkan remainder dengan divisor
  SUB R20, R24
  SBC R21, R25

  BRCS div_16bit_skip

  ; Jika tidak carry, simpan hasil
  MOV R23, R21
  MOV R26, R20
  LSL R18
  ROL R19
  INC R18
  RJMP div_16bit_next

div_16bit_skip:
  ; Jika carry (kurang dari 0), restore
  MOV R21, R23
  MOV R20, R26
  LSL R18
  ROL R19

div_16bit_next:
  DEC R22
  BRNE div_16bit_loop
  RET

;================================================================

; Print ke serial monitor
print_3digit_decimal:
  PUSH R16
  PUSH R17
  PUSH R18
  PUSH R19
  PUSH R20
  PUSH R21
  PUSH R23
  PUSH R24
  PUSH R25

  ; Inisialisasi R17:R16 dengan nilai R23 (0-255)
  CLR R17
  MOV R16, R23

  ; Digit ratusan: (R17:R16) ÷ 100
  LDI R25, 0
  LDI R24, 100
  RCALL div_16bit
  MOV R16, R18         ; hasil ke R16
  SUBI R16, -'0'       ; convert to ASCII
  RCALL usart_send

  ; Sisa di R21:R20
  MOV R17, R21
  MOV R16, R20

  ; Digit puluhan: sisa ÷ 10
  LDI R25, 0
  LDI R24, 10
  RCALL div_16bit
  MOV R16, R18
  SUBI R16, -'0'
  RCALL usart_send

  ; Sisa satuan: ambil R20 langsung
  MOV R16, R20
  SUBI R16, -'0'
  RCALL usart_send

  ; New line
  LDI R16, '\r'
  RCALL usart_send
  LDI R16, '\n'
  RCALL usart_send

  POP R25
  POP R24
  POP R23
  POP R21
  POP R20
  POP R19
  POP R18
  POP R17
  POP R16
  RET

usart_send:
wait_udre:
  LDS R17, UCSR0A
  SBRS R17, UDRE0    ; tunggu sampai UDR0 siap
  RJMP wait_udre
  STS UDR0, R16      ; kirim karakter
  RET

;================================================================

; Delay timer0 dengan menggunakan nilai 16-bit dari R21 & R22 sebagai nilai milidetik (ms)
timer0_delay_ms:
  INC R21
  INC R22
  LDI R20, 0x83
  OUT TCNT0, R20    ;load Timer0
  LDI R20,0x03
  OUT TCCR0B, R20   ;Timer0, Normal mode, int clk, prescaler 64
  RJMP timer0_delay_ms_l2
  
timer0_delay_ms_l1: 
  LDI R22, 255

timer0_delay_ms_l2: 
  IN R20, TIFR0     ;read TIFR
  SBRS R20, TOV0    ;if TOV0 is set skip next instruction
  RJMP timer0_delay_ms_l2
  LDI R20, (1 << TOV0)
  OUT TIFR0, R20
  DEC R22
  BRNE timer0_delay_ms_l2
  DEC R21
  BRNE timer0_delay_ms_l1

timer0_delay_ms_done:
  LDI R20,0x0
  OUT TCCR0B, R20   ;stop Timer0
  LDI R20,1<<TOV0
  RET

;================================================================

; Interrupt untuk switch mode otomatis <-> manual
INT0_vect:
  PUSH R16
  PUSH R17
  PUSH R18

  ; debounce (5-10 ms)
  LDI R17, 100

debounce_delay:
  NOP
  NOP
  DEC R17
  BRNE debounce_delay

  ; toggle mode flag
  LDI R16, 1
  EOR R19, R16

  POP R18
  POP R17
  POP R16
  RETI