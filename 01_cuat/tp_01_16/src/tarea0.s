SECTION  .tarea0 progbits
GLOBAL __tarea0
EXTERN vectores
EXTERN _cantidad
EXTERN SYSCALL_2_SEL

USE32
__tarea0:
;xchg bx,bx
    call SYSCALL_2_SEL:0
    jmp __tarea0
    
;-------------------------------------------------    
SECTION	.tarea0_bss nobits alloc noexec write

_dato_no_init_t0:
    resb 1

;--------------------------------------------------
SECTION	.tarea0_datos

_DATO1_T0: db  0x01

