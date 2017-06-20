;.include "m328def.inc"
.include "IO.mac"
.include "tft_colors.inc"
.include "tft_macros.mac"
;.include "read_convert.inc"

.equ RAM_START = 0x0100
.EQU B_RST = 2
.EQU B_CS = 3
.EQU B_WR = 4
.EQU B_RS = 5

.EQU NUM_COM_VALUES = 50 
.EQU NUM_DATA_VALUES = 50

.EQU tft_max_x = 319
.EQU tft_max_y = 239

.DEF com1 = r20
.DEF data = r22
.DEF counter = r21
.DEF c_high = r18
.DEF c_low = r17

.EQU PIXEL_COLOR = VGA_WHITE
.DEF pixel_x_high = r3
.DEF pixel_x_low = r2
.DEF pixel_y = r1

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
	.def	ac_resply	=	r24
	.def	temp_memh	=	r25
	.def	temp_meml	=	r26
;Direcciones de memoria RAM
	.equ	xh_min		=	RAM_START
	.equ	xl_min		=	xh_min+1
	.equ	xh_max		=	xh_min+2
	.equ	xl_max		=	xh_min+3
	.equ	yh_min		=	xh_min+4
	.equ	yl_min		=	xh_min+5
	.equ	yh_max		=	xh_min+6
	.equ	yl_max		=	xh_min+7
	.equ	anterior_xh	=	xh_min+8
	.equ	anterior_hl	=	xh_min+9
	.equ	anterior_y	=	xh_min+10
;Varianzas aceptables de las mediciones
	.equ 	var_x		=	7
	.equ	var_y		=	16
;Puertos
  ;Bits
	.equ TB_CLK	=	1	;A1->PC4
	.equ TB_CS	=	2	;D10->PB2
	.equ TB_DIN	=	0	;A0->PC5
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
	.equ	TCONV_X			=	0x11			;0x10
	.equ	TCONV_Y			=	0x17			;0x17
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
	RCALL INIT_TOUCH

;---TESTBENCH---- lleno la pantalla de azul y dibujo 2 pixeles en 2 posiciones distintas

	FILL_SCRN VGA_BLACK;Lleno la pantalla de color negro
	;ldi r31,high(100) ;pixel_x_h
	;ldi r30,low(100) ;pixel_x_low
	;ldi r29,100 ;pixel_y
	;DRAW_PIXEL r31,r30,r29
	;ldi r31,high(200) ;pixel_x_h
	;ldi r30,low(200) ;pixel_x_low
	;ldi r29,100 ;pixel_y
	;DRAW_PIXEL r31,r30,r29
ACA:
	rcall READ_CONVERT ;
	ldi r20,240
	sub r20,r10
	mov r10,r20
	DRAW_PIXEL r11,r12,r10
	rcall DELAY_5MS
	RJMP ACA





INIT_LCD: 
	
	SBI PORTC,B_RST
	RCALL DELAY_5MS
	CBI PORTC,B_RST
	RCALL DELAY_15MS
	SBI PORTC,B_RST
	RCALL DELAY_15MS
	CBI PORTC,B_CS

	ldi Zl,low(INIT_COM_DATA_VALUES_ILI9325C<<1)
	ldi zh,HIGH(INIT_COM_DATA_VALUES_ILI9325C<<1)

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

INIT_TOUCH:

	sbi		TD_CLK,TB_CLK		
	sbi		TD_CS,TB_CS
	sbi		TD_DIN,TB_DIN
	cbi		TD_DOUT,TB_DOUT
	sbi		TP_CLK,TB_CLK
	sbi		TP_DIN,TB_DIN
	sbi		TP_CS,TB_CS
INIT_TOUCH_EXIT: ret


