SECTION .ISR_HANDLERS

GLOBAL HANDLER_IRQ_GEN
GLOBAL HANDLER_IRQ_00
GLOBAL HANDLER_IRQ_06
GLOBAL HANDLER_IRQ_08
GLOBAL HANDLER_IRQ_13
GLOBAL HANDLER_IRQ_14
GLOBAL HANDLER_TTICK
GLOBAL HANDLER_TECLADO
EXTERN tecla
EXTERN _tiempo
;---------------------------------------------------------------
; Handlers
;---------------------------------------------------------------
HANDLER_IRQ_GEN:		    

			xchg bx,bx
			mov dx,0XFF
		    ;------------EOI----------------------------
		    mov al,20h	;Indicamos al PIC que finaliza la Interrupción
		    out 20h,al
		    ;-------------------------------------------
		    iret
;--------------------------------------------------------------------

HANDLER_IRQ_00:		    

			xchg bx,bx
			mov dx,0x00
			mov eax,0x1
		    iret
;--------------------------------------------------------------------

HANDLER_IRQ_06:		    

			xchg bx,bx
			mov dx,0x06
		    iret
;--------------------------------------------------------------------

HANDLER_IRQ_08:		    

			xchg bx,bx
			mov dx,0x08
		    iret
;--------------------------------------------------------------------

HANDLER_IRQ_13:		    

			xchg bx,bx
			mov dx,0x13
		    iret
;--------------------------------------------------------------------

HANDLER_IRQ_14:		    

			xchg bx,bx
			mov dx,0x14
		    iret
;--------------------------------------------------------------------

HANDLER_TTICK:

		mov eax, [_tiempo]
		inc eax
		mov [_tiempo],eax
;		xchg bx,bx
		;------------EOI1----------------------------
		mov al,20h	;Indicamos al PIC que finaliza la Interrupción
		out 20h,al
		;-------------------------------------------
		iret
		    
;------------------------------------------------------------------------
		   
HANDLER_TECLADO:	

    in al, 0x60
    bt ax,7
    jc __salida_hand_teclado
    mov [tecla], al

__salida_hand_teclado:
		    ;------------EOI----------------------------
		    mov al,20h	;Indicamos al PIC que finaliza la Interrupción
		    out 20h,al
		    ;-------------------------------------------
		    iret

;------------------------------------------------------------------------


 
