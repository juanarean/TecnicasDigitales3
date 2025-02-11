SECTION .ISR_HANDLERS

;/*
;* OFFSETS TSS
;*/
%define OFFSET_BACKLINK   0
%define OFFSET_ESP0       4
%define OFFSET_SS0        8
%define OFFSET_ESP1       12
%define OFFSET_SS1        16
%define OFFSET_ESP2       20
%define OFFSET_SS2        24
%define OFFSET_CR3        28
%define OFFSET_EIP        32
%define OFFSET_EFLAGS     36
%define OFFSET_EAX        40
%define OFFSET_ECX        44
%define OFFSET_EDX        48
%define OFFSET_EBX        52
%define OFFSET_ESP        56
%define OFFSET_EBP        60
%define OFFSET_ESI        64
%define OFFSET_EDI        68
%define OFFSET_ES         72
%define OFFSET_CS         76
%define OFFSET_SS         80
%define OFFSET_DS         84
%define OFFSET_FS         88
%define OFFSET_GS         92
%define OFFSET_LDT        96
%define OFFSET_T          100
%define OFFSET_BITMAP     102
%define CR0_TS            0x00000008

GLOBAL HANDLER_IRQ_GEN
GLOBAL HANDLER_IRQ_00
GLOBAL HANDLER_IRQ_06
GLOBAL HANDLER_IRQ_07
GLOBAL HANDLER_IRQ_08
GLOBAL HANDLER_IRQ_13
GLOBAL HANDLER_IRQ_14
GLOBAL HANDLER_TTICK
GLOBAL HANDLER_TECLADO
EXTERN tecla
EXTERN _tiempo
EXTERN _tiempo_t1
EXTERN _tiempo_t2
EXTERN __PDPT1
EXTERN __PDPT2
EXTERN tss_tarea0
EXTERN tss_tarea1
EXTERN tss_tarea2
EXTERN __tarea0
EXTERN __tarea1
EXTERN __tarea2
EXTERN _pag_nuevas
EXTERN _cant_tablas_pag
EXTERN __paginacion
EXTERN __PDPT
EXTERN _cantidad
EXTERN digitos
EXTERN vectores
EXTERN __STACK_START_32
EXTERN __STACK_START_T1
EXTERN __STACK_START_T2
EXTERN _mmxt0
EXTERN _mmxt1
EXTERN _mmxt2
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
		    iret
;--------------------------------------------------------------------

HANDLER_IRQ_06:		    

    xchg bx,bx
    mov dx,0x06
    iret
    
;--------------------------------------------------------------------

HANDLER_IRQ_07:		    

    push eax
    push ebx
    push ecx
    push edx
    clts
    mov eax,cr3
    cmp eax,__PDPT
    je _salvar_mmxt0
    cmp eax,[__PDPT1]
    je _salvar_mmxt1
    fxrstor [_mmxt2]
    jmp __salida_hand07
_salvar_mmxt0:
    fxrstor [_mmxt0]
    jmp __salida_hand07
_salvar_mmxt1:
    fxrstor [_mmxt1]
    
__salida_hand07:
    pop edx
    pop ecx
    pop ebx
    pop eax
    
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
;xchg bx,bx
    push    eax
    xor eax,eax
    mov ax,ds
    push    eax
    mov eax,cr3
    cmp eax,__PDPT
    je  _guardar_t0
    cmp eax,[__PDPT1]
    je  _guardar_t1
    jmp _guardar_t2
    
_guardar_t0:
    pop eax
    mov word [tss_tarea0+OFFSET_DS],ax
    mov word [tss_tarea0+OFFSET_ES],ax
    mov word [tss_tarea0+OFFSET_FS],ax
    mov word [tss_tarea0+OFFSET_GS],ax
    pop eax
    mov dword [tss_tarea0+OFFSET_EAX],eax
    mov dword [tss_tarea0+OFFSET_ECX],ebx
    mov dword [tss_tarea0+OFFSET_EDX],ecx
    mov dword [tss_tarea0+OFFSET_EBX],edx
    mov dword [tss_tarea0+OFFSET_EBP],ebp
    mov dword [tss_tarea0+OFFSET_ESI],esi
    mov dword [tss_tarea0+OFFSET_EDI],edi
    mov dword [tss_tarea0+OFFSET_ESP0],esp
    mov eax, cr0
    and eax, CR0_TS
    cmp eax, 0
    jne _cambio_tarea
    fxsave [_mmxt0]
    jmp _cambio_tarea
    
 _guardar_t1:
; xchg bx,bx
    pop eax
    mov word [tss_tarea1+OFFSET_DS],ax
    mov word [tss_tarea1+OFFSET_ES],ax
    mov word [tss_tarea1+OFFSET_FS],ax
    mov word [tss_tarea1+OFFSET_GS],ax
    pop eax
    mov dword [tss_tarea1+OFFSET_EAX],eax
    mov dword [tss_tarea1+OFFSET_ECX],ebx
    mov dword [tss_tarea1+OFFSET_EDX],ecx
    mov dword [tss_tarea1+OFFSET_EBX],edx
    mov dword [tss_tarea1+OFFSET_EBP],ebp
    mov dword [tss_tarea1+OFFSET_ESI],esi
    mov dword [tss_tarea1+OFFSET_EDI],edi
    mov dword [tss_tarea1+OFFSET_ESP0],esp  
    mov eax, cr0
    and eax, CR0_TS
    cmp eax, 0
    jne _cambio_tarea
    fxsave [_mmxt1]
    jmp _cambio_tarea
    
_guardar_t2:

    pop eax
    mov word [tss_tarea2+OFFSET_DS],ax
    mov word [tss_tarea2+OFFSET_ES],ax
    mov word [tss_tarea2+OFFSET_FS],ax
    mov word [tss_tarea2+OFFSET_GS],ax
    pop eax
    mov dword [tss_tarea2+OFFSET_EAX],eax
    mov dword [tss_tarea2+OFFSET_ECX],ebx
    mov dword [tss_tarea2+OFFSET_EDX],ecx
    mov dword [tss_tarea2+OFFSET_EBX],edx
    mov dword [tss_tarea2+OFFSET_EBP],ebp
    mov dword [tss_tarea2+OFFSET_ESI],esi
    mov dword [tss_tarea2+OFFSET_EDI],edi
    mov dword [tss_tarea2+OFFSET_ESP0],esp
    mov eax, cr0
    and eax, CR0_TS
    cmp eax, 0
    jne _cambio_tarea
    fxsave [_mmxt2]
    
_cambio_tarea:
    mov eax,[_tiempo_t1]
    mov ebx,[_tiempo_t2]
    dec eax
    dec ebx
    mov [_tiempo_t1],eax
    mov [_tiempo_t2],ebx
    cmp eax,0
    je _cambio_t1
    cmp ebx,0
    je _cambio_t2

_cambio_t0:
    mov eax,cr3
    cmp eax,__PDPT
    je __salida_hand_ttick
 ;   xchg bx,bx
    mov eax,__PDPT
    mov cr3,eax
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax
    mov al,20h	;Indicamos al PIC que finaliza la Interrupción
    out 20h,al    
    mov dword esp,[tss_tarea0+OFFSET_ESP0]
    ;mov dword eax,[tss_tarea0+OFFSET_EAX]
    mov dword ebx,[tss_tarea0+OFFSET_ECX]
    mov dword ecx,[tss_tarea0+OFFSET_EDX]
    mov dword edx,[tss_tarea0+OFFSET_EBX]
    mov dword ebp,[tss_tarea0+OFFSET_EBP]
    mov dword esi,[tss_tarea0+OFFSET_ESI]
    mov dword edi,[tss_tarea0+OFFSET_EDI]
    mov word ax,[tss_tarea0+OFFSET_DS]
    mov word gs,ax
    mov word es,ax
    mov word fs,ax
    mov word ds,ax
    mov eax,esp
    cmp esp,__STACK_START_32 + 0x00000fff
    jne _salto_1vezt0
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,cs
    push eax
    mov eax, __tarea0
    push eax
;    xchg bx,bx
_salto_1vezt0:
    mov dword eax,[tss_tarea0+OFFSET_EAX]
    jmp __IRET
    
_cambio_t1:
;xchg bx,bx
    mov eax,cr3
    cmp eax,[__PDPT1]
    je __salida_hand_ttick
    mov eax,[__PDPT1]
    mov cr3,eax
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax
    mov al,20h	;Indicamos al PIC que finaliza la Interrupción
    out 20h,al    
    mov dword esp,[tss_tarea1+OFFSET_ESP0]
    ;mov dword eax,[tss_tarea1+OFFSET_EAX]
    mov dword ebx,[tss_tarea1+OFFSET_ECX]
    mov dword ecx,[tss_tarea1+OFFSET_EDX]
    mov dword edx,[tss_tarea1+OFFSET_EBX]
    mov dword ebp,[tss_tarea1+OFFSET_EBP]
    mov dword esi,[tss_tarea1+OFFSET_ESI]
    mov dword edi,[tss_tarea1+OFFSET_EDI]
    mov word ax,[tss_tarea1+OFFSET_DS]
    mov word gs,ax
    mov word es,ax
    mov word fs,ax
    mov word ds,ax
    mov eax,esp
    cmp esp,__STACK_START_T1 + 0x00000fff
    jne _salto_1vezt1
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,cs
    push eax
    mov eax, __tarea1
    push eax