;--------------------------------------read_convert
READ_CONVERT:
		ldi		promedio,16		;Contador para acumular 8 muestras
		ldi		ac_resphx,0				;inicializo los acumuladores en cero
		ldi		ac_resplx,0
		ldi		ac_resphy,0
		ldi		ac_resply,0
		ldi		temp_memh,0xFF
		; sts 	xh_min,temp_memh		;inicializo el minimo con 0xFF y el maximo con 0x00
		; sts 	xl_min,temp_memh		;asi el primer dato que reciba se reemplaza
		; sts 	xh_max,ac_resphx
		; sts 	xl_max,ac_resphx
		; sts 	yh_min,temp_memh
		; sts 	yl_min,temp_memh
		; sts 	yh_max,ac_resphx
		; sts 	yl_max,ac_resphx
		
	INICIO_PROMEDIO:
		ldi		orden,0xD0				;Leo en X
		rcall MAGIA_ADC
		;rcall COMP_EXT_X
		add		ac_resplx,resp_low		;Acumulo para despues promediar
		adc		ac_resphx,resp_high
		ldi		orden,0x90				;Leo en Y
		rcall MAGIA_ADC
		;rcall COMP_EXT_Y
		add		ac_resply,resp_low		;Acumulo para despues promediar
		adc		ac_resphy,resp_high	
		dec		promedio
		brne	INICIO_PROMEDIO
		;sbi		TP_CS,TB_CS			;por algun motivo la rutina de C termina la comunicacion aca.
		
		; lds		temp_memh,xh_max
		; sub		ac_resphx,temp_memh		;cargo en un registro auxiliar el high y el low del maximo de x, y se lo resto al acumulador
		; lds		temp_memh,xl_max
		; sbc		ac_resplx,temp_memh		;
		; lds		temp_memh,xh_min		;repito para el valor minimo de x
		; sub		ac_resphx,temp_memh		
		; lds		temp_memh,xl_min
		; sbc		ac_resplx,temp_memh		;
		
		; lds		temp_memh,yh_max		;Repito para Y
		; sub		ac_resphy,temp_memh		
		; lds		temp_memh,yl_max
		; sbc		ac_resply,temp_memh		
		; lds		temp_memh,yh_min		
		; sub		ac_resphy,temp_memh		
		; lds		temp_memh,yl_min
		; sbc		ac_resply,temp_memh		
		
		ldi		promedio,4
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
		rcall 	CONVERTIR_PIXEL
		mov 	r10,r2
		mov 	r11,r3
		mov 	r12,r4
		ret

MAGIA_ADC:			;Rutina para recibir datos del ADC, tren de pulsos de ads784.pdf pagina 8, figura 5	
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
		cbi		TP_CLK,TB_CLK		;ahora tengo que hacer titilar el clock para que el ADC levante el dato
		sbi		TP_CLK,TB_CLK
		dec		contador
		brne 	ENVIO_ORDEN	
		sbi		TP_CLK,TB_CLK	;en este punto ya está cargada la orden en el ADC.
		cbi		TP_CLK,TB_CLK
	;----------------------Recepcion de datos----------------
		ldi		contador,12
		ldi		resp_high,0x00
		ldi		resp_low,0x00
	RECIBO_DATO:
		; lsl		resp_low				;shifteo a la izquierda el low de la respuesta para que el msb quede en carry
		; rol		resp_high				;shifteo a la izquierda, y pongo el carry en el lsb
		sbi		TP_CLK,TB_CLK
		cbi 	TP_CLK,TB_CLK
		sbic	TPIN_DOUT,TB_DOUT			;Mira el bit de DOUT, si esta en low, no hace nada, sino le suma uno a respuesta
		inc		resp_low	
		lsl		resp_low				;shifteo a la izquierda el low de la respuesta para que el msb quede en carry
		rol		resp_high				;shifteo a la izquierda, y pongo el carry en el lsb
		dec 	contador
		brne	RECIBO_DATO
	;En este punto recibi los 12 bits de lo que devuelve el ADC, pongo el CS en high y listo
		sbi		TP_CS,TB_CS		;seteo CS para terminar el envio de datos.
		ldi		contador,0xF0		;Uso el contador como variable auxiliar. 
		and		contador,resp_high	;si 0xF0 and resp_high no es cero, tengo un valor fuera de rango, lo trunco en 0x0FFF
		breq	LEIDO_EN_RANGO
		ldi		resp_high,0x00
		ldi		resp_low,0x00
	LEIDO_EN_RANGO:
	ret
	
	
	

	
CONVERTIR_PIXEL:;----------------------------------------------------------------------------------------
	;Esta es la cuenta que tengo que hacer:
	;	VIEJOS	X=(TP_X-Ttouch_x_left)*Tdisp_x_size/(Ttouch_x_right - Ttouch_x_left);
	;			Y=(TP_Y-Ttouch_y_top) *Tdisp_y_size/(Ttouch_y_bottom - Ttouch_y_top);
	;			Tdisp_x_size/(Ttouch_x_right - Ttouch_x_left)= (239)/(870-222)=0.368827160=0x0.5E
	;			Tdisp_y_size/(Ttouch_y_bottom - Ttouch_y_top)=(319)/(341-3853)=-0.090831435=0x0.17
	;X=(TP_X - touch_y_top) *(disp_y_size)) /(touch_y_bottom - touch_y_top);
	;	disp_y_size/(touch_y_bottom-touch_y_top)=319/(341-3853)=-0.090831435=0x0.17
	;Y=(TP_Y - touch_x_left)*(-disp_x_size))/(touch_x_right - touch_x_left) + disp_x_size;
	;	disp_x_size/(touch_x_right-touch_x_left)
	
	;Factores de conversión:
	
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
		mov 	r30,Tresp_low_y
		cpi		r30,0x00
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
	ret
	
