USE16

%define DESTINO_1       0x00000
%define DESTINO_2       0xf0000
%define ROM_SIZE		(64*1024)
%define ROM_START		0xf0000
%define RESET_VECTOR	0xffff0
ORG ROM_START
start16:
   xor eax, eax
   mov cr3, eax             ;Invalidar TLB
  
   mov ax, 0xffff           ;Genero una pila para poder llamar Funciones.
   mov sp, ax
   mov ax, 0x0000
   mov ss, ax
   
   mov eax, CODE_LENGTH
   push eax
   mov eax, 0x0000
   push eax
xchg bx,bx 
;Testeo si estoy copiando por primera vez o ya estoy en la posicion 0x00000000 
   mov edx, cs
   mov ebx, DESTINO_1>>4
   cmp edx,ebx
   jne copia_destino1
   
   mov eax, DESTINO_2>>4
   push eax
   mov eax, DESTINO_2
   push eax
   
   call td3_memcopy
xchg bx,bx    
   jmp 0xf000:0x0000

copia_destino1:
   mov eax, DESTINO_1>>4
   push eax
   mov eax, DESTINO_1
   push eax
   
   call td3_memcopy
xchg bx,bx    
    jmp 0x0000:DESTINO_1
   
    fin:
   hlt
   jmp fin

;///////////////////////////////////////////////////////////////////////////////
;                   Funcion para copiar
;///////////////////////////////////////////////////////////////////////////////
td3_memcopy:
pop bp
pop edi
pop edx
pop esi
pop ecx


copia:
        mov ax,0xf000
        mov ds,ax
        mov bl,[si]
        mov ds,dx
        mov [di],bl
        
        inc si
        inc di
        
        loop copia
push bp
ret
   
CODE_LENGTH equ ($-start16)

times (RESET_VECTOR - ROM_START - CODE_LENGTH) nop
reset_vector:
	cli
	cld
	jmp 0xf000:start16
align 16
