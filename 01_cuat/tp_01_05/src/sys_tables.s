SECTION	.sys_tables progbits alloc noexec nowrite

GLOBAL GDTR
GLOBAL CODE_SEL
GLOBAL DATA_SEL

;******************************************/
;GDT PARA INICIAR EL SISTEMA
;******************************************/


GDT:

		dq	0		;la GDT empieza siempre con el descriptor 0. Null descriptor. 8 Bytes de 0s.
      
;******************************************/
; * DESCRIPTOR DE CODIGO */

CODE_SEL	equ	$-GDT		;para definir donde empieza el decriptor de código. <<<esto no gasta memoria, son macros para el compilador.>>>
      
code_desc:

limit_low:	dw	0xffff		;cantidad de direcciones del segmento.
base_15_0:	dw	0x0000		;todas las direcciones en 0 -> memoria flat.
base_23_16:	db	0x00
att_low:	db	10011011b	;PRESENTE / DPL=0 / NO DE SISEMA / 1 (codigo) / AJUSTABLE (nivel de priv.) / READABLE / ACCEDIDO.
att_high:	db	11001111b	;GRANULAR / SEGMENTO DE 32 BITS / NO ES IA-32e (64BITS) / BIT PARA EL USUARIO / PARTE ALTA DEL LIMITE.
base_31_24:	db	0x00

;******************************************/
; * DESCRIPTOR DE DATOS */

DATA_SEL	equ	$-GDT		;para definir donde empieza el descriptor de datos.

data_desc:

		dw	0xffff		;limite 15-0
		dw	0		;base 15-0
		db	0		;base 23-16
		db	10010011b	;atributos low.
		db	11001111b	;atributos high.
		db	0		;base 32-24.

;******************************************/
GDT_SIZE	equ	$-GDT		;tamaño de la GDT.

GDTR:

		dw	GDT_SIZE
		dd	GDT		; Direccion de inicio de la GDT. Donde empieza la ROM, lo primero que pongo es la GDT. 
;		dw	0xffff		;gdtr mide 64 bits... un cuadruple word. 
;******************************************/
