	.include "m328def.inc"

;Constantes de calibración:
	.equ CAL_X	=	0x00378F66
	.equ CAL_Y	=	0x03C34155
	.equ CAL_S	=	0x000EF13F

;Puertos
  ;Bits
	.equ B_CLK	=	4	;A1->PC4
	.equ B_CS	=	0	;D8->PB0
	.equ B_DIN	=	5	;A0->PC5
	.equ B_DOUT	=	1	;D9->PB1
	;.equ T_IRQ	=	34	;no mapeado
	;.equ T_BUSY=	32	;no esta mapeado segun el esquematico del shield
  ;Puertos
	.equ P_CLK	=	PORTC	;A1->PC4
	.equ P_CS	=	PORTB	;D8->PB0
	.equ P_DIN	=	PORTC	;A0->PC5
	.equ P_DOUT	=	PORTB	;D9->PB1
	;.equ T_IRQ	=	34		;no mapeado
	;.equ T_BUSY=	32		;no esta mapeado segun el esquematico del shield

;Constantes magicas que hacen a la calibracion

	.equ orient			=	1 ; portrait o landscape
	.equ touch_x_left	=	(CAL_X>>14) & 0x3FF;
	.equ touch_x_right	=	CAL_X & 0x3FFF;
	.equ touch_y_top	=	(CAL_Y>>14) & 0x3FFF;
	.equ touch_y_bottom	=	CAL_Y & 0x3FFF;
	.equ disp_x_size	=	(CAL_S>>12) & 0x0FFF;
	.equ disp_y_size	=	CAL_S & 0x0FFF;

;Seteo puertos de salida y entrada

	sbi		P_CLK,B_CLK
	sbi		P_CS,B_CS
	sbi		P_DIN,B_DIN
	cbi		P_DOUT,B_DOUT