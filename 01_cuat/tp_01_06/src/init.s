%include "./inc/processor-flags.h"

SECTION .kernel16
GLOBAL start16
GLOBAL A20_Enable_No_Stack_return
GLOBAL bios_init_return
EXTERN __STACK_START_16
EXTERN __STACK_END_16
EXTERN GDTR
EXTERN CODE_SEL
EXTERN DATA_SEL
EXTERN A20_Enable_No_Stack
EXTERN bios_init

USE16
start16:
   test eax, 0x0             ;Verificar que el uP no este en fallo
   jne ..@fault_end

   xor eax, eax
   mov cr3, eax             ;Invalidar TLB
   
   mov ax, __STACK_START_16
   mov ss, ax
   mov sp, __STACK_END_16

   jmp A20_Enable_No_Stack
   A20_Enable_No_Stack_return:
  
   jmp bios_init
   bios_init_return:

    o32 lgdt [cs:GDTR]             ;Cargo la GDT
    
; Establecer el up en Modo protegido:
	mov eax,cr0				; 
	or al,1					; 
	mov cr0,eax				; solo pongo en "1" el bit menos significaivo del CR0.
    
    jmp .flush_prefech_queue
    .flush_prefech_queue:        ;esto es para limpiar el pipeline porque cambié a modo protegido, lo que estaba en el pipeline ya no sirve.

    o32 jmp dword CODE_SEL:kernel32_init

..@fault_end:
   hlt
   jmp ..@fault_end

SECTION  .init32 progbits
EXTERN __STACK_END_32
EXTERN __STACK_SIZE_32
EXTERN DS_SEL
EXTERN CS_SEL_32
EXTERN kernel32_main
EXTERN __fast_memcpy
EXTERN ___kernel_size
EXTERN ___kernel_vma_st
EXTERN ___kernel_lma_st
EXTERN ___rutinas_size
EXTERN ___rutinas_vma_st
EXTERN ___rutinas_lma_st

USE32
kernel32_init:
   ;->Inicializar la pila   
   mov ax, DATA_SEL
   mov ss, ax
   mov esp, __STACK_END_32
   ;->Inicializar la pila   
   xor ebx, ebx
   mov ecx, __STACK_SIZE_32
   .stack_init:
      push ebx
      loop .stack_init
   mov esp, __STACK_END_32

   ;->Inicializar la selectores datos
   mov ds, ax
   mov es, ax
   mov gs, ax
   mov fs, ax

   ;->Desempaquetar la ROM
   ;-->kernel
   push ebp
   mov ebp, esp
   push ___kernel_size
   push ___kernel_vma_st
   push ___kernel_lma_st
   call __fast_memcpy
   leave
   cmp eax, 1           ;Analizo el valor de retorno (1 Exito -1 Fallo)
   jne .guard
   
   ;Desempaquetar rutinas
   push ebp
   mov ebp, esp
   push ___rutinas_size
   push ___rutinas_vma_st
   push ___rutinas_lma_st
   call __fast_memcpy
   leave
   cmp eax, 1           ;Analizo el valor de retorno (1 Exito -1 Fallo)
   jne .guard

   jmp CODE_SEL:kernel32_main

   .guard:
      hlt
      jmp .guard