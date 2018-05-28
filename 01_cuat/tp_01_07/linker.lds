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
   ___rutinas_vma = .;
   .rut ___rutinas_vma :
      AT ( 0xffff0000 )   
      { *(.rutinas); } > ram
   ___rutinas_lma =  LOADADDR(.rut);  
   ___rutinas_size = SIZEOF(.rut);  
   
   . = ___rutinas_vma + ___rutinas_size;
   ___handlers_vma = .;
   .handlers_irs ___handlers_vma :
      AT ( ___rutinas_lma + ___rutinas_size )   
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

   __datos_no_iniciali_inicio = 0x003E0000;
   ___bss_vma_st = __datos_no_iniciali_inicio;
   .bss  : { *(.dat_no_inic*); } > ram   
   
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
