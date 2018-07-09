SECTION  .tarea1 progbits
GLOBAL __tarea1
EXTERN vectores
EXTERN _cantidad

USE32
__tarea1:
   
    mov eax,[_cantidad]
    cmp eax,1
    jb _hlt
    mov ecx,[_sumados_t1]
    cmp ecx,eax
    je _hlt
    movq mm2,[_sumatoria_t1]
    paddb mm2,[vectores + 8*ecx]
    inc ecx
    mov [_sumados_t1],ecx
    movq [_sumatoria_t1],mm2

    ;cmp eax,0x1fffffff
    ;ja _volver
    ;mov ecx,[eax]
    ;mov [_lectura_t1],ecx
_hlt:    
    hlt
    jmp __tarea1
    
;-------------------------------------------------    
SECTION	.tarea1_bss nobits alloc noexec write

GLOBAL _sumatoria_t1
GLOBAL _sumados_t1

_sumatoria_t1:
    resb 8
    
_lectura_t1:
    resb 4
    
_sumados_t1:
    resb 4

;--------------------------------------------------
SECTION	.tarea1_datos progbits

GLOBAL _DATO1


_DATO1_T1: db  0x01

