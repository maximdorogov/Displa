;Esta funcion recibe en los registros R17-R20 la informacion que devuelve el ADC (son 12 bits para cada coordenada)
;y devuelve en los registros r2:X y en r3:high(Y) r4:low(Y)

	.def	const_conv  =	r16
	.def	resp_high_y	=	r17
	.def	resp_low_y	=	r18
	.def	resp_high_x	=	r19
	.def	resp_low_x	=	r20
	.def	aux			=	r21
	.def	aux_h		=	r22

;Esta es la cuenta que tengo que hacer:
;X=(TP_X-touch_x_left)*disp_x_size/(touch_x_right - touch_x_left);
;Y=(TP_Y-touch_y_top) *disp_y_size/(touch_y_bottom - touch_y_top);
;Con los valores de calibracion que me dan, tengo:
	.equ CAL_X	=	0x00378F66;				=	0000 0000 0011 0111 1000 1111 0110 0110
	.equ CAL_Y	=	0x03C34155;				=	0000 0011 1100 0011 0100 0001 0101 0101
	;.equ CAL_S	=	0x000EF13F;				=	0000 0000 0000 1110 1111 0001 0011 1111
 	.equ touch_x_left	=	(CAL_X>>14) & 0x3FF;	=	0000 1101 1110	=	0x0DE	=	222
 	;.equ touch_x_right	=	CAL_X & 0x3FFF;			=   0011 0110 0110	=	0x366	=	870

 	.equ touch_y_top	=	(CAL_Y>>14) & 0x3FFF;	=	1111 0000 1101	=	0xF0D	=	3853
 	;.equ touch_y_bottom	=	CAL_Y & 0x3FFF;			=	0001 0101 0101	=	0x155	=	341

 	;.equ disp_x_size	=	(CAL_S>>12) & 0x0FFF;	=	0000 1110 1111	=	0x0EF	=	239
 	;.equ disp_y_size	=	CAL_S & 0x0FFF;			=	0001 0011 1111	=	0x13F	=	319


;Factores de conversión:
;disp_x_size/(touch_x_right - touch_x_left)= (239)/(870-222)=0.368827160=0x0.5E
	.equ	CONV_X		=	0x5E
;disp_y_size/(touch_y_bottom - touch_y_top)=(319)/(341-3853)=-0.090831435=0x0.17
;La defino como positiva e invierto el sentido en que se hace la resta:TP_Y-touch_y_top -> touch_y_top-TP_Y
	.equ	CONV_Y		=	0x17


;Esta es la funcion que voy a implementar para la coma fija:
; a b , 0
; 0 0 , c
;--------
;H(ac)|L(ac)+H(cb)|L(cb)|0 >> 16
;Basicamente es el producto entre ab0 y 00c shifteado 16 bits a la derecha.
; Eso es, descarto los dos registros menos significativos

;	.equ	prueba_x=300			;entre 222 y 870
;	.equ	prueba_y=3000			;entre 341 y 3853
;
;	ldi		resp_high_y,high(prueba_y)
;	ldi		resp_low_y,low(prueba_y)
;	ldi		resp_high_x,high(prueba_x)
;	ldi		resp_low_x,low(prueba_x)


;empiezo por x:
;segun la forma en que estan definidas las constantes, el eje x es el mas chico, que entra en un solo registro
;le resto el offset touch_x_left
	ldi		const_conv,CONV_X
	ldi		aux,low(touch_x_left)
	neg		aux
	ldi		aux_h,0x00
	com		aux_h
	add		resp_low_x,aux
	adc		resp_high_x,aux_h
;hago el producto
	mul		resp_low_x,const_conv
	mov		r3,r1
	mul		resp_high_x,const_conv
	mov		r2,r1
	add		r3,r0
	brcc	NO_CARRY_X
	inc		r2
NO_CARRY_X:
	mov		r2,r3


;Ahora con y:
	ldi		const_conv,CONV_Y
	ldi		aux,low(touch_y_top)
	ldi		aux_h,high(touch_y_top)
;tengo que ver si resp_low_y es 0x00 para ver si tengo que usar neg o com en resp_high_y
	cpi		resp_low_y,0x00
	breq	RLOWY_NULL
;si estoy aca es porque resp_low_y no es cero
	neg		resp_low_y
	com		resp_high_y
	rjmp	RLOWY_NOT_NULL
RLOWY_NULL:
;si estoy aca es porque resp_low_y es cero
	neg		resp_high_y
RLOWY_NOT_NULL:
;resto el offset
	add		resp_low_y,aux
	adc		resp_high_y,aux_h
;hago el producto
	mul		resp_low_y,const_conv
	mov		r4,r1
	mul		resp_high_y,const_conv
	mov		r3,r1
	add		r4,r0
	brcc	NO_CARRY_Y
	inc		r3
NO_CARRY_Y: