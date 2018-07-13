SECTION  .tarea2 progbits
GLOBAL __tarea2
EXTERN vectores
EXTERN _cantidad
EXTERN SYSCALL_1_SEL
EXTERN SYSCALL_2_SEL

USE32
__tarea2:
;xchg bx,bx
    mov eax,_buffer_t2
    push eax
    mov ecx,[_sumados_t2]
    inc ecx
    shl ecx,3
    push ecx
    call SYSCALL_1_SEL:0
    pop ecx
    add esp,4
    cmp eax,ecx
    jb _hlt
    xchg bx,bx  
    movq mm2,[_sumatoria_t2]
    paddb mm2,[_buffer_t2 + 8*ecx]
    mov [_sumados_t2],ecx
    movq [_sumatoria_t2],mm2
  
    ;cmp eax,0x1fffffff
    ;ja _volver
    ;mov ecx,[eax]
    ;mov [_lectura_t2],ecx
_hlt:    
    call SYSCALL_2_SEL:0
    jmp __tarea2
    
;-------------------------------------------------    
SECTION	.tarea2_bss nobits alloc noexec write

GLOBAL _sumatoria
GLOBAL _sumados_t2

_sumatoria_t2:
    resb 8
    
_lectura_t2:
    resb 4
    
_sumados_t2:
    resb 4
    
_buffer_t2:
    resb 8

;--------------------------------------------------
SECTION	.tarea2_datos

GLOBAL _DATO1


_DATO1_T2: db  0x01

