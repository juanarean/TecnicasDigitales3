SECTION  .kernel32 progbits
GLOBAL kernel32_main
EXTERN __tarea1
EXTERN tecla
EXTERN digitos
EXTERN vectores
EXTERN _tiempo
EXTERN _cantidad
EXTERN GDTR
EXTERN CODE_SEL
EXTERN DATA_SEL
EXTERN IDTR

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
mov [_cantidad],edx

sti
   xchg bx,bx
   _halt:
      hlt

      mov ebx,[_tiempo]
      cmp ebx,5
      jne _test_tecla
      xor eax,eax
      mov [_tiempo],eax
      call __tarea1
      jmp _halt
      
_test_tecla:      
      mov al, [tecla]
      mov ecx, 9
      mov ebx, 2
_comparaciones:      
      cmp al, bl           
      jne _sig_comp
      dec al
      jmp _grabar_tecla
_sig_comp:
        inc bl
        loop _comparaciones

_comp_A:
      cmp al, 0x1e          ; tecla A
      jne _comp_B
      mov al, 0xA
      je _grabar_tecla
_comp_B:      
      cmp al, 0x30          ; tecla B
      jne _comp_C
      mov al,0xB
      je _grabar_tecla
_comp_C:      
      cmp al, 0x2e          ; tecla C
      jne _comp_D
      mov al, 0xC
      je _grabar_tecla
_comp_D:      
      cmp al, 0x20          ; tecla D
      jne _comp_E
      mov al, 0xD
      je _grabar_tecla
_comp_E:      
      cmp al, 0x12          ; tecla E
      jne _comp_F
      mov al, 0xE
      je _grabar_tecla
_comp_F:      
      cmp al, 0x21          ; tecla F
      jne _comp_0
      mov al, 0xF
      je _grabar_tecla
_comp_0:      
      cmp al, 0x0b          ; tecla D
      jne _comp_Enter
      mov al, 0x00
      je _grabar_tecla
_comp_Enter:
      cmp al, 0x1c          ; tecla ENTER
      je _grabar_vector
      xor eax,eax
      mov [tecla], al
      jmp _halt
      
   
_grabar_tecla:
    mov ebx,[digitos]
    and ebx,0x0fffffff
    shl ebx,4
    or bl,al
    mov [digitos],ebx
    xor eax,eax
    mov [tecla], al
    jmp _halt
    
_grabar_vector:
    mov eax,[digitos]
    mov [vectores + edx],eax
    add edx,4
    mov [_cantidad],edx
    xor eax,eax
    mov [tecla], al
    mov [digitos],eax
    jmp _halt
      
