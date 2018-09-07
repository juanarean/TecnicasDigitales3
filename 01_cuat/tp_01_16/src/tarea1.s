SECTION  .tarea1 progbits
GLOBAL __tarea1
EXTERN vectores
EXTERN _cantidad
EXTERN SYSCALL_1_SEL
EXTERN SYSCALL_2_SEL

USE32
__tarea1:

    mov eax,_buffer_t1
    push eax            ; le envio donde copiar los datos
    mov ecx,[_sumados_t1]
    inc ecx
    shl ecx,3
    push ecx            ; le envio cuantos bytes copiar
    call SYSCALL_1_SEL:0
    cmp eax,ecx
    jb _hlt     ;si lo que se leyo es menor a lo que se pidio no hago la suma, no hay datos nuevos.
    movq mm2,[_sumatoria_t1]
    paddb mm2,[_buffer_t1 + eax-8]
    shr ecx,3
    mov [_sumados_t1],ecx
    movq [_sumatoria_t1],mm2

_hlt:    
    call SYSCALL_2_SEL:0
    jmp __tarea1
    
;-------------------------------------------------    
SECTION	.tarea1_bss nobits alloc noexec write

GLOBAL _sumatoria_t1
GLOBAL _sumados_t1

_sumatoria_t1:
    resb 8
    
_lectura_t1:
    resb 4
    
_sumados_t1:    ; lleva la cuanta de cuantos numeros se fueron sumando.
    resb 4

_buffer_t1: 
    resb 8

;--------------------------------------------------
SECTION	.tarea1_datos progbits

GLOBAL _DATO1


_DATO1_T1: db  0x01

