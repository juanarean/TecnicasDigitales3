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
EXTERN _pag_nuevas
EXTERN _cant_tablas_pag
EXTERN __paginacion
EXTERN __PDPT
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

    push eax
    
    mov eax,[_cant_tablas_pag]
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,[_pag_nuevas]   ;paginas nuevas agregadas por este metodo
    shl eax,12               ;multiplico por 0x1000
    add eax,0x10000000      ;le agrego la base fisica de las nuevas paginas
    push eax
    mov eax,CR2    ;direccion a la que quise leer
    and eax,0x1ffff000      ;alineado a 4k
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    mov [_cant_tablas_pag],eax

    mov eax,[_pag_nuevas]
    inc eax
    mov [_pag_nuevas],eax
    
    pop eax
    
    add esp,4   ;saco el error code
    iret
;--------------------------------------------------------------------

HANDLER_TTICK:
		push eax
		mov eax, [_tiempo]
		inc eax
		mov [_tiempo],eax

		;------------EOI1----------------------------
		mov al,20h	;Indicamos al PIC que finaliza la Interrupción
		out 20h,al
		;-------------------------------------------
        pop eax
		iret
		    
;------------------------------------------------------------------------
		   
HANDLER_TECLADO:	
    xor eax,eax
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


 
