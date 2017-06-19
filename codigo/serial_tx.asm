.include "m328def.inc"

.equ Fosc = 16000000				; clock
.equ Baud = 38400					; baud
.equ UBRR = (Fosc/(Baud*16))-1	

.def dato = r20

.MACRO DATA_TX
CHECK:			
; Wait for empty transmit buffer
	lds r16,UCSR0A 

	sbrs r16,UDRE0

	rjmp CHECK
	
	sts UDR0,@0 ; Put data (r16) into buffer, sends the data
	
.ENDMACRO

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
MAIN_LOOP:

	ldi dato,10
			
	RCALL SERIAL_TX ;dato;antes de llamar esta funcion cargo el valor a enviar en el registro "dato"
	;DATA_TX dato
	rcall DELAY_50MS

	ldi dato,5
			
	RCALL SERIAL_TX ;dato;antes de llamar esta funcion cargo el valor a enviar en el registro "dato"
	;DATA_TX dato
	rcall DELAY_50MS

	ldi dato,15

	RCALL SERIAL_TX ;dato;antes de llamar esta funcion cargo el valor a enviar en el registro "dato"
	;DATA_TX dato
	rcall DELAY_50MS

	rjmp MAIN_LOOP

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SERIAL_TX:
RETRY:			
; Wait for empty transmit buffer
	lds r16,UCSR0A 

	sbrs r16,UDRE0

	rjmp RETRY
	
	sts UDR0,dato ; Put data (r16) into buffer, sends the data
SERIAL_TX_END: ret	


DELAY_5MS:
	
	      ldi  R17, $86
WGLOOP0:  ldi  R18, $C6
WGLOOP1:  dec  R18
          brne WGLOOP1
          dec  R17
          brne WGLOOP0
; ----------------------------- 
; delaying 2 cycles:
          nop
          nop
END_DELAY_5MS: RET

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
