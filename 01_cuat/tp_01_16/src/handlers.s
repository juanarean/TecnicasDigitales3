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
GLOBAL td3_halt
GLOBAL td3_read
EXTERN tecla
EXTERN _tiempo
EXTERN _tiempo_t1
EXTERN _tiempo_t2
EXTERN _tiempo_t3
EXTERN _tiempo_t4
EXTERN __PDPT0
EXTERN __PDPT1
EXTERN __PDPT2
EXTERN __PDPT3
EXTERN __PDPT4
EXTERN tss_tarea0
EXTERN tss_tarea1
EXTERN tss_tarea2
EXTERN tss_tarea3
EXTERN tss_tarea4
EXTERN __tarea0
EXTERN __tarea1
EXTERN __tarea2
EXTERN __tarea3
EXTERN __tarea4
EXTERN _pag_nuevas
EXTERN _cant_tablas_pag
EXTERN __paginacion
EXTERN __PDPT
EXTERN _cantidad
EXTERN digitos
EXTERN vectores
EXTERN __STACK_START_T_PL0
EXTERN __STACK_START_T_PL3
EXTERN _mmxt0
EXTERN _mmxt1
EXTERN _mmxt2
EXTERN _mmxt3
EXTERN _mmxt4
EXTERN CODE_SEL
EXTERN DATA_SEL
;---------------------------------------------------------------
; Handlers
;---------------------------------------------------------------
; Handelr generico para que todas las excepsiones tengan una rutina de atención
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
; Handler que guarda los mmx cuando se intenta ejecutar una instruccion SIMD con cr0.ts=0.
HANDLER_IRQ_07:		    

    push eax
    push ebx
    push ecx
    push edx
    clts
    mov eax,cr3
    cmp eax,[__PDPT0]
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
; Handler de page fault, genera una nueva pagina mirando en CR2 que se quiso acceder.
HANDLER_IRQ_14:
xchg bx,bx
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
; SCHEDULER
HANDLER_TTICK:
; Primero veo en que tarea estoy y guardo el contexto.
    push    eax
    xor eax,eax
    mov ax,ds
    push    eax
    mov eax,cr3
    cmp eax,[__PDPT0]
    je  _guardar_t0
    cmp eax,[__PDPT1]
    je  _guardar_t1
    cmp eax,[__PDPT2]
    je _guardar_t2
    cmp eax,[__PDPT3]
    je _guardar_t3
    cmp eax,[__PDPT4]
    je _guardar_t4
    jmp _cambio_t0
    
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
    jmp _cambio_tarea
    
_guardar_t3:

    pop eax
    mov word [tss_tarea3+OFFSET_DS],ax
    mov word [tss_tarea3+OFFSET_ES],ax
    mov word [tss_tarea3+OFFSET_FS],ax
    mov word [tss_tarea3+OFFSET_GS],ax
    pop eax
    mov dword [tss_tarea3+OFFSET_EAX],eax
    mov dword [tss_tarea3+OFFSET_ECX],ebx
    mov dword [tss_tarea3+OFFSET_EDX],ecx
    mov dword [tss_tarea3+OFFSET_EBX],edx
    mov dword [tss_tarea3+OFFSET_EBP],ebp
    mov dword [tss_tarea3+OFFSET_ESI],esi
    mov dword [tss_tarea3+OFFSET_EDI],edi
    mov dword [tss_tarea3+OFFSET_ESP0],esp
    mov eax, cr0
    and eax, CR0_TS
    cmp eax, 0
    jne _cambio_tarea
    fxsave [_mmxt3]
    jmp _cambio_tarea
    
_guardar_t4:

    pop eax
    mov word [tss_tarea4+OFFSET_DS],ax
    mov word [tss_tarea4+OFFSET_ES],ax
    mov word [tss_tarea4+OFFSET_FS],ax
    mov word [tss_tarea4+OFFSET_GS],ax
    pop eax
    mov dword [tss_tarea4+OFFSET_EAX],eax
    mov dword [tss_tarea4+OFFSET_ECX],ebx
    mov dword [tss_tarea4+OFFSET_EDX],ecx
    mov dword [tss_tarea4+OFFSET_EBX],edx
    mov dword [tss_tarea4+OFFSET_EBP],ebp
    mov dword [tss_tarea4+OFFSET_ESI],esi
    mov dword [tss_tarea4+OFFSET_EDI],edi
    mov dword [tss_tarea4+OFFSET_ESP0],esp
    mov eax, cr0
    and eax, CR0_TS
    cmp eax, 0
    jne _cambio_tarea
    fxsave [_mmxt4]

    
