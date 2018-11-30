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
EXTERN _tiempo_t3
EXTERN _tiempo_t4
EXTERN __print_inicio

%define CR4_MASK 0x00000600
%define TIEMPOT1 0x0000000a
%define TIEMPOT2 0x00000014
%define TIEMPOT3 0x0000001e
%define TIEMPOT4 0x00000028

USE32
kernel32_main:
;xchg bx,bx
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

mov eax,cr4
or  eax,CR4_MASK

xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx

mov [digitos],eax       ;seteo en 0 las variables que voy a utilizar.
mov [_cantidad],eax		;mov [_pag_nuevas],eax

mov dword [_tiempo_t1],TIEMPOT1     ;Seteo los tiempos en que se ejecuta cada tarea.
mov dword [_tiempo_t2],TIEMPOT2
mov dword [_tiempo_t3],TIEMPOT3
mov dword [_tiempo_t4],TIEMPOT4

mov ax,SEL_TSS_TAREA0
ltr ax           ;Para poder hacer cambios de tarea tengo que poner cualquier selector de tarea con ts=0 (task no busy). para poder hacer el cambio manual. si fuera automatico el procesador se encarga de chequear y modificar este bit.

xor eax,eax

;xchg bx,bx
mov eax,0x0000b8002
mov byte [eax], 0x1e
call __print_inicio

sti     ; habilito interrupciones.
_bucle_main:

hlt         ; quedo aca hasta que salta la primera interrupcion del timer.
jmp _bucle_main

