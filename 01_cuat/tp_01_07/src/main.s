SECTION  .kernel32 progbits
GLOBAL kernel32_main
EXTERN __datos_no_iniciali_inicio
EXTERN __leer_teclado
EXTERN GDTR
EXTERN CODE_SEL
EXTERN DATA_SEL
EXTERN IDTR

USE32
kernel32_main:
xchg bx,bx  

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
sti

xor ecx,ecx
_leo_tecla:
call __leer_teclado
      cmp al,0x1F   ; código de la 'S'
      je _fin
      mov [__datos_no_iniciali_inicio + ecx],al
      inc ecx
      cmp al,0x15   ; código de la 'Y'
      je _DE
      cmp al,0x16   ; código de la 'U'
      je _UD
      
      jmp _leo_tecla
   
   _fin:
   xchg bx,bx
      hlt
      jmp _fin
      
  _DE:
  xchg bx,bx
  mov eax,0
  mov edx,0
  div eax
  jmp _leo_tecla
  
  _UD:
  xchg bx,bx
  db 0x0f
  db 0x27
  jmp _leo_tecla