_cambio_tarea:
; Verifico cual de las tareas cumplió su tiempo y voy a cambiar a esa tarea.
    mov eax,[_tiempo_t1]
    dec eax
    mov [_tiempo_t1],eax
    cmp eax,0
    je _cambio_t1
    
    mov eax,[_tiempo_t2]
    dec eax
    mov [_tiempo_t2],eax
    cmp eax,0
    je _cambio_t2
    
    mov eax,[_tiempo_t3]
    dec eax
    mov [_tiempo_t3],eax
    cmp eax,0
    je _cambio_t3
    
    mov eax,[_tiempo_t4]
    dec eax
    mov [_tiempo_t4],eax
    cmp eax,0
    je _cambio_t4

_cambio_t0:
    mov eax,cr3
    cmp eax,[__PDPT0]
    je __salida_hand_ttick      ;si ya estoy en la tarea no cargo nada y voy al IRET directamente
    mov eax,[__PDPT0]
    mov cr3,eax                 ;Cambio el arbol de paginacion.
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax                 ; pongo el TS en 0.
    mov al,20h                  ;Indicamos al PIC que finaliza la Interrupción
    out 20h,al  
    mov eax,[tss_tarea0+OFFSET_SS0] ; empiezo a cargar el contexto
    mov word ss,ax
    mov dword esp,[tss_tarea0+OFFSET_ESP0]
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
    cmp esp,__STACK_START_T_PL0 + 0x00001000
    jne _salto_1vezt0           ; si la pila nunca fue utilizada, entonces no puedo solo hacer IRET, tengo que poner en la pila los FLAGS, el CS y el IP.
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,[tss_tarea0+OFFSET_CS]
    push eax
    mov eax, __tarea0
    push eax
;    xchg bx,bx
_salto_1vezt0:
    mov dword eax,[tss_tarea0+OFFSET_EAX]
    jmp __IRET
    
_cambio_t1:

    mov eax,cr3
    cmp eax,[__PDPT1]
    je __salida_hand_ttick      ;si ya estoy en la tarea no cargo nada y voy al IRET directamente
    mov eax,[__PDPT1]
    mov cr3,eax                 ;Cambio el arbol de paginacion.
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax                 ; pongo el TS en 0.
    mov al,20h                  ;Indicamos al PIC que finaliza la Interrupción
    out 20h,al    
    mov dword esp,[tss_tarea1+OFFSET_ESP0] ; empiezo a cargar el contexto
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
    cmp esp,__STACK_START_T_PL0 + 0x00001000
    jne _salto_1vezt1           ; si la pila nunca fue utilizada, entonces no puedo solo hacer IRET, tengo que poner en la pila los FLAGS, el CS y el IP.
    mov dword eax,[tss_tarea1+OFFSET_SS]
    push eax
    mov dword eax,[tss_tarea1+OFFSET_ESP]
    push eax
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,[tss_tarea1+OFFSET_CS]
    push eax
    mov eax, __tarea1
    push eax
_salto_1vezt1:
    mov dword eax,[tss_tarea1+OFFSET_EAX]
    mov dword [_tiempo_t1],0xa
    jmp __IRET
    
_cambio_t2:

    mov eax,cr3
    cmp eax,[__PDPT2]
    je __salida_hand_ttick      ;si ya estoy en la tarea no cargo nada y voy al IRET directamente
    mov eax,[__PDPT2]
    mov cr3,eax                 ;Cambio el arbol de paginacion.
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax                 ; pongo el TS en 0.
    mov al,20h                  ;Indicamos al PIC que finaliza la Interrupción
    out 20h,al    
    mov dword esp,[tss_tarea2+OFFSET_ESP0] ; empiezo a cargar el contexto
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
    cmp esp,__STACK_START_T_PL0 + 0x00001000
    jne _salto_1vezt2           ; si la pila nunca fue utilizada, entonces no puedo solo hacer IRET, tengo que poner en la pila los FLAGS, el CS y el IP.
    mov dword eax,[tss_tarea1+OFFSET_SS]
    push eax
    mov dword eax,[tss_tarea1+OFFSET_ESP]
    push eax
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,[tss_tarea2+OFFSET_CS]
    push eax
    mov eax, __tarea2
    push eax
_salto_1vezt2:
    mov dword eax,[tss_tarea2+OFFSET_EAX]
    mov dword [_tiempo_t2],0x14
    jmp __IRET

