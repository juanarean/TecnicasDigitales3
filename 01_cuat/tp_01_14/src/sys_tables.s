SECTION	.sys_tables progbits alloc noexec nowrite

GLOBAL GDTR
GLOBAL CODE_SEL
GLOBAL DATA_SEL
GLOBAL IDTR
GLOBAL tss_tarea0
GLOBAL tss_tarea1
GLOBAL tss_tarea2
GLOBAL base_tss0_0_15
GLOBAL base_tss1_0_15
GLOBAL base_tss2_0_15
GLOBAL base_tss0_16_23
GLOBAL base_tss1_16_23
GLOBAL base_tss2_16_23
GLOBAL base_tss0_24_31
GLOBAL base_tss1_24_31
GLOBAL base_tss2_24_31
GLOBAL SEL_TSS_TAREA0
GLOBAL SEL_TSS_TAREA1
GLOBAL SEL_TSS_TAREA2
GLOBAL _mmxt0
GLOBAL _mmxt1
GLOBAL _mmxt2
EXTERN __HANDLER_HIGH
EXTERN HANDLER_IRQ_00
EXTERN HANDLER_IRQ_06
EXTERN HANDLER_IRQ_07
EXTERN HANDLER_IRQ_08
EXTERN HANDLER_IRQ_13
EXTERN HANDLER_IRQ_14
EXTERN HANDLER_TTICK
EXTERN HANDLER_TECLADO
EXTERN HANDLER_IRQ_GEN

%define LONG_TSS 104
%define LONG_MMX 512

;ALIGN 16
_mmxt0 times LONG_MMX db 0
    
_mmxt1 times LONG_MMX db 0

_mmxt2 times LONG_MMX db 0
;-----------------------------------------------------------------------------------------------------------
; TSS tarea 0
tss_tarea0 times LONG_TSS db 0    ;TSS tarea 0

;-----------------------------------------------------------------------------------------------------------
; TSS tarea 1
tss_tarea1 times LONG_TSS db 0    ;TSS tarea 1

;-----------------------------------------------------------------------------------------------------------
; TSS tarea 2
tss_tarea2 times LONG_TSS db 0    ;TSS tarea 2


;ALIGN 8
;******************************************/
;GDT

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
SEL_TSS_TAREA0 equ $ - GDT
                    dw LONG_TSS-1      ;Descriptor de TSS desocupado (tarea 0) 
base_tss0_0_15:     dw 0                ;la direccion es 100000h porque esta al principio de la .sys_tables
base_tss0_16_23:    db 0x10
                    db 0x89
                    db 0x00
base_tss0_24_31:    db 0x00
;*******************************************/
SEL_TSS_TAREA1 equ $ - GDT
                    dw LONG_TSS-1      ;Descriptor de TSS desocupado (tarea 1) 
base_tss1_0_15:     dw LONG_TSS         ;.sys_tables + tamaño de la TSS0
base_tss1_16_23:    db 0x10
                    db 0x89
                    db 0x00
base_tss1_24_31:    db 0x00
;******************************************/
SEL_TSS_TAREA2 equ $ - GDT
                    dw LONG_TSS-1      ;Descriptor de TSS desocupado (tarea 2) 
base_tss2_0_15:     dw LONG_TSS * 2     ;.sys_tables + tamaño TSS0 + tamaño TSS1
base_tss2_16_23:    db 0x10
                    db 0x89
                    db 0x00
base_tss2_24_31:    db 0x00
;******************************************/
GDT_SIZE	equ	$-GDT		;tamaño de la GDT.

GDTR:

		dw	GDT_SIZE
		dd	GDT		; Direccion de inicio de la GDT. Donde empieza la ROM, lo primero que pongo es la GDT. 
;		dw	0xffff		;gdtr mide 64 bits... un cuadruple word. 
;******************************************/

; ******************************************
; IDT
; ******************************************


;El 1er Descriptor de la IDT se corresponde con la poscición cero del vector de interrupciones del 8259, que sería la excepción/Interrupción 0. Confeccionamos la siguiente tabla para tener en vista como se relacionan los Descriptores de la IDT con las excepciones/Interrupciones, y para interpretar con mayor facilidad la tabla IDT en el BOCHS.

