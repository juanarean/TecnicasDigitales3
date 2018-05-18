USE16

%define DESTINO_1       0x00000000
%define DESTINO_2       0x00300000      
%define ROM_SIZE		(64*1024)
%define ROM_START		0xf0000
%define RESET_VECTOR	0xffff0
ORG ROM_START
start16:

   xor eax, eax
   mov cr3, eax             ;Invalidar TLB
  
   jmp A20_Enable_No_Stack  ;Habilito el mecanismo gate A20
   A20_Enable_No_Stack_return:
xchg bx,bx    
   
   o32 lgdt  [cs:GDTR]
   ;Establecer el up en MP
	mov eax,cr0				; 
	or al,1					; 
	mov cr0,eax				; solo pongo en "1" el bit menos significaivo del CR0.

   mov esp,0x1fffb000
   
   ;->Quitar el up de MP<-
   mov  eax, cr0
   and   eax, 0xfffffffe
   mov  cr0, eax
   
xchg bx,bx
Programa:
   o32 mov eax, COPY_LENGTH
   o32 push eax
   o32 mov eax, Programa
   o32 push eax

xchg bx,bx 
;Testeo si estoy copiando por primera vez o ya estoy en la posicion 0x00000000 
   mov dx, cs
   mov bx, 0x0000
   cmp dx,bx
   jne copia_destino1
   
   mov eax, DESTINO_2
   push eax
   
   call td3_memcopy
xchg bx,bx    
   o32 jmp dword 0x0000:0x00300000

copia_destino1:
   mov eax, DESTINO_1
   push eax
   
   call td3_memcopy
xchg bx,bx    
    jmp 0x0000:0x0000
   
fin:
   hlt
   jmp fin

;///////////////////////////////////////////////////////////////////////////////
;                   Funcion para copiar
;///////////////////////////////////////////////////////////////////////////////
td3_memcopy:
pop bp
pop edi
pop edx
pop esi
pop ecx


copia:

        mov ax,0xf000
        mov ds,ax
        mov bl,[si]
        mov ds,dx
        o32 mov [edi],bl
        
        inc si
        inc di
        
        loop copia
push bp
ret

COPY_LENGTH equ ($-Programa)

;///////////////////////////////////////////////////////////////////////////////
;                   Funciones para habilitar el A20 Gate
;///////////////////////////////////////////////////////////////////////////////
%define     PORT_A_8042    0x60        ;Puerto A de E/S del 8042
%define     CTRL_PORT_8042 0x64        ;Puerto de Estado del 8042
%define     KEYB_DIS       0xAD        ;Deshabilita teclado con Command Byte
%define     KEYB_EN        0xAE        ;Habilita teclado con Command Byte
%define     READ_OUT_8042  0xD0        ;Copia en 0x60 el estado de OUT
%define     WRITE_OUT_8042 0xD1        ;Escribe en OUT lo almacenado en 0x60

USE16
;------------------------------------------------------------------------------
;| Título: A20_Enable_No_Stack                                                |
;| Versión:       1.0                     Fecha:   26/02/2018                 |
;| Autor:         ChristiaN               Modelo:  IA-32 (16bits)             |
;| ------------------------------------------------------------------------   |
;| Descripción:                                                               |
;|    Habilita la puerta A20 sin utilizacion de la pila.                      |
;|    Referencia https://wiki.osdev.org/A20_Line                              |
;| ------------------------------------------------------------------------   |
;| Recibe:                                                                    |
;|    Nada                                                                    |
;|                                                                            |
;| Retorna:                                                                   |
;|    Nada                                                                    |
;| ------------------------------------------------------------------------   |
;| Revisiones:                                                                |
;|    1.0 | 26/02/2018 | ChristiaN | Original                                 |
;------------------------------------------------------------------------------
A20_Enable_No_Stack:

   xor ax, ax
   ;Deshabilita el teclado
   mov di, .8042_kbrd_dis
   jmp .empty_8042_in
   .8042_kbrd_dis:
   mov al, KEYB_DIS
   out CTRL_PORT_8042, al
 
   ;Lee la salida
   mov di, .8042_read_out
   jmp .empty_8042_in
   .8042_read_out:
   mov al, READ_OUT_8042
   out CTRL_PORT_8042, al
   
   .empty_8042_out:  
;      in al, CTRL_PORT_8042      ; Lee port de estado del 8042 hasta que el
;      test al, 00000001b         ; buffer de salida este vacio
;      jne .empty_8042_out

   xor bx, bx   
   in al, PORT_A_8042
   mov bx, ax

   ;Modifica el valor del A20
   mov di, .8042_write_out
   jmp .empty_8042_in
   .8042_write_out:
   mov al, WRITE_OUT_8042
   out CTRL_PORT_8042, al

   mov di, .8042_set_a20
   jmp .empty_8042_in
   .8042_set_a20:
   mov ax, bx
   or ax, 00000010b              ; Habilita el bit A20
   out PORT_A_8042, al

   ;Habilita el teclado
   mov di, .8042_kbrd_en
   jmp .empty_8042_in
   .8042_kbrd_en:
   mov al, KEYB_EN
   out CTRL_PORT_8042, al

   mov di, .a20_enable_no_stack_exit
   .empty_8042_in:  
;      in al, CTRL_PORT_8042      ; Lee port de estado del 8042 hasta que el
;      test al, 00000010b         ; buffer de entrada este vacio
;      jne .empty_8042_in
      jmp di

   .a20_enable_no_stack_exit:

jmp A20_Enable_No_Stack_return

;**************************************************************************************************/
;GDT PARA INICIAR EL SISTEMA EN 32 BITS
; *************************************************************************************************/
GDT:
		dq	0		;la GDT empieza siempre con el descriptor 0. Null descriptor. 8 Bytes de 0s.
      
;***************************************************************************************/
; * DESCRIPTOR DE CODIGO */

CODE_SEL	equ	$-GDT		;para definir donde empieza el decriptor de código. <<<esto no gasta memoria, son macros para el compilador.>>>
      
code_desc:

limit_low:	dw	0xffff		;cantidad de direcciones del segmento.
base_15_0:	dw	0x0000		;todas las direcciones en 0 -> memoria flat.
base_23_16:	db	0x00
att_low:	db	10011011b	;PRESENTE / DPL=0 / NO DE SISEMA / 1 (codigo) / AJUSTABLE (nivel de priv.) / READABLE / ACCEDIDO.
att_high:	db	11001111b	;GRANULAR / SEGMENTO DE 32 BITS / NO ES IA-32e (64BITS) / BIT PARA EL USUARIO / PARTE ALTA DEL LIMITE.
base_31_24:	db	0x00

;***********************************************************************************/
; * DESCRIPTOR DE DATOS */

DATA_SEL	equ	$-GDT		;para definir donde empieza el descriptor de datos.

data_desc:

		dw	0xffff		;limite 15-0
		dw	0		;base 15-0
		db	0		;base 23-16
		db	10010011b	;atributos low.
		db	11001111b	;atributos high.
		db	0		;base 32-24.

;***********************************************************************************/
GDT_SIZE	equ	$-GDT		;tamaño de la GDT.

GDTR:

		dw	GDT_SIZE-1
		dd	GDT		; Direccion de inicio de la GDT.

CODE_LENGTH equ ($-start16)

times (RESET_VECTOR - ROM_START - CODE_LENGTH) nop
reset_vector:
	cli
	cld
	jmp 0xf000:start16
align 16
