SECTION  .kernel32 progbits
GLOBAL kernel32_main
EXTERN __datos_no_iniciali_inicio
EXTERN __leer_teclado

USE32
kernel32_main:
xchg bx,bx  
xor ecx,ecx
_leo_tecla:
call __leer_teclado
      cmp al,0x1F   ; código de la 'S'
      je _fin
      mov [__datos_no_iniciali_inicio + ecx],al
      inc ecx
      
      jmp _leo_tecla
   
   _fin:
   xchg bx,bx
      hlt
      jmp _fin
