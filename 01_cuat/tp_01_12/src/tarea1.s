SECTION  .tarea1 progbits
GLOBAL __tarea1
EXTERN vectores
EXTERN _cantidad

USE32
__tarea1:

    xor ecx,ecx
    mov ecx,[_cantidad]
    cmp ecx,1
    jbe _volver
    xor eax,eax
    dec ecx
_suma:
    add eax,[vectores + 4*ecx]
    loop _suma
    add eax,[vectores]
 xchg bx,bx  
 ;pop eax
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


_sumatoria:
    resb 4
    
_lectura:
    resb 4

;--------------------------------------------------
SECTION	.tarea1_datos

GLOBAL _DATO1


_DATO1: db  0x01

