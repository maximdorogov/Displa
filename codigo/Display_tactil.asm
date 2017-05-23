.include "m328def.inc"

.MACRO LOADIO
	
	ldi r16,@1
	out @0,r16

.ENDMACRO

.MACRO FILL_SCRN ;lleno la pantalla con un color, recibe como parametro un color en RGB565
	
	ldi c_high,HIGH(@0)
	ldi c_low,LOW(@0)
	cbi PORTC,B_CS
	;deberia ir clear_screen()
	sbi PORTC,B_RS
	;para llenar la pantalla necesito repetir un loop 76800 veces, para ello armo 2 loops 
	;uno de 65535 y otro de 11265
	;cargo 65535 en dos registros
	ldi r29,$ff 
	ldi r28,$ff 
	;cargo 11265 en dos registros
	ldi r25,$2c 
	ldi r24,$01
START_FILL_1:
	
	out PORTD,c_high
	cbi PORTC,B_WR
	sbi PORTC,B_WR
	OUT PORTD, c_low
	cbi PORTC,B_WR
	SBI PORTC,B_WR
	sbiw r29:r28,1
	brne START_FILL_1
;hasta aca ejecute la rutina 65535 veces, ahora hago un loop de 11265 para completar los 76800
	

START_FILL_2:
	
	out PORTD,c_high
	cbi PORTC,B_WR
	sbi PORTC,B_WR
	OUT PORTD, c_low
	cbi PORTC,B_WR
	SBI PORTC,B_WR

	sbiw r25:r24,1
	brne START_FILL_2

	sbi PORTC,B_CS
.ENDMACRO

.EQU B_RST = 2
.EQU B_CS = 3
.EQU B_WR = 4
.EQU B_RS = 5

.EQU NUM_COM_VALUES = 50 
.EQU NUM_DATA_VALUES = 50

.DEF com1 = r20
.DEF data = r22
.DEF counter = r21
.DEF c_high = r18
.DEF c_low = r17


.cseg

MAIN:
;%%%%%%%%%%%%%%%% STACK POINTER INIT %%%%%%%%%%%%%%%%%%%%%

	ldi r21,LOW(RAMEND)
	OUT SPL,r21
	ldi r21,HIGH(RAMEND)
	OUT SPH,r21

;%%%%%%%%%%%%%%%%%%%%%%%%%% CONFIG PORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	LOADIO DDRB, 0xff ;defino el puerto B como salida
	LOADIO DDRD, 0xff ; defino el puerto D como salida. Va a ser el puerto de escritura al display.
	LOADIO DDRC,0xff ; defino el PORTC como salida.Van a ser los bits de control del display.

;%%%%%%%%%%%%%%%%%%%INICIALIZO LOS PUERTOS A VALoROES SEGUROS%%%%%%%%%%%%
	LOADIO PORTC,0x38 ; inicializo el puerto en un valor seguro
	LOADIO PORTB,0x00
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	
	RCALL INIT_LCD

	nop
	nop

	FILL_SCRN $F800

ACA: RJMP ACA

	


INIT_LCD: 
	
	SBI PORTC,B_RST
	RCALL DELAY_5MS
	CBI PORTC,B_RST
	RCALL DELAY_15MS
	SBI PORTC,B_RST
	RCALL DELAY_15MS
	CBI PORTC,B_CS

	ldi Zl,low(INIT_COM_DATA_VALUES_ILI9325D<<1)
	ldi zh,HIGH(INIT_COM_DATA_VALUES_ILI9325D<<1)

	ldi counter,16
LOOP_INIT_16:
	RCALL WRITE_COM_DATA
	dec counter
	brne LOOP_INIT_16

	RCALL DELAY_200MS
	RCALL WRITE_COM_DATA
	RCALL WRITE_COM_DATA
	RCALL DELAY_50MS
	RCALL WRITE_COM_DATA
	RCALL DELAY_50MS
	RCALL WRITE_COM_DATA
	RCALL WRITE_COM_DATA
	RCALL WRITE_COM_DATA
	RCALL DELAY_50MS

	ldi counter,28
LOOP_INIT_28:
	
	RCALL WRITE_COM_DATA
	dec counter
	brne LOOP_INIT_28	

	SBI PORTC,B_CS

END_INIT_LCD:RET

WRITE_COM_DATA:
	
	RCALL WRITE_COM
	RCALL WRITE_DATA

END_WRITE_COM_DATA: RET

WRITE_COM:
	
	LPM com1,Z+ ;cargo comando a com1 y Z apunta a dat_high
	cbi PORTC,B_RS
	LOADIO PORTD,0
	cbi PORTC,B_WR
	sbi PORTC,B_WR
	OUT PORTD, com1
	cbi PORTC,B_WR
	SBI PORTC,B_WR
	
END_WRITE_COM: RET

