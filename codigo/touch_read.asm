	.include "m328def.inc"

;Constantes de calibración:
	.equ CAL_X	=	0x00378F66
	.equ CAL_Y	=	0x03C34155
	.equ CAL_S	=	0x000EF13F

;-----------------------------------------------
; Recibo en r16 la orden que se le envia al ADC y devuelvo en r17(high) y r18(low) lo que leyo el ADC
; las ordenes que se le envia son:
; S|A2|A1|A0|MODE|SER/DFR|PD1|PD2
; S es siempre 1. MODE 0 para 12 bits, 1 para 8 bits
; SER/DFR 1 para single ended reference mode, 0 para diferencial reference mode
; PD1 y PD2 son para power down, si queres ahorrar energia.
; Para leer x: 1001 0000
; Para leer y: 1101 0000




	
;Puertos
  ;Bits
	.equ B_CLK	=	4	;A1->PC4
	.equ B_CS	=	2	;D10->PB2
	.equ B_DIN	=	5	;A0->PC5
	.equ B_DOUT	=	1	;D9->PB1
	;.equ T_IRQ	=	34	;no mapeado
	;.equ T_BUSY=	32	;no esta mapeado segun el esquematico del shield
  ;DDRs
	.equ D_CLK	=	DDRC	;A1->PC4
	.equ D_CS	=	DDRB	;D10->PB2
	.equ D_DIN	=	DDRC	;A0->PC5
	.equ D_DOUT	=	DDRB	;D9->PB1
	;.equ T_IRQ	=	34		;no mapeado
	;.equ T_BUSY=	32		;no mapeado
  ;Ports
	.equ P_CLK	=	PORTC	;A1->PC4
	.equ P_CS	=	PORTB	;D10->PB2
	.equ P_DIN	=	PORTC	;A0->PC5
	.equ P_DOUT	=	PORTB	;D9->PB1
	;.equ T_IRQ	=	34		;no mapeado
	;.equ T_BUSY=	32		;no mapeado
  ;Pin del DOUT
	.equ PIN_DOUT =	PINB

;Constantes magicas que hacen a la calibracion

	.equ orient			=	1 ; portrait o landscape
	.equ touch_x_left	=	(CAL_X>>14) & 0x3FF;
	.equ touch_x_right	=	CAL_X & 0x3FFF;
	.equ touch_y_top	=	(CAL_Y>>14) & 0x3FFF;
	.equ touch_y_bottom	=	CAL_Y & 0x3FFF;
	.equ disp_x_size	=	(CAL_S>>12) & 0x0FFF;
	.equ disp_y_size	=	CAL_S & 0x0FFF;

;Seteo puertos de salida y entrada, e inicializo el CS en high, y el resto en low

	sbi		D_CLK,B_CLK					;sbi DDRC,4 por ejemplo
	sbi		D_CS,B_CS
	sbi		D_DIN,B_DIN
	cbi		D_DOUT,B_DOUT
	
	cbi		P_CLK,B_CLK
	cbi		P_DIN,B_DIN
	sbi		P_CS,B_CS
	
	


;Rutina para recibir datos del ADC, tren de pulsos de ads784.pdf pagina 8, figura 5
	
	.def	orden		=	r16
	.def	resp_high	=	r17		;usar Zl y Zh para resp no ayuda en nada de la forma que lo voy a implementar
	.def	resp_low	=	r18
	.def	contador	=	r19
	
	ldi		contador,8
	cbi		P_CS,B_CS		;bajo CS para empezar a enviar datos
;----------------------Envio orden---------------------
ENVIO_ORDEN:
	lsl		orden			;shifteo a la izquierda la orden para que el mas significativo quede en el carry
	brcs	SETEO_DIN
	cbi		P_DIN,B_DIN		;si el carry es cero pongo DIN en low 
	rjmp	DIN_SETEADO		;y salto a DIN_SETEADO
SETEO_DIN:
	sbi		P_DIN,B_DIN		
DIN_SETEADO:				;DIN ya tiene el dato que corresponde, 
	sbi		P_CLK,B_CLK		;ahora tengo que hacer titilar el clock para que el ADC levante el dato
	cbi		P_CLK,B_CLK
	dec		contador
	brne 	ENVIO_ORDEN		;en este punto ya está cargada la orden en el ADC, creo que hay que poner un delay por aca y empezar a leer la respuesta

	
;----------------------Recepcion de datos----------------
	ldi		contador,12
	ldi		resp_high,0x00
	ldi		resp_low,0x00
RECIBO_DATO:
	sbi		P_CLK,B_CLK
	sbic	PIN_DOUT,B_DOUT			;Mira el bit de DOUT, si esta en low, no hace nada, sino le suma uno a respuesta
	rjmp	PIN_DOUT_NO_SETEADO
	;si estoy aca es porque el bit que devuelve el ADC es un uno
	inc		resp_low	
PIN_DOUT_NO_SETEADO:				;si el rjmp me trajo aca, es xq el ADC devuelve un cero, que es el valor del lsb de resp_low
	lsl		resp_low				;shifteo a la izquierda el low de la respuesta para que el msb quede en carry
	rol		resp_high				;shifteo a la izquierda, y pongo el carry en el lsb
	cbi 	P_CLK,B_CLK
	dec 	contador
	brne	RECIBO_DATO
;En este punto recibi los 12 bits de lo que devuelve el ADC, pongo el CS en high y listo
	sbi		P_CS,B_CS		;bajo CS para empezar a enviar datos


	
	
	
