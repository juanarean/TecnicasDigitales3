/**/
   __STACK_START_16 = 0x9000;                                     /*SS=0x9000*/
   __STACK_END_16 = 0xffff;         
   __STACK_START_32 = 0x1fffb000;
   __STACK_END_32 = 0x1fffbfff;
   __STACK_SIZE_32 = ((__STACK_END_32 - __STACK_START_32) / 4);   /*32b word*/
    __HANDLER_HIGH = 0X0000;

MEMORY
{
   ram (!x) : ORIGIN = 0x00000000, LENGTH = 4294901760 /*2^32(4G)-2^16(64k)*/
   rom32 (rx)  : ORIGIN = 0xffff0000, LENGTH = 0xffff
}
SECTIONS
{
  
   . = 0x00000000;
   ___handlers_vma = .;
   .handlers_irs ___handlers_vma :
      AT ( 0xffff0000 )   
      { *(.ISR_HANDLERS); } > ram
   ___handlers_lma =  LOADADDR(.handlers_irs);  
   ___handlers_size = SIZEOF(.handlers_irs); 
   
   . = 0x00100000;
   ___tablas_vma = .;
   .tablas ___tablas_vma : 
      AT ( ___handlers_lma + ___handlers_size )
      { *(.sys_tables); } > ram
   ___tablas_lma = LOADADDR(.tablas);
   ___tablas_size = SIZEOF(.tablas);
   
    . = 0x00300000;
   ___kernel_vma_st = .;
   .codigo_kernel32 ___kernel_vma_st :
      AT ( ___tablas_lma + ___tablas_size )   
      { *(.kernel32); } > ram
   ___kernel_lma_st =  LOADADDR(.codigo_kernel32);  
   ___kernel_size = SIZEOF(.codigo_kernel32);

   __tabla_digitos = 0x00310000;
   ___td_vma_st = __tabla_digitos;
   .td __tabla_digitos : { *(.tabla_digitos*); } > ram 
   __digitos_lma = LOADADDR(.td);
   __digitos_size = SIZEOF(.td);
   
   . = 0x00320000;
   ___tarea1_vma_st = .;
   .codigo_tarea1 ___tarea1_vma_st :
      AT ( ___kernel_lma_st + ___kernel_size )   
      { *(.tarea1); } > ram
   ___tarea1_lma_st =  LOADADDR(.codigo_tarea1);  
   ___tarea1_size = SIZEOF(.codigo_tarea1);
   
   __datos_no_iniciali_inicio = 0x003E0000;
   ___bss_vma_st = __datos_no_iniciali_inicio;
   .bss __datos_no_iniciali_inicio : { *(.dat_no_inic*); } > ram   
   
   __codigo_ini32 = 0xfffff000;
   .codigo_init32 __codigo_ini32 :
      AT ( 0xfffff000 )   
      { *(.init32); } > rom32
    ___codigo_ini32_size = SIZEOF(.codigo_init32);
      
   __codigo_init16 = __codigo_ini32 + ___codigo_ini32_size;
   .text __codigo_init16 :
      AT ( __codigo_ini32 + ___codigo_ini32_size )   
      { *(.kernel16); } > rom32
   
   . = 0xfffffff0;
   .codigo_reset 0xfffffff0 :
      AT ( 0xfffffff0 )
      { *(.resetvec); } > rom32

   .fill_rom32 :
      { FILL(0x90);
        . = ORIGIN(rom32) + LENGTH(rom32)-1;
        BYTE(0x90);
      } > rom32

   .end_rom32 0xffffffff:
      AT ( 0xffffffff )
      { 
        BYTE(0x90);
      }
}
