SECTION  .tarea4 progbits
GLOBAL __tarea4
EXTERN vectores
EXTERN _cantidad
EXTERN SYSCALL_1_SEL
EXTERN SYSCALL_2_SEL

USE32
__tarea4:
;xchg bx,bx
    mov eax,_buffer_t4
    push eax
    mov ecx,[_sumados_t4]
    inc ecx
    shl ecx,3
    push ecx
    call SYSCALL_1_SEL:0
    cmp eax,ecx
    jb _hlt
    movq mm2,[_sumatoria_t4]
    paddusb mm2,[_buffer_t4 + eax-8]
    shr ecx,3
    mov [_sumados_t4],ecx
    movq [_sumatoria_t4],mm2

_hlt:    
    call SYSCALL_2_SEL:0
    jmp __tarea4
    
;-------------------------------------------------    
SECTION	.tarea4_bss nobits alloc noexec write

GLOBAL _sumatoria_t4
GLOBAL _sumados_t4

_sumatoria_t4:
    resb 8
    
_lectura_t4:
    resb 4
    
_sumados_t4:
    resb 4

_buffer_t4:
    resb 8

;--------------------------------------------------
SECTION	.tarea4_datos progbits

GLOBAL _DATO4


_DATO1_T4: db  0x01