;    xchg bx,bx
_salto_1vezt1:
    mov dword eax,[tss_tarea1+OFFSET_EAX]
    mov dword [_tiempo_t1],0xa
    jmp __IRET
    
_cambio_t2:
;xchg bx,bx
    mov eax,cr3
    cmp eax,[__PDPT2]
    je __salida_hand_ttick
    mov eax,[__PDPT2]
    mov cr3,eax
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax
    mov al,20h	;Indicamos al PIC que finaliza la Interrupción
    out 20h,al    
    mov dword esp,[tss_tarea2+OFFSET_ESP0]
    ;mov dword eax,[tss_tarea1+OFFSET_EAX]
    mov dword ebx,[tss_tarea2+OFFSET_ECX]
    mov dword ecx,[tss_tarea2+OFFSET_EDX]
    mov dword edx,[tss_tarea2+OFFSET_EBX]
    mov dword ebp,[tss_tarea2+OFFSET_EBP]
    mov dword esi,[tss_tarea2+OFFSET_ESI]
    mov dword edi,[tss_tarea2+OFFSET_EDI]
    mov word ax,[tss_tarea2+OFFSET_DS]
    mov word gs,ax
    mov word es,ax
    mov word fs,ax
    mov word ds,ax
    mov eax,esp
    cmp esp,__STACK_START_T2 + 0x00000fff
    jne _salto_1vezt2
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,cs
    push eax
    mov eax, __tarea2
    push eax
;    xchg bx,bx
_salto_1vezt2:
    mov dword eax,[tss_tarea2+OFFSET_EAX]
    mov dword [_tiempo_t2],0x14
    jmp __IRET
    
    
__salida_hand_ttick:
    mov al,20h	;Indicamos al PIC que finaliza la Interrupción
    out 20h,al  
__IRET:
    iretd
  
;------------------------------------------------------------------------
   
HANDLER_TECLADO:	

    push eax
    push ebx
    push ecx
    push edx
    
    xor eax,eax
    in al, 0x60
    bt ax,7
    jc __salida_hand_teclado

_test_tecla:      
      mov ecx, 9
      mov ebx, 2
_comparaciones:      
      cmp al, bl           
      jne _sig_comp
      dec al
      jmp _grabar_tecla
_sig_comp:
        inc bl
        loop _comparaciones

_comp_A:
      cmp al, 0x1e          ; tecla A
      jne _comp_B
      mov al, 0xA
      je _grabar_tecla
_comp_B:      
      cmp al, 0x30          ; tecla B
      jne _comp_C
      mov al,0xB
      je _grabar_tecla
_comp_C:      
      cmp al, 0x2e          ; tecla C
      jne _comp_D
      mov al, 0xC
      je _grabar_tecla
_comp_D:      
      cmp al, 0x20          ; tecla D
      jne _comp_E
      mov al, 0xD
      je _grabar_tecla
_comp_E:      
      cmp al, 0x12          ; tecla E
      jne _comp_F
      mov al, 0xE
      je _grabar_tecla
_comp_F:      
      cmp al, 0x21          ; tecla F
      jne _comp_0
      mov al, 0xF
      je _grabar_tecla
_comp_0:      
      cmp al, 0x0b          ; tecla 0
      jne _comp_Enter
      mov al, 0x00
      je _grabar_tecla
_comp_Enter:
      cmp al, 0x1c          ; tecla ENTER
      je _grabar_vector
      xor eax,eax
      mov [tecla], al
      jmp __salida_hand_teclado
      
   
_grabar_tecla:

    movq mm0,[digitos]
    psllq mm0,4
    movd mm1,eax
    por mm0,mm1
    movq [digitos],mm0
    xor eax,eax
    mov [tecla], al
    jmp __salida_hand_teclado
    
_grabar_vector:
    mov edx,[_cantidad]
    movq mm0,[digitos]
    movq [vectores + 8*edx],mm0
    add edx,1
    mov [_cantidad],edx
    xor eax,eax
    mov [tecla], al
    pxor mm0,mm0
    movq [digitos],mm0
    jmp __salida_hand_teclado
    
__salida_hand_teclado:
    pop edx
    pop ecx
    pop ebx
    pop eax
;------------EOI----------------------------
   mov al,20h	;Indicamos al PIC que finaliza la Interrupción
   out 20h,al
;-------------------------------------------
   iretd

;------------------------------------------------------------------------


 
