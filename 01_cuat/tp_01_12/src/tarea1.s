SECTION  .tarea1 progbits
GLOBAL __tarea1
EXTERN vectores
EXTERN _cantidad

USE32
__tarea1:

    mov eax,[_cantidad]
    cmp eax,1
    jb _volver
    mov ecx,[_sumados]
    cmp ecx,eax
    je _volver
    mov eax,[_sumatoria]
    add eax,[vectores + 4*ecx]
    inc ecx
    mov [_sumados],ecx
    mov [_sumatoria],eax
    cmp eax,0x1fffffff
    ja _volver
    mov ecx,[eax]
    mov [_lectura],ecx
    
_volver:
    ret
    
;-------------------------------------------------    
SECTION	.tarea1_bss nobits alloc noexec write

GLOBAL _sumatoria
GLOBAL _sumados

_sumatoria:
    resb 4
    
_lectura:
    resb 4
    
_sumados:
    resb 4

;--------------------------------------------------
SECTION	.tarea1_datos

GLOBAL _DATO1


_DATO1: db  0x01

