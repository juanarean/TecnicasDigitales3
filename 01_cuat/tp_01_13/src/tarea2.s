SECTION  .tarea2 progbits
GLOBAL __tarea2
EXTERN vectores
EXTERN _cantidad

USE32
__tarea2:

    mov eax,[_cantidad]
    cmp eax,1
    jb _hlt
    mov ecx,[_sumados_t2]
    cmp ecx,eax
    je _hlt
    mov eax,[_sumatoria_t2]
    add eax,[vectores + 4*ecx]
    inc ecx
    mov [_sumados_t2],ecx
    mov [_sumatoria_t2],eax
    ;cmp eax,0x1fffffff
    ;ja _volver
    ;mov ecx,[eax]
    ;mov [_lectura_t2],ecx
_hlt:    
    hlt
    jmp __tarea2
    
;-------------------------------------------------    
SECTION	.tarea2_bss nobits alloc noexec write

GLOBAL _sumatoria
GLOBAL _sumados_t2

_sumatoria_t2:
    resb 4
    
_lectura_t2:
    resb 4
    
_sumados_t2:
    resb 4

;--------------------------------------------------
SECTION	.tarea2_datos

GLOBAL _DATO1


_DATO1_T2: db  0x01

