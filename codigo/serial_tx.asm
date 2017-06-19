.include "m328def.inc"

.equ Fosc = 16000000				; clock
.equ Baud = 38400					; baud
.equ UBRR = (Fosc/(Baud*16))-1	

.def dato = r18

.cseg

MAIN:
;%%%%%%%%%%%%%%%% STACK POINTER INIT %%%%%%%%%%%%%%%%%%%%%

	ldi r21,LOW(RAMEND)
	OUT SPL,r21
	ldi r21,HIGH(RAMEND)
	OUT SPH,r21
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;%%%%%%%%%%%%%%%% UART INIT %%%%%%%%%%%%%%%%%%%%%
; inicializo la UART para transmitir datos de 8 bits 

	ldi r16,(1<<TXEN0) 
	sts UCSR0B,r16 

	ldi r16, (3<<UCSZ00)	; set Format Frame 8bit 1bit de stop.
	sts UCSR0C, r16

; set baud rate
	ldi r16,HIGH(UBRR)			;set baud rate (38400bds / 16MHz)
	sts UBRR0H,r16
	ldi r16,low(UBRR)
	sts UBRR0L,r16

	
	 ;cargo el dato a transmitir
DATA_SEND_LOOP:
	ldi dato,240
			
; Wait for empty transmit buffer
	lds r16,UCSR0A 

	sbrs r16,UDRE0

	rjmp DATA_SEND_LOOP
	
	sts UDR0,dato ; Put data (r16) into buffer, sends the data
	
	call DELAY_50MS
	
	rjmp DATA_SEND_LOOP


DELAY_50MS:
		      ldi  R17, $5F
	WGLOOP6:  ldi  R18, $17
	WGLOOP7:  ldi  R19, $79
	WGLOOP8:  dec  R19
	          brne WGLOOP8
	          dec  R18
	          brne WGLOOP7
	          dec  R17
	          brne WGLOOP6
	; ----------------------------- 
	; delaying 3 cycles:
	          ldi  R17, $01
	WGLOOP9:  dec  R17
	          brne WGLOOP9
	; ----------------------------- 
	; delaying 2 cycles:
	          nop
	          nop
END_DELAY_50MS: RET
