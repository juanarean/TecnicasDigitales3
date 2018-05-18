SECTION  .kernel32 progbits
GLOBAL kernel32_main
EXTERN __fast_memcpy
EXTERN ___kernel_lma_st
EXTERN ___kernel_size
EXTERN CODE_SEL
EXTERN DESTINO2

USE32
kernel32_main:
   
   mov ebp, esp
   push ___kernel_size
   push DESTINO2
   push ___kernel_lma_st
   call __fast_memcpy
   leave
   cmp eax, 1           ;Analizo el valor de retorno (1 Exito -1 Fallo)
   jne .guard
xchg bx,bx
   jmp CODE_SEL:DESTINO2
   
   .guard:
        hlt
        jmp .guard
