SECTION  .tarea3 progbits
GLOBAL __tarea3
EXTERN vectores
EXTERN _cantidad
EXTERN SYSCALL_1_SEL
EXTERN SYSCALL_2_SEL

USE32
__tarea3:
;xchg bx,bx
    mov eax,_buffer_t3
    push eax
    mov ecx,[_sumados_t3]
    inc ecx
    shl ecx,3
    push ecx
    call SYSCALL_1_SEL:0
    cmp eax,ecx
    jb _hlt
    movq mm2,[_sumatoria_t3]
    paddsb mm2,[_buffer_t3 + eax-8]
    shr ecx,3
    mov [_sumados_t3],ecx
    movq [_sumatoria_t3],mm2

_hlt:    
    call SYSCALL_2_SEL:0
    jmp __tarea3
    
;-------------------------------------------------    
SECTION	.tarea3_bss nobits alloc noexec write

GLOBAL _sumatoria_t3
GLOBAL _sumados_t3

_sumatoria_t3:
    resb 8
    
_lectura_t3:
    resb 4
    
_sumados_t3:
    resb 4

_buffer_t3:
    resb 8

;--------------------------------------------------
SECTION	.tarea3_datos progbits

GLOBAL _DATO3


_DATO1_T3: db  0x01

