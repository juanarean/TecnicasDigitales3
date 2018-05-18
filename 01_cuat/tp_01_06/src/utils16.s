SECTION .kernel16
USE16
;///////////////////////////////////////////////////////////////////////////////
;                   Funciones para habilitar el A20 Gate
;///////////////////////////////////////////////////////////////////////////////
%include "./inc/init_pci.inc"

%define     PORT_A_8042    0x60        ;Puerto A de E/S del 8042
%define     CTRL_PORT_8042 0x64        ;Puerto de Estado del 8042
%define     KEYB_DIS       0xAD        ;Deshabilita teclado con Command Byte
%define     KEYB_EN        0xAE        ;Habilita teclado con Command Byte
%define     READ_OUT_8042  0xD0        ;Copia en 0x60 el estado de OUT
%define     WRITE_OUT_8042 0xD1        ;Escribe en OUT lo almacenado en 0x60

GLOBAL A20_Enable_No_Stack
GLOBAL bios_init
EXTERN A20_Enable_No_Stack_return
EXTERN bios_init_return

;------------------------------------------------------------------------------
;| Título: A20_Enable_No_Stack                                                |
;| Versión:       1.0                     Fecha:   26/02/2018                 |
;| Autor:         ChristiaN               Modelo:  IA-32 (16bits)             |
;| ------------------------------------------------------------------------   |
;| Descripción:                                                               |
;|    Habilita la puerta A20 sin utilizacion de la pila.                      |
;|    Referencia https://wiki.osdev.org/A20_Line                              |
;| ------------------------------------------------------------------------   |
;| Recibe:                                                                    |
;|    Nada                                                                    |
;|                                                                            |
;| Retorna:                                                                   |
;|    Nada                                                                    |
;| ------------------------------------------------------------------------   |
;| Revisiones:                                                                |
;|    1.0 | 26/02/2018 | ChristiaN | Original                                 |
;------------------------------------------------------------------------------
A20_Enable_No_Stack:

   xor ax, ax
   ;Deshabilita el teclado
   mov di, .8042_kbrd_dis
   jmp .empty_8042_in
   .8042_kbrd_dis:
   mov al, KEYB_DIS
   out CTRL_PORT_8042, al
 
   ;Lee la salida
   mov di, .8042_read_out
   jmp .empty_8042_in
   .8042_read_out:
   mov al, READ_OUT_8042
   out CTRL_PORT_8042, al
   
   .empty_8042_out:  
;      in al, CTRL_PORT_8042      ; Lee port de estado del 8042 hasta que el
;      test al, 00000001b         ; buffer de salida este vacio
;      jne .empty_8042_out

   xor bx, bx   
   in al, PORT_A_8042
   mov bx, ax

   ;Modifica el valor del A20
   mov di, .8042_write_out
   jmp .empty_8042_in
   .8042_write_out:
   mov al, WRITE_OUT_8042
   out CTRL_PORT_8042, al

   mov di, .8042_set_a20
   jmp .empty_8042_in
   .8042_set_a20:
   mov ax, bx
   or ax, 00000010b              ; Habilita el bit A20
   out PORT_A_8042, al

   ;Habilita el teclado
   mov di, .8042_kbrd_en
   jmp .empty_8042_in
   .8042_kbrd_en:
   mov al, KEYB_EN
   out CTRL_PORT_8042, al

   mov di, .a20_enable_no_stack_exit
   .empty_8042_in:  
;      in al, CTRL_PORT_8042      ; Lee port de estado del 8042 hasta que el
;      test al, 00000010b         ; buffer de entrada este vacio
;      jne .empty_8042_in
      jmp di

   .a20_enable_no_stack_exit:

jmp A20_Enable_No_Stack_return

