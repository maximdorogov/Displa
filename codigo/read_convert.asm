;.include "m328def.inc"

;Constantes de calibración:
	; .equ TCAL_X	=	0x00378F66
	; .equ TCAL_Y	=	0x03C34155
	; .equ TCAL_S	=	0x000EF13F
;-----------------------------------------------
; las ordenes que se le envia son:
; S|A2|A1|A0|MODE|SER/DFR|PD1|PD2
; Para leer x: 1001 0000		0x90
; Para leer y: 1101 0000		0xD0


;----------------------DEFINICIONES-----------------------

;-----------------------------
;-----PARTE DE LA LECTURA-----
;-----------------------------
	.def	orden		=	r16
	.def	resp_high	=	r17	
	.def	resp_low	=	r18
	.def	contador	=	r19
	.def	promedio	=	r20
	.def	ac_resphx	=	r21
	.def	ac_resplx	=	r22
	.def	ac_resphy	=	r23
	.def	ac_resphy	=	r24
;Puertos
  ;Bits
	.equ TB_CLK	=	4	;A1->PC4
	.equ TB_CS	=	2	;D10->PB2
	.equ TB_DIN	=	5	;A0->PC5
	.equ TB_DOUT=	1	;D9->PB1
	;.equ T_IRQ	=	34	;no mapeado
	;.equ T_BUSY=	32	;no esta mapeado segun el esquematico del shield
  ;DDRs
	.equ TD_CLK	=	DDRC	;A1->PC4
	.equ TD_CS	=	DDRB	;D10->PB2
	.equ TD_DIN	=	DDRC	;A0->PC5
	.equ TD_DOUT=	DDRB	;D9->PB1
	;.equ T_IRQ	=	34		;no mapeado
	;.equ T_BUSY=	32		;no mapeado
  ;Ports
	.equ TP_CLK	=	PORTC	;A1->PC4
	.equ TP_CS	=	PORTB	;D10->PB2
	.equ TP_DIN	=	PORTC	;A0->PC5
	.equ TP_DOUT=	PORTB	;D9->PB1
	;.equ T_IRQ	=	34		;no mapeado
	;.equ T_BUSY=	32		;no mapeado
  ;Pin del DOUT
	.equ TPIN_DOUT =	PINB

	
;-----------------------------
;-----PARTE DEL PRODUCTO------
;-----------------------------
	.def	Tconst_conv  	=	r16
	.def	Tresp_high_x 	=	r12
	.def	Tresp_low_x		=	r13
	.def	Tresp_high_y	=	r14
	.def	Tresp_low_y		=	r15
	.def	Taux			=	r21
	.def	Taux_h			=	r22
	
	.equ 	TCAL_X			=	0x00378F66;		=	0000 0000 0011 0111 1000 1111 0110 0110
	.equ 	TCAL_Y			=	0x03C34155;		=	0000 0011 1100 0011 0100 0001 0101 0101
 	.equ 	Ttouch_x_left	=	(TCAL_X>>14) & 0x3FF;	=	0000 1101 1110	=	0x0DE	=	222
 	.equ 	Ttouch_y_top	=	(TCAL_Y>>14) & 0x3FFF;	=	1111 0000 1101	=	0xF0D	=	3853
	.equ	TCONV_X			=	0x5E
	.equ	TCONV_Y			=	0x17

	
;----------------------INICIO DEL PROGRAMA-----------------------

; ;Seteo puertos de salida y entrada, e inicializo todo en high (Esto deberia hacerse una sola vez en el main)

	; sbi		TD_CLK,TB_CLK					;sbi DDRC,4 por ejemplo
	; sbi		TD_CS,TB_CS
	; sbi		TD_DIN,TB_DIN
	; cbi		TD_DOUT,TB_DOUT
	
	; sbi		TP_CLK,TB_CLK
	; sbi		TP_DIN,TB_DIN
	; sbi		TP_CS,TB_CS
.MACRO READ_CONVERT
		ldi		promedio,8				;Contador para acumular 8 muestras
		ldi		ac_resphx,0				;inicializo los acumuladores en cero
		ldi		ac_resplx,0
		ldi		ac_resphy,0
		ldi		ac_resply,0
	INICIO_PROMEDIO:
		ldi		orden,0x90				;Leo en X
		MAGIA_ADC
		add		ac_resplx,resp_low		;Acumulo para despues promediar
		adc		ac_resphx,resp_high
		ldi		orden,0xD0				;Leo en Y
		MAGIA_ADC
		add		ac_resply,resp_low		;Acumulo para despues promediar
		adc		ac_resphy,resp_high	
		dec		promedio
		brne	INICIO_PROMEDIO
		ldi		promedio,3
	DIVIDO_POR_8:
		lsr		ac_resphx				;Shifteo el acumulador 3 veces a la derecha para dividir por 8
		ror		ac_resplx				;Esto es, promediar los 8 valores acumulados
		lsr		ac_resphy
		ror		ac_resply
		dec		promedio 
		brne	DIVIDO_POR_8
		mov		Tresp_high_x,ac_resphx	;Muevo los promedios a los registros que toma como entrada la parte de la conversion
		mov		Tresp_low_x,ac_resplx
		mov		Tresp_high_y,ac_resphy
		mov		Tresp_low_y,ac_resply
		CONVERTIR_PIXEL
