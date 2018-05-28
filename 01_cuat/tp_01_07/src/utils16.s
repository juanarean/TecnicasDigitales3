GLOBAL PIC_Config
GLOBAL PIT_Set_1mseg
GLOBAL RTC_Service
GLOBAL A20_Enable

SECTION .kernel16
;-------------------------------------------------------------------------------
;|  Título:         Reprogramar PICS                                           |
;|  Versión:        1.0                     Fecha:  15/02/2010                 |
;|  Autor:          D.GARCIA                Modelo: IA-32 (16/32bits)          |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Desplaza la base de los tipos de interrupcion de los PICs 8259A        |
;|      Retorna con las interrupciones deshabilitadas                          |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      bl:     Base del primer PIC                                            |
;|      bh:     Base del segundo PIC                                           |
;|                                                                             |
;|  Retorna:                                                                   |
;|      Nada                                                                   |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------
USE16
PIC_Config:                     ; Inicializo PIC 1
    mov     al, 11h             ; ICW1: IRQs activas x flanco, cascada, e ICW4
    out     20h, al  
    mov     al, bl              ; ICW2: El PIC 1 arranca en INT tipo "bl"
    out     21h, al
    mov     al, 04h             ; ICW3: PIC 1 Master, Slave, Ingresa Int x IRQ2
    out     21h,al
    mov     al, 01h             ; ICW4: Modo 8086
    out     21h, al
    mov     al, 0FFh            ; Deshabilito las interrupciones del PIC 1 
    out     21h, al
    mov     al, 11h             ; ICW1: IRQs activas x flanco, cascada, e ICW4
    out     0A0h, al  
    mov     al, bh              ; ICW 2: El PIC 2 arranca en INT tipo "bh"
    out     0A1h, al
    mov     al, 02h             ; ICW 3: PIC 2 Slave, Ingresa Int x IRQ2
    out     0A1h, al
    mov     al, 01h             ; ICW 4: Modo 8086
    out     0A1h, al
    mov     al, 0FFh            ; Deshabilito las interrupciones del PIC 2
    out     0A1h, al

    ret

;-------------------------------------------------------------------------------
;|  Título:         Reprogram_PIT                                              |
;|  Versión:        1.0                     Fecha:  24/08/2014                 |
;|  Autor:          Andrea Pirlo            Modelo: IA-32 (16/32bits)          |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Reprograma el Temporizador 0 del PIT (Programmable Internal Timer)     |
;|      Ticks cada 1 ms                                                        |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      Nada                                                                   |
;|  Retorna:                                                                   |
;|      Nada                                                                   |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
;7 6 5 4 3 2 1 0   <-- Número de bit de la palabra de control
;| | | | | | | |
;| | | | | | | +-- Modo BCD:
;| | | | | | |     0 - El contador trabajará en formato binario de 16 bits
;| | | | | | |     1 - El contador trabajará en formato BCD con cuatro dígitos 
;| | | | | | |          decimales
;| | | | +-+-+---- Modo de operación para el contador:
;| | | |           000 - Modo 0. Interrupt on Terminal Count (Interrumpe al terminar el conteo)
;| | | |           001 - Modo 1. Hardware Retriggerable One-Shot (Disparo programable)
;| | | |           X10 - Modo 2. Rate Generator (Generador de impulsos). El valor del bit más significativo no importa
;| | | |           X11 - Modo 3. Square Wave(Generador de onda cuadrada). El valor del bit más significativo no importa
;| | | |           100 - Modo 4. Software Triggered Strobe (Strobe disparado por software)
;| | | |           101 - Modo 5. Hardware Triggered Strobe (Retriggerable) (Strobe disparado por hardware)
;| | | |
;| | +-+---------- Modo de acceso (lectura/escritura) para el valor del contador:
;| |               00 - Counter Latch. El valor puede ser leído de la manera en que fue ajustado previamente.
;| |                                   El valor es mantenido hasta que es leído o sobreescrito.
;| |               01 - Lee (o escribe) solo el byte menos significativo del contador (bits 0-7)
;| |               10 - Lee (o escribe) solo el byte más significativo del contador (bits 8-15)
;| |               11 - Primero se lee (o escribe) el byte menos significativo del contador, y luego el byte más significativo
;| |
;+-+-------------- Selección del contador:
;                  00 - Se selecciona el contador 0
;                  01 - Se selecciona el contador 1
;                  10 - Se selecciona el contador 2
;                  11 - No usado. (solo hay 3 contadores)
;                  (Los demás bits de la palabra de control indican cómo será programado el contador seleccionado)

USE16
PIT_Set_1mseg:              ; Programacion del Timer Tick.
    mov al, 00110100b       
    out 43h, al             ; En 43h está el registro de control.

    mov ax, 1193            ; Los 3 contadores del PIT reciben una señal de clock de 1.19318 MHz 
                            ; 1193 * (1/1.19318 MHz) = 1000 interrupciones por segundo
                            ; El intervalo entre interrupciones es de 1 ms.
    out 40h, al             ; En 40h está el Counter 0.
    mov al, ah
    out 40h, al

    ret


