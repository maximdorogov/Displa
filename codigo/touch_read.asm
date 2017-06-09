	;.include "m328def.inc"

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
; PD1 y PD2 son para power down, si queres ahorrar energia. Los dejamos todos en 0
; Para leer x: 1001 0000
; Para leer y: 1101 0000




	
;Puertos
  ;Bits
	.equ TB_CLK	=	4	;A1->PC4
	.equ TB_CS	=	2	;D10->PB2
	.equ TB_DIN	=	5	;A0->PC5
	.equ TB_DOUT	=	1	;D9->PB1
	;.equ T_IRQ	=	34	;no mapeado
	;.equ T_BUSY=	32	;no esta mapeado segun el esquematico del shield
  ;DDRs
	.equ TD_CLK	=	DDRC	;A1->PC4
	.equ TD_CS	=	DDRB	;D10->PB2
	.equ TD_DIN	=	DDRC	;A0->PC5
	.equ TD_DOUT	=	DDRB	;D9->PB1
	;.equ T_IRQ	=	34		;no mapeado
	;.equ T_BUSY=	32		;no mapeado
  ;Ports
	.equ TP_CLK	=	PORTC	;A1->PC4
	.equ TP_CS	=	PORTB	;D10->PB2
	.equ TP_DIN	=	PORTC	;A0->PC5
	.equ TP_DOUT	=	PORTB	;D9->PB1
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

	sbi		TD_CLK,TB_CLK					;sbi DDRC,4 por ejemplo
	sbi		TD_CS,TB_CS
	sbi		TD_DIN,TB_DIN
	cbi		TD_DOUT,TB_DOUT
	
	cbi		TP_CLK,TB_CLK
	cbi		TP_DIN,TB_DIN
	sbi		TP_CS,TB_CS
	
	


;Rutina para recibir datos del ADC, tren de pulsos de ads784.pdf pagina 8, figura 5
	
	.def	orden		=	r16
	.def	resp_high	=	r17	
	.def	resp_low	=	r18
	.def	contador	=	r19
	
	ldi		contador,8
	cbi		TP_CS,TB_CS		;bajo CS para empezar a enviar datos
;----------------------Envio orden---------------------
ENVIO_ORDEN:
	cbi TP_CLK,TB_CLK
	lsl		orden			;shifteo a la izquierda la orden para que el mas significativo quede en el carry
	brcs	SETEO_DIN
	cbi		TP_DIN,TB_DIN		;si el carry es cero pongo DIN en low 
	rjmp	DIN_SETEADO		;y salto a DIN_SETEADO
SETEO_DIN:
	sbi		TP_DIN,TB_DIN		
DIN_SETEADO:				;DIN ya tiene el dato que corresponde, 
	sbi		TP_CLK,TB_CLK		;ahora tengo que hacer titilar el clock para que el ADC levante el dato
	cbi		TP_CLK,TB_CLK
	dec		contador
	brne 	ENVIO_ORDEN	
		;en este punto ya está cargada la orden en el ADC.
	sbi		TP_CLK,TB_CLK
	cbi		TP_CLK,TB_CLK
;----------------------Recepcion de datos----------------

	ldi		contador,12
	ldi		resp_high,0x00
	ldi		resp_low,0x00
RECIBO_DATO:
	lsl		resp_low				;shifteo a la izquierda el low de la respuesta para que el msb quede en carry
	rol		resp_high				;shifteo a la izquierda, y pongo el carry en el lsb
	sbi		TP_CLK,TB_CLK
	cbi 	TP_CLK,TB_CLK
	sbic	PIN_DOUT,TB_DOUT			;Mira el bit de DOUT, si esta en low, no hace nada, sino le suma uno a respuesta
	inc		resp_low	
	dec 	contador
	brne	RECIBO_DATO
;En este punto recibi los 12 bits de lo que devuelve el ADC, pongo el CS en high y listo
	sbi		TP_CS,TB_CS		;seteo CS para terminar el envio de datos.
	
	andi	resp_high,0x3F	; si lo que devuelve el ADC esta fuera de rango, lo trunco en 4095 (0x3F FF)
	
	
	
	
	
	
	
	
	
	
	
	
;Para que esto coincida al 100% con la funcion de ejemplo, hay que ponerla en un loop de 10 veces,
;agregar un acumulador que sume lo que devuelve el ADC en cada iteracion, descartando cualquier dato fuera de intervalo, y guardando
;en otros dos registros los valores maximo y minimo que devuelve el touch. Despues se le resta al valor acumulado el valor maximo y minimo
;leido, y se le hace un shifteo 3 veces (dividir por 8). Si se descarto en alguna oportunidad un dato, habria que dividir por 7 (o lo que corresponda)
; o bien tomar un dato extra hasta tener 10 en total (sin descartar el max y min)