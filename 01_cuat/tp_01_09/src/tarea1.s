SECTION  .tarea1 progbits
GLOBAL __tarea1
EXTERN vectores
EXTERN _cantidad
EXTERN _sumatoria

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

