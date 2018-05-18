SECTION  .key progbits
GLOBAL __leer_teclado

USE32
__leer_teclado:
xor eax, eax
   _leer:
      in al, 0x64
      bt eax, 0x00
      jnc _leer

      in al, 0x60
      mov bl,al
_espero_suelte:

        in al, 0x60
        bt eax, 0x07
      jnc _espero_suelte
      
mov al,bl
ret