.ENDMACRO	

.MACRO MAGIA_ADC			;Rutina para recibir datos del ADC, tren de pulsos de ads784.pdf pagina 8, figura 5	
	;toma la orden en "orden=r16" y devuelve high y low en resp_high y resp_low
		ldi		contador,8
		cbi		TP_CS,TB_CS		;bajo CS para empezar a enviar datos
	;----------------------Envio orden---------------------
		cbi 	TP_CLK,TB_CLK
	ENVIO_ORDEN:
		lsl		orden				;shifteo a la izquierda la orden para que el mas significativo quede en el carry
		brcs	SETEO_DIN
		cbi		TP_DIN,TB_DIN		;si el carry es cero pongo DIN en low 
		rjmp	DIN_SETEADO			;y salto a DIN_SETEADO
	SETEO_DIN:
		sbi		TP_DIN,TB_DIN		
	DIN_SETEADO:					;DIN ya tiene el dato que corresponde, 
		sbi		TP_CLK,TB_CLK		;ahora tengo que hacer titilar el clock para que el ADC levante el dato
		cbi		TP_CLK,TB_CLK
		dec		contador
		brne 	ENVIO_ORDEN	
		sbi		TP_CLK,TB_CLK	;en este punto ya está cargada la orden en el ADC.
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
		sbic	TPIN_DOUT,TB_DOUT			;Mira el bit de DOUT, si esta en low, no hace nada, sino le suma uno a respuesta
		inc		resp_low	
		dec 	contador
		brne	RECIBO_DATO
	;En este punto recibi los 12 bits de lo que devuelve el ADC, pongo el CS en high y listo
		sbi		TP_CS,TB_CS		;seteo CS para terminar el envio de datos.
		ldi		contador,0xF0		;Uso el contador como variable auxiliar. 
		and		contador,resp_high	;si 0xF0 and resp_high no es cero, tengo un valor fuera de rango, lo trunco en 0x0FFF
		breq	LEIDO_EN_RANGO
		ldi		resp_high,0x0F
		ldi		resp_low,0xFF
	LEIDO_EN_RANGO:

.ENDMACRO
	
	
	

	
.MACRO CONVERTIR_PIXEL;----------------------------------------------------------------------------------------
	;Esta es la cuenta que tengo que hacer:
	;X=(TP_X-Ttouch_x_left)*Tdisp_x_size/(Ttouch_x_right - Ttouch_x_left);
	;Y=(TP_Y-Ttouch_y_top) *Tdisp_y_size/(Ttouch_y_bottom - Ttouch_y_top);
	;Factores de conversión:
	;Tdisp_x_size/(Ttouch_x_right - Ttouch_x_left)= (239)/(870-222)=0.368827160=0x0.5E
	;Tdisp_y_size/(Ttouch_y_bottom - Ttouch_y_top)=(319)/(341-3853)=-0.090831435=0x0.17
	;La defino como positiva e invierto el sentido en que se hace la resta:TP_Y-Ttouch_y_top -> Ttouch_y_top-TP_Y

	;Esta es la funcion que voy a implementar para la coma fija:
	; a b , 0
	; 0 0 , c
	;--------
	;H(ac)|L(ac)+H(cb)|L(cb)|0 >> 16
	;Basicamente es el producto entre ab0 y 00c shifteado 16 bits a la derecha.
	; Eso es, descarto los dos registros menos significativos

	;empiezo por x:
	;segun la forma en que estan definidas las constantes, el eje x es el mas chico, que entra en un solo registro
	;le resto el offset Ttouch_x_left
		ldi		Tconst_conv,TCONV_X
		ldi		Taux,low(Ttouch_x_left)
		neg		Taux
		ldi		Taux_h,0x00
		com		Taux_h
		add		Tresp_low_x,Taux
		adc		Tresp_high_x,Taux_h
	;hago el producto
		mul		Tresp_low_x,Tconst_conv
		mov		r3,r1
		mul		Tresp_high_x,Tconst_conv
		mov		r2,r1
		add		r3,r0
		brcc	NO_CARRY_X
		inc		r2
	NO_CARRY_X:
		mov		r2,r3


	;Ahora con y:
		ldi		Tconst_conv,TCONV_Y
		ldi		Taux,low(Ttouch_y_top)
		ldi		Taux_h,high(Ttouch_y_top)
	;tengo que ver si Tresp_low_y es 0x00 para ver si tengo que usar neg o com en Tresp_high_y
		cpi		Tresp_low_y,0x00
		breq	RLOWY_NULL
	;si estoy aca es porque Tresp_low_y no es cero
		neg		Tresp_low_y
		com		Tresp_high_y
		rjmp	RLOWY_NOT_NULL
	RLOWY_NULL:
	;si estoy aca es porque Tresp_low_y es cero
		neg		Tresp_high_y
	RLOWY_NOT_NULL:
	;resto el offset
		add		Tresp_low_y,Taux
		adc		Tresp_high_y,Taux_h
	;hago el producto
		mul		Tresp_low_y,Tconst_conv
		mov		r4,r1
		mul		Tresp_high_y,Tconst_conv
		mov		r3,r1
		add		r4,r0
		brcc	NO_CARRY_Y
		inc		r3
	NO_CARRY_Y:
.ENDMACRO