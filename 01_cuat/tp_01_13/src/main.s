SECTION  .kernel32 progbits
GLOBAL kernel32_main
EXTERN tecla
EXTERN digitos
EXTERN vectores
EXTERN _tiempo
EXTERN _cantidad
EXTERN GDTR
EXTERN CODE_SEL
EXTERN DATA_SEL
EXTERN IDTR
EXTERN __tarea0
EXTERN _pag_nuevas
EXTERN _sumados_t1
EXTERN _sumados_t2
EXTERN SEL_TSS_TAREA0
EXTERN SEL_TSS_TAREA1
EXTERN SEL_TSS_TAREA2
EXTERN _tiempo_t1
EXTERN _tiempo_t2

USE32
kernel32_main:

lgdt [cs:GDTR]
mov ax, DATA_SEL
mov ds, ax
mov ds, ax
mov es, ax
mov gs, ax
mov fs, ax
jmp CODE_SEL:CargaIDT

CargaIDT:
lidt [cs:IDTR]
mov     al,11111100b
out     21h,al 

xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx

mov [digitos],eax
mov [_cantidad],eax
mov [_pag_nuevas],eax
mov [_sumados_t1],eax
mov [_sumados_t2],eax

mov dword [_tiempo_t1],0x0000000a
mov dword [_tiempo_t2],0x00000015

sti


xchg bx,bx
jmp __tarea0