; DIRECCIÓN	|	VECTOR N°
;---------------------------------------------------------------
;    00h    	|	0 (Fault)
;    01h    	|     	1 (Fault/Trap) - RESERVED
;    02h    	|	2 (Interrupt)
;    03h    	|	3 (Trap)
;    04h    	|	4 (Trap)
;    05h    	|	5 (Fault)
;    06h    	|	6 (Fault)
;    07h    	|	7 (Fault)
;    08h    	|	8 (Abort)
;    09h    	|	9 (Fault)
;    0Ah    	|	10 (Fault)
;    0Bh    	|	11 (Fault)
;    0Ch    	|	12 (Fault) 
;    0Dh    	|	13 (Fault)
;    0Eh    	|	14 (Fault)
;    0Fh    	|	15 (  -  ) - RESERVED
;    10h    	|	16 (Fault)
;    11h    	|	17 (Fault)
;    12h    	|	18 (Abort)
;    13h    	|	19 (Fault)
;    14h	|	20 (Reserved)
;    15h	|	21 (Reserved)
;    16h	|	22 (Reserved)
;    17h	|	23 (Reserved)
;    18h	|	24 (Reserved)
;    19h	|	25 (Reserved)
;    1Ah	|	26 (Reserved)
;    1Bh	|	27 (Reserved)
;    1Ch	|	28 (Reserved)
;    1Dh	|	29 (Reserved)
;    1Eh	|	30 (Reserved)
;    1Fh	|	31 (Reserved)
;    20h	|	32 (Timer Tick)
;    21h	|	33 (IRQ1 - Teclado)
;    22h	|	34
;    23h	|	35 (COM2)
;    24h	|	36 (COM1)
;    25h	|	37 (LPT2)
;    26h	|	38
;    27h	|	39 (LPT1)
;    28h	|	40
;    29h	|	41
;    2Ah
;    2Bh
;    2Ch
;    2Dh
;    2Eh
;    2Fh
;---------------------------------------------------------------
IDT:

;---------------------------------------------------------------

	 _00: equ $-IDT
		dw	HANDLER_IRQ_00
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_01: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH

;---------------------------------------------------------------

	_02: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_03: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_04: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_05: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_06: equ $-IDT
		dw	HANDLER_IRQ_06
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_07: equ $-IDT
		dw	HANDLER_IRQ_07
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_08: equ $-IDT
		dw	HANDLER_IRQ_08
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_09: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_10: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_11: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_12: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_13: equ $-IDT
		dw	HANDLER_IRQ_13
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	 _14: equ $-IDT
		dw	HANDLER_IRQ_14
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_15: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH

;---------------------------------------------------------------

	_16: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_17: equ $-IDT
		dw	HANDLER_IRQ_00
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_18: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_19: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

times 8*12 db 0
;---------------------------------------------------------------
; IRQ TIMERTICK
;---------------------------------------------------------------

	_32: equ $-IDT
		dw	HANDLER_TTICK
		dw	CODE_SEL
		db	0
		db	10001110b		; INTERRUPT
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

;---------------------------------------------------------------
; IRQ TECLADO
;---------------------------------------------------------------

	_33: equ $-IDT
		dw	HANDLER_TECLADO
		dw	CODE_SEL
		db	0
		db	10001110b		; INTERRUPT
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_34: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_35: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_36: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH

;---------------------------------------------------------------

	_37: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_38: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_39: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_40: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_41: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_42: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_43: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_44: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_45: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_46: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

	_47: equ $-IDT
		dw	HANDLER_IRQ_GEN
		dw	CODE_SEL
		db	0
		db	10001111b		; FAULT/TRAP
		dw	__HANDLER_HIGH
		
;---------------------------------------------------------------

idt_size	equ	$-IDT		;Calcula dinámicamente el tamaño de la IDT
	 
;-------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------------------
IDTR:		
	 dw idt_size-1	;Límite = Tamaño del segmento - 1
	 dd IDT		;Base de la IDT
	 dw 0