COMP_EXT_X:
		lds		temp_memh,xh_max
		lds		temp_meml,xl_max
		cp		resp_low,temp_meml
		cpc		resp_high,temp_memh
		brcs	COMP_X_NOT_MAX
		sts		xh_max,resp_high
		sts		xl_max,resp_low
	COMP_X_NOT_MAX:
		lds		temp_memh,xh_min
		lds		temp_meml,xl_min
		cp		resp_low,temp_meml
		cpc		resp_high,temp_memh
		brcc	COMP_X_NOT_MIN
		sts		xh_min,resp_high
		sts		xl_min,resp_low
	COMP_X_NOT_MIN:
ret

COMP_EXT_Y:
		lds		temp_memh,yh_max
		lds		temp_meml,yl_max
		cp		resp_low,temp_meml
		cpc		resp_high,temp_memh
		brcs	COMP_Y_NOT_MAX
		sts		yh_max,resp_high
		sts		yl_max,resp_low
	COMP_Y_NOT_MAX:
		lds		temp_memh,yh_min
		lds		temp_meml,yl_min
		cp		resp_low,temp_meml
		cpc		resp_high,temp_memh
		brcc	COMP_Y_NOT_MIN
		sts		yh_min,resp_high
		sts		yl_min,resp_low
	COMP_Y_NOT_MIN:
ret

	;%%%%%%%%%%%%%%%% TABLAS CON VALORES DE INICIALIZACION %%%%%%%%%%%%%%%%%%%%%%%%
;.ORG $200

;la secuencia de valores es : com , dat_h , dat_low
INIT_COM_DATA_VALUES_ILI9325D: 
.db 0xE5,0x78,0xF0,0x01,0x01,0x00,0x02,0x02,0x00,0x03,0x10,0x30,0x04,0x00,0x00,0x08,0x02,0x07,0x09,0x00,0x00,0x0A,0x00,0x00,0x0C,0x00,0x00,0x0D,0x00,0x00,0x0F,0x00,0x00,0x10,0x00,0x00,0x11,0x00,0x07,0x12,0x00,0x00,0x13,0x00,0x00,0x07,0x00,0x01,0x10,0x16,0x90,0x11,0x02,0x27,0x12,0x00,0x0D,0x13,0x12,0x00,0x29,0x00,0x0A,0x2B,0x00,0x0D,0x20,0x00,0x00,0x21,0x00,0x00,0x30,0x00,0x00,0x31,0x04,0x04,0x32,0x00,0x03,0x35,0x04,0x05,0x36,0x08,0x08,0x37,0x04,0x07,0x38,0x03,0x03,0x39,0x07,0x07,0x3C,0x05,0x04,0x3D,0x08,0x08,0x50,0x00,0x00,0x51,0x00,0xEF,0x52,0x00,0x00,0x53,0x01,0x3F,0x60,0xA7,0x00,0x61,0x00,0x01,0x6A,0x00,0x00,0x80,0x00,0x00,0x81,0x00,0x00,0x82,0x00,0x00,0x83,0x00,0x00,0x84,0x00,0x00,0x85,0x00,0x00,0x90,0x00,0x10,0x92,0x00,0x00,0x07,0x01,0x33
INIT_COM_DATA_VALUES_ILI9325C:
.db 0xE5,0x78,0xF0,0x01,0x01,0x00,0x02,0x07,0x00,0x03,0x10,0x30,0x04,0x00,0x00,0x08,0x02,0x07,0x09,0x00,0x00,0x0A,0x00,0x00,0x0C,0x00,0x00,0x0D,0x00,0x00,0x0F,0x00,0x00,0x10,0x00,0x00,0x11,0x00,0x07,0x12,0x00,0x00,0x13,0x00,0x00,0x07,0x00,0x01,0x10,0x10,0x90,0x11,0x02,0x27,0x12,0x00,0x1F,0x13,0x15,0x00,0x29,0x00,0x27,0x2B,0x00,0x0D,0x20,0x00,0x00,0x21,0x00,0x00,0x30,0x00,0x00,0x31,0x07,0x07,0x32,0x03,0x07,0x35,0x02,0x00,0x36,0x00,0x08,0x37,0x00,0x04,0x38,0x00,0x00,0x39,0x07,0x07,0x3C,0x00,0x02,0x3D,0x1D,0x04,0x50,0x00,0x00,0x51,0x00,0xEF,0x52,0x00,0x00,0x53,0x01,0x3F,0x60,0xA7,0x00,0x61,0x00,0x01,0x6A,0x00,0x00,0x80,0x00,0x00,0x81,0x00,0x00,0x82,0x00,0x00,0x83,0x00,0x00,0x84,0x00,0x00,0x85,0x00,0x00,0x90,0x00,0x10,0x92,0x06,0x00,0x07,0x01,0x33	  