_cambio_t3:

    mov eax,cr3
    cmp eax,[__PDPT3]
    je __salida_hand_ttick      ;si ya estoy en la tarea no cargo nada y voy al IRET directamente
    mov eax,[__PDPT3]
    mov cr3,eax                 ;Cambio el arbol de paginacion.
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax                 ; pongo el TS en 0.
    mov al,20h                  ;Indicamos al PIC que finaliza la Interrupción
    out 20h,al    
    mov dword esp,[tss_tarea3+OFFSET_ESP0] ; empiezo a cargar el contexto
    mov dword ebx,[tss_tarea3+OFFSET_ECX]
    mov dword ecx,[tss_tarea3+OFFSET_EDX]
    mov dword edx,[tss_tarea3+OFFSET_EBX]
    mov dword ebp,[tss_tarea3+OFFSET_EBP]
    mov dword esi,[tss_tarea3+OFFSET_ESI]
    mov dword edi,[tss_tarea3+OFFSET_EDI]
    mov word ax,[tss_tarea3+OFFSET_DS]
    mov word gs,ax
    mov word es,ax
    mov word fs,ax
    mov word ds,ax
    mov eax,esp
    cmp esp,__STACK_START_T_PL0 + 0x00001000
    jne _salto_1vezt3           ; si la pila nunca fue utilizada, entonces no puedo solo hacer IRET, tengo que poner en la pila los FLAGS, el CS y el IP.
    mov dword eax,[tss_tarea3+OFFSET_SS]
    push eax
    mov dword eax,[tss_tarea3+OFFSET_ESP]
    push eax
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,[tss_tarea3+OFFSET_CS]
    push eax
    mov eax, __tarea3
    push eax
_salto_1vezt3:
    mov dword eax,[tss_tarea3+OFFSET_EAX]
    mov dword [_tiempo_t3],0x20
    jmp __IRET
    
_cambio_t4:

    mov eax,cr3
    cmp eax,[__PDPT4]
    je __salida_hand_ttick      ;si ya estoy en la tarea no cargo nada y voy al IRET directamente
    mov eax,[__PDPT4]
    mov cr3,eax                 ;Cambio el arbol de paginacion.
    mov eax,cr0
    or  eax,CR0_TS
    mov cr0,eax                 ; pongo el TS en 0.
    mov al,20h                  ;Indicamos al PIC que finaliza la Interrupción
    out 20h,al    
    mov dword esp,[tss_tarea4+OFFSET_ESP0] ; empiezo a cargar el contexto
    mov dword ebx,[tss_tarea4+OFFSET_ECX]
    mov dword ecx,[tss_tarea4+OFFSET_EDX]
    mov dword edx,[tss_tarea4+OFFSET_EBX]
    mov dword ebp,[tss_tarea4+OFFSET_EBP]
    mov dword esi,[tss_tarea4+OFFSET_ESI]
    mov dword edi,[tss_tarea4+OFFSET_EDI]
    mov word ax,[tss_tarea4+OFFSET_DS]
    mov word gs,ax
    mov word es,ax
    mov word fs,ax
    mov word ds,ax
    mov eax,esp
    cmp esp,__STACK_START_T_PL0 + 0x00001000
    jne _salto_1vezt4           ; si la pila nunca fue utilizada, entonces no puedo solo hacer IRET, tengo que poner en la pila los FLAGS, el CS y el IP.
    mov dword eax,[tss_tarea4+OFFSET_SS]
    push eax
    mov dword eax,[tss_tarea4+OFFSET_ESP]
    push eax
    mov eax,0x200
    push eax
    xor eax,eax
    mov ax,[tss_tarea4+OFFSET_CS]
    push eax
    mov eax, __tarea4
    push eax
_salto_1vezt4:
    mov dword eax,[tss_tarea4+OFFSET_EAX]
    mov dword [_tiempo_t4],0x2a
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
    jc __salida_hand_teclado    ; si se soltó la tecla salgo del hanlder

_test_tecla:      
      mov ecx, 9
      mov ebx, 2
_comparaciones:                 ; comparo del 0 al 9
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
    mov ebx,[digitos]
    and ebx,0xf0000000
    shr ebx,28
    mov ecx,[digitos+4]
    and ecx,0x0fffffff
    shl ecx,4
    or cl,bl
    mov ebx,[digitos]
    shl ebx,4
    or bl,al
    mov [tecla], al
    mov [digitos+4],ecx
    mov [digitos],ebx
    jmp __salida_hand_teclado
    
_grabar_vector:
    mov edx,[_cantidad]
    mov eax,[digitos]
    mov [vectores + 8*edx],eax
    mov eax,[digitos+4]
    mov [vectores + 8*edx + 4],eax
    inc edx
    mov [_cantidad],edx
    xor eax,eax
    mov [tecla], al
    mov [digitos],eax
    mov [digitos+4],eax
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
; SYSCALL de lectura de vector de teclas
td3_read:
    push ebp
    mov ebp,esp
       
    push ebx
    push ecx
    push edx
    
    xor eax,eax
    mov esi,vectores
    mov edi,[ebp+16]
    mov ecx,[ebp+12]
    cmp ecx,0
    je ret_read
    mov edx,[_cantidad]
    cmp edx,0
    je ret_read
    shl edx,3
    cmp edx,ecx
    jae loop_read
    mov ecx,edx
loop_read:
    mov bl,[esi]
    mov [edi],bl
    inc esi
    inc edi
    inc eax
    loop loop_read
    
ret_read:    
    pop edx
    pop ecx
    pop ebx
    pop ebp
    retf 8
    
;------------------------------------------------------------------------
; SYSCALL halt
td3_halt:
    hlt
    retf
        
