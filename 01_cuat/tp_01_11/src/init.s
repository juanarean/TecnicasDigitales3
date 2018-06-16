%include "./inc/processor-flags.h"

SECTION .kernel16
GLOBAL start16
EXTERN __STACK_START_16
EXTERN __STACK_END_16
EXTERN GDTR
EXTERN CODE_SEL
EXTERN DATA_SEL
EXTERN A20_Enable
EXTERN PIC_Config
EXTERN PIT_Set_100mseg

USE16
start16:
   test eax, 0x0             ;Verificar que el uP no este en fallo
   jne ..@fault_end

   xor eax, eax
   mov cr3, eax             ;Invalidar TLB
   
   mov ax, __STACK_START_16
   mov ss, ax
   mov sp, __STACK_END_16

   call A20_Enable
   
    mov bl,0x20     ;PIC #2 - Pasamos los datos a cargar a la función por medio de los Registros BL y BH
    mov bh,0x28     ;PIC #1
    call PIC_Config
    call PIT_Set_100mseg
    
    o32 lgdt [cs:GDTR16]             ;Cargo la GDT
    
; Establecer el up en Modo protegido:
	mov eax,cr0				; 
	or al,1					; 
	mov cr0,eax				; solo pongo en "1" el bit menos significaivo del CR0.
    
    jmp .flush_prefech_queue
    .flush_prefech_queue:        ;esto es para limpiar el pipeline porque cambié a modo protegido, lo que estaba en el pipeline ya no sirve.

    o32 jmp dword CODE_SEL16:kernel32_init

..@fault_end:
   hlt
   jmp ..@fault_end
   
gdt16:
dq	0
CODE_SEL16	equ	$-gdt16
dw	0xffff
dw	0x0000
db	0x00
db	10011011b
db	11001111b
db	0x00
DATA_SEL16	equ	$-gdt16
dw	0xffff
dw	0
db	0
db	10010011b
db	11001111b
db	0
GDT16_SIZE	equ	$-gdt16		;tamaño de la GDT.

GDTR16:

		dw	GDT16_SIZE-1
		dd	gdt16


SECTION  .init32 progbits
EXTERN __STACK_END_32
EXTERN __STACK_SIZE_32
EXTERN DS_SEL
EXTERN CS_SEL
EXTERN __PDPT
EXTERN kernel32_main
EXTERN __fast_memcpy
EXTERN __paginacion
EXTERN ___kernel_size
EXTERN ___kernel_vma_st
EXTERN ___kernel_lma_st
EXTERN ___tablas_size
EXTERN ___tablas_vma
EXTERN ___tablas_lma
EXTERN ___handlers_size
EXTERN ___handlers_vma
EXTERN ___handlers_lma
EXTERN ___tarea1_vma_st
EXTERN ___tarea1_lma_st
EXTERN ___tarea1_size

EXTERN __codigo_ini32
EXTERN __tabla_digitos
EXTERN ___bss_tarea1_vma
EXTERN ___batos_tarea1_vma
EXTERN __datos_no_iniciali_inicio
EXTERN __STACK_START_32
EXTERN __STACK_START_T1

EXTERN _cant_tablas_pag


USE32
kernel32_init:
   ;->Inicializar la pila   
   mov ax, DATA_SEL16
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

   ;Desempaquetar la ROM
   push ebp
   mov ebp, esp
   push ___kernel_size
   push ___kernel_vma_st
   push ___kernel_lma_st
   call __fast_memcpy
   leave
   cmp eax, 1           ;Analizo el valor de retorno (1 Exito -1 Fallo)
   jne .guard
 
   ;Desempaquetar Tablas del sistema
   push ebp
   mov ebp, esp
   push ___tablas_size
   push ___tablas_vma
   push ___tablas_lma
   call __fast_memcpy
   leave
   cmp eax, 1           ;Analizo el valor de retorno (1 Exito -1 Fallo)
   jne .guard

   ;Desempaquetar handlers
   push ebp
   mov ebp, esp
   push ___handlers_size
   push ___handlers_vma
   push ___handlers_lma
   call __fast_memcpy
   leave
   cmp eax, 1           ;Analizo el valor de retorno (1 Exito -1 Fallo)
   jne .guard
   
   ;Desempaquetar tarea1
   push ebp
   mov ebp, esp
   push ___tarea1_size
   push ___tarea1_vma_st
   push ___tarea1_lma_st
   call __fast_memcpy
   leave
   cmp eax, 1           ;Analizo el valor de retorno (1 Exito -1 Fallo)
   jne .guard
   

;-------------PAGINACION----------------

   ;->Inicializar la tabla de directorio de paginas 
   mov ecx, 0xfff       ;4k
   .PDPT_init:
      mov byte [__PDPT + ecx],0x00
      loop .PDPT_init
   
    mov eax, 0          ;push cantdad de entradas al directorio de paginas.
    push eax
    mov eax, __PDPT
    push eax
    mov eax,__codigo_ini32  ;pagina init
    push eax
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,__STACK_START_32  ;pagina pila
    push eax
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,___kernel_vma_st  ;pagina main
    push eax
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,___handlers_vma  ;ISR
    push eax
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,___tablas_vma  ;pagina tablas del sistema
    push eax
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,__tabla_digitos  ;pagina tablas de digitos
    push eax
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,___tarea1_vma_st  ;pagina tarea 1
    push eax
    mov eax, 0x00410000
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,___bss_tarea1_vma  ;pagina tarea 1 datos no inic
    push eax
    mov eax, 0x00411000
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,___batos_tarea1_vma  ;pagina tarea 1 datos inic
    push eax
    mov eax, 0x00412000
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,__datos_no_iniciali_inicio  ;pagina datos no inic
    push eax
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    push eax            ;push cantdad de entradas al directorio de paginas.
    mov eax, __PDPT
    push eax
    mov eax,__STACK_START_T1  ;pagina datos no inic
    push eax
    mov eax, 0x00413000
    push eax
    call __paginacion
    add esp,4*4         ;restablesco el puntero de pila porque el c no lo hace
    
    mov [_cant_tablas_pag], eax ; guardo la cantidad de entradas en el directorio de paginas.
    
    mov eax,__PDPT
    mov CR3,eax
    
    mov eax,CR0
    or eax,0x80000000
    xchg bx,bx
    mov CR0, eax

   jmp CODE_SEL16:kernel32_main

   .guard:
      hlt
      jmp .guard

