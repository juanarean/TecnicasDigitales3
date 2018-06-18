SECTION  .tarea1 progbits
GLOBAL __tarea1
EXTERN vectores
EXTERN _cantidad

USE32
__tarea1:

    push ebp
    mov ebp, esp
    xor ecx,ecx
    mov ecx,[_cantidad]
    cmp ecx,1
    jbe _volver
    xor eax,eax
    dec ecx
_lazo:
    add eax,[vectores + 4*ecx]
    loop _lazo
    add eax,[vectores]
    
    mov [_sumatoria],eax
    
_volver:
    leave
    ret
    
;-------------------------------------------------    
SECTION	.tarea1_bss nobits alloc noexec write

GLOBAL _sumatoria


_sumatoria:
    resb 4

;--------------------------------------------------
SECTION	.tarea1_datos

GLOBAL _DATO1


_DATO1: db  0x01