WRITE_DATA:
	
	LPM data,Z+ ;cargo data_high en data y Z apunta a dat_low
	sbi PORTC,B_RS
	OUT PORTD,data
	cbi PORTC,B_WR
	SBI PORTC,B_WR
	LPM data,Z+ ;cargo data_low en data y Z apunta a com1
	OUT PORTD,data
	cbi PORTC,B_WR
	SBI PORTC,B_WR
	
END_WRITE_DATA: RET

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

DELAY_15MS:	
	         ; delaying 40239780 cycles:
	          ldi  R17, $F5
	WGLOOP15: ldi  R18, $E7
	WGLOOP13: ldi  R19, $EC
	WGLOOP14: dec  R19
	          brne WGLOOP14
	          dec  R18
	          brne WGLOOP13
	          dec  R17
	          brne WGLOOP15
	; ----------------------------- 
	; delaying 360 cycles:
	          ldi  R17, $78
	WGLOOP19: dec  R17
	          brne WGLOOP19
	          
END_DELAY_15MS: RET

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

DELAY_200MS:
			   ldi  R17, $F1
	WGLOOP10:  ldi  R18, $19
	WGLOOP11:  ldi  R19, $B0
	WGLOOP12:  dec  R19
	          brne WGLOOP12
	          dec  R18
	          brne WGLOOP11
	          dec  R17
	          brne WGLOOP10
	; ----------------------------- 
	; delaying 2 cycles:
	          nop
	          nop
END_DELAY_200MS: RET


;%%%%%%%%%%%%%%%% TABLAS CON VALORES DE INICIALIZACION %%%%%%%%%%%%%%%%%%%%%%%%
;.ORG $200

;la secuencia de valores es : com , dat_h , dat_low
INIT_COM_DATA_VALUES_ILI9325D: 
.db 0xE5,0x78,0xF0,0x01,0x01,0x00,0x02,0x02,0x00,0x03,0x10,0x30,0x04,0x00,0x00,0x08,0x02,0x07,0x09,0x00,0x00,0x0A,0x00,0x00,0x0C,0x00,0x00,0x0D,0x00,0x00,0x0F,0x00,0x00,0x10,0x00,0x00,0x11,0x00,0x07,0x12,0x00,0x00,0x13,0x00,0x00,0x07,0x00,0x01,0x10,0x16,0x90,0x11,0x02,0x27,0x12,0x00,0x0D,0x13,0x12,0x00,0x29,0x00,0x0A,0x2B,0x00,0x0D,0x20,0x00,0x00,0x21,0x00,0x00,0x30,0x00,0x00,0x31,0x04,0x04,0x32,0x00,0x03,0x35,0x04,0x05,0x36,0x08,0x08,0x37,0x04,0x07,0x38,0x03,0x03,0x39,0x07,0x07,0x3C,0x05,0x04,0x3D,0x08,0x08,0x50,0x00,0x00,0x51,0x00,0xEF,0x52,0x00,0x00,0x53,0x01,0x3F,0x60,0xA7,0x00,0x61,0x00,0x01,0x6A,0x00,0x00,0x80,0x00,0x00,0x81,0x00,0x00,0x82,0x00,0x00,0x83,0x00,0x00,0x84,0x00,0x00,0x85,0x00,0x00,0x90,0x00,0x10,0x92,0x00,0x00,0x07,0x01,0x33
INIT_COM_DATA_VALUES_ILI9325C:
.db 0xE5,0x78,0xF0,0x01,0x01,0x00,0x02,0x07,0x00,0x03,0x10,0x30,0x04,0x00,0x00,0x08,0x02,0x07,0x09,0x00,0x00,0x0A,0x00,0x00,0x0C,0x00,0x00,0x0D,0x00,0x00,0x0F,0x00,0x00,0x10,0x00,0x00,0x11,0x00,0x07,0x12,0x00,0x00,0x13,0x00,0x00,0x07,0x00,0x01,0x10,0x10,0x90,0x11,0x02,0x27,0x12,0x00,0x1F,0x13,0x15,0x00,0x29,0x00,0x27,0x2B,0x00,0x0D,0x20,0x00,0x00,0x21,0x00,0x00,0x30,0x00,0x00,0x31,0x07,0x07,0x32,0x03,0x07,0x35,0x02,0x00,0x36,0x00,0x08,0x37,0x00,0x04,0x38,0x00,0x00,0x39,0x07,0x07,0x3C,0x00,0x02,0x3D,0x1D,0x04,0x50,0x00,0x00,0x51,0x00,0xEF,0x52,0x00,0x00,0x53,0x01,0x3F,0x60,0xA7,0x00,0x61,0x00,0x01,0x6A,0x00,0x00,0x80,0x00,0x00,0x81,0x00,0x00,0x82,0x00,0x00,0x83,0x00,0x00,0x84,0x00,0x00,0x85,0x00,0x00,0x90,0x00,0x10,0x92,0x06,0x00,0x07,0x01,0x33	  