;///////////////////////////////////////////////////////////////////////////////
;                   Funciones para controlar el RTC
;///////////////////////////////////////////////////////////////////////////////
USE16

;--------------------------------------------------------------------------------
;|  Título:         Control RTC                                                |
;|  Versión:        1.0                     Fecha:  16/07/2009                 |
;|  Autor:          D.GARCIA                Modelo: IA-32 (32 bits)            |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Rutina para manejo de servicios del Reloj de Tiempo Real               |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      AL = 0 Subfuncion fecha                                                |
;|      AL = 1 Subfuncion hora                                                 |
;|                                                                             |
;|  Retorna:                                                                   |
;|      Fecha:                                                                 |
;|          DH = Año                                                           |
;|          DL = Mes                                                           |
;|          AH = Dia                                                           |
;|          AL = Dia de la semana                                              |
;|      Hora:                                                                  |
;|          DL = Hora                                                          |
;|          AH = Minutos                                                       |
;|          AL = Segundos                                                      |
;|          CL = 0:OK  N:Codigo de error                                       |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------
RTC_Service:
    cmp     al, 0
    je      Fecha               ; Servicio de Fecha
    cmp     al, 1
    je      Hora                ; Servicio de Hora
    jmp     RTC_Err_Exit        ; Funcion no valida, salida con error
    
RTC_Err_Exit:
    mov     cl, 1               ; Codigo de error. Subfuncion invalida
    ret
RTC_Exit:
    mov     cl, 0               ; Codigo de error. OK
    ret

;-------------------------------------------------------------------------------
;|  Título:         Auxiliar RTC                                               |
;|  Versión:        1.0                     Fecha:  16/07/2009                 |
;|  Autor:          D.GARCIA                Modelo: IA-32 (32 bits)            |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Subfuncion para obtener la hora del sistema desde el RTC               |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      Nada                                                                   |
;|  Retorna:                                                                   |
;|      Nada                                                                   |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------
Hora:
    call    RTC_disponible      ; asegura que no está actualizándose el RTC
    mov     al, 4
    out     70h, al             ; Selecciona Registro de Hora
    in      al, 71h             ; lee hora
    mov     dl, al

    mov     al, 2
    out     70h, al             ; Selecciona Registro de Minutos
    in      al, 71h             ; lee minutos
    mov     ah, al

    xor     al, al
    out     70h, al             ; Selecciona Registro de Segundos
    in      al, 71h             ; lee minutos

    jmp     RTC_Exit


;-------------------------------------------------------------------------------
;|  Título:         Auxiliar RTC                                               |
;|  Versión:        1.0                     Fecha:  16/07/2009                 |
;|  Autor:          D.GARCIA                Modelo: IA-32 (32 bits)            |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Subfuncion para obtener la fecha del sistema desde el RTC              |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      Nada                                                                   |
;|  Retorna:                                                                   |
;|      Nada                                                                   |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------
Fecha:
    call    RTC_disponible      ; asegura que no esté 
                                ; actualizandose el RTC
    mov     al, 9
    out     70h, al             ; Selecciona Registro de Año
    in      al, 71h             ; lee año 
    mov     dh, al

    mov     al, 8
    out     70h, al             ; Selecciona Registro de Mes
    in      al, 71h             ; lee mes
    mov     dl, al

    mov     al, 7
    out     70h, al             ; Selecciona Registro de Fecha
    in      al, 71h             ; lee Fecha del mes
    mov     ah, al

    mov     al, 6
    out     70h, al             ; Selecciona Registro de Día 
    in      al, 71h             ; lee día de la semana

    jmp     RTC_Exit

    
;-------------------------------------------------------------------------------
;|  Título:         Auxiliar RTC                                               |
;|  Versión:        1.0                     Fecha:  16/07/2009                 |
;|  Autor:          D.GARCIA                Modelo: IA-32e (64 bits)           |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Verifica en el Status Register A que el RTC no esta actualizando       |
;|      fecha y hora.                                                          |
;|      Retorna cuando el RTC esta disponible                                  |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      Nada                                                                   |
;|  Retorna:                                                                   |
;|      Nada                                                                   |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------
RTC_disponible:
    mov     al, 0Ah
    out     70h, al             ; Selecciona registro de status A
wait_for_free:
    in      al, 71h             ; lee Status
    test    al, 80h
    jnz     wait_for_free
    
    ret


;///////////////////////////////////////////////////////////////////////////////
;                   Funciones para habilitar el A20 Gate
;///////////////////////////////////////////////////////////////////////////////
%define     PORT_A_8042     0x60        ; Puerto A de E/S del 8042
%define     CTRL_PORT_8042  0x64        ; Puerto de Estado del 8042
USE16
;-------------------------------------------------------------------------------
;|  Título: Habilito Gate A20                                                  |
;|  Versión:        1.0                     Fecha:  15/02/2010                 |
;|  Autor:          D.GARCIA                Modelo: IA-32 (16/32bits)          |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Chequea y llama a la funcion de habilitacion de la puerta A20 si no    |
;|      esta habilitada                                                        |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      Nada                                                                   |
;|                                                                             |
;|  Retorna:                                                                   |
;|      Nada                                                                   |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------

A20_Enable:
    mov     ax, 0FFFFh      
    mov     es, ax
    cmp     word [es:7E0Eh], 0AA55h ; Chequeo si 107E0Eh coincide con 7E0Eh
    je      GateA20_Disabled        ; A20 esta deshabilitada si coincide
    rol     word [7DFEh], 1h        ; Modifico word en 7E0Eh
    cmp     word [es:7E0Eh], 55AAh  ; Cambio tambien 107E0Eh?
    jne     GateA20_Enabled         ; Si no cambio entonces A20 esta habilitada
GateA20_Disabled:
    mov     al, 0DFh                ; Comando de habilitacion de A20
    call    _Gate_A20               ; Habilitar Gate A20
    cmp     al, 0                   ; OK?
    je      GateA20_Enabled         ; Si es OK continuo
Fail:
    hlt                             ; De lo contrario detengo el procesador
    jmp     Fail
GateA20_Enabled:
    mov     word [7DFEh], 0AA55h    ; Restituyo la firma del bootloader

    ret

;-------------------------------------------------------------------------------
;|  Título: Auxiliar para habilitar Gate A20                                   |
;|  Versión:        1.0                     Fecha:  15/02/2010                 |
;|  Autor:          D.GARCIA                Modelo: IA-32 (16/32bits)          |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Controla la señal que maneja la compuerta del bit de direcciones A20.  |
;|      La señal de compuerta del bit A20 toma una salida del procesador de    |
;|      teclado 8042.                                                          |
;|      Se debe utilizar cuando se planea acceder en Modo Protegido a          |
;|      direcciones de memoria mas alla del 1er Mbyte                          |
;|      El port 60h como entrada lee el scan code de la última tecla presionada|
;|      o liberada por el operador de la PC. Como salida tiene funciones muy   |
;|      específicas bit a bit: En particular el Bit 1 se utiliza para activar  |
;|      el Gate de A20 si se pone en 1 y desactivarlo si está en 0.            |
;|      Por otra parte el port 64h es el registro de comandos/estados según se |
;|      escriba o lea respectivamente.                                         |
;|      En BIOS nuevos aparece la INT 15h con ax 2400 disable, o 2401 enable   |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      AH = 0DDh, si se desea apagar esta senal                               |
;|      AL = 0DFh, si se desea disparar esta senal (x86 controla A20)          |
;|                                                                             |
;|  Retorna:                                                                   |
;|      AL = 00, si hubo exito. El 8042 acepto el comando                      |
;|      AL = 02, si fallo. El 8042 no acepto el comando                        |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------

_Gate_A20:
    cli                         ; Deshabilito interrupciones en el uso del 8042

    call    _8042_empty?        ; Ve si el buffer del 8042 está vacío
    jnz     gate_a20_exit       ; No lo está => retorna con AL=2

    mov     al, 0D1h            ; Comando Write port del 8042
    out     CTRL_PORT_8042, al  ; ...se envia al port 64h

    call    _8042_empty?        ; Espera se acepte el comando
    jnz     gate_a20_exit       ; Si no se acepta, retorna con AL=2

    mov     al, ah              ; Pone en AL el dato a escribir
    out     PORT_A_8042, al     ; Lo envia al 8042
    call    _8042_empty?        ; Espera se acepte el comando

gate_a20_exit:
    ret


;-------------------------------------------------------------------------------
;|  Título: Auxiliar para habilitar Gate A20                                   |
;|  Versión:        1.0                     Fecha:  15/02/2010                 |
;|  Autor:          D.GARCIA                Modelo: IA-32 (16/32bits)          |
;|  ------------------------------------------------------------------------   |
;|  Descripción:                                                               |
;|      Espera que se vacie el buffer del 8042                                 |
;|  ------------------------------------------------------------------------   |
;|  Recibe:                                                                    |
;|      Nada                                                                   |
;|                                                                             |
;|  Retorna:                                                                   |
;|      AL = 00, el buffer del 8042 est  vacio.(ZF = 1)                        |
;|      AL = 02, time out. El buffer del 8042 sigue lleno. (ZF = 0)            |
;|  ------------------------------------------------------------------------   |
;|  Revisiones:                                                                |
;|      1.0 | 15/02/2010 | D.GARCIA | Original                                 |
;-------------------------------------------------------------------------------

_8042_empty?:
    push    cx                  ; Salva CX
    sub     cx, cx              ; CX = 0 : valor de time out
empty_8042_01:  
    in      al, CTRL_PORT_8042  ; Lee port de estado del 8042
    and     al, 00000010b       ; si el bit 1 esta seteado o...
    loopnz  empty_8042_01       ; no alcanzó time out, espera.
    pop     cx                  ; recupera cx
    ret                         ; retorna con AL=0, si se limpió bit 1, 
                                ; o AL=2 si no. 

