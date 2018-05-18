/**/
   __STACK_START_16 = 0x9000;                                     /*SS=0x9000*/
   __STACK_END_16 = 0xffff;         
   __STACK_START_32 = 0x1fffb000;
   __STACK_END_32 = 0x1fffbfff;
   __STACK_SIZE_32 = ((__STACK_END_32 - __STACK_START_32) / 4);   /*32b word*/

MEMORY
{
   ram (!x) : ORIGIN = 0x00000000, LENGTH = 4294901760 /*2^32(4G)-2^16(64k)*/
   rom32 (rx)  : ORIGIN = 0xffff0000, LENGTH = 0xffff
}
SECTIONS
{
    . = 0x00000000;
   ___rutinas_vma_st = .;
   .rutinas ___rutinas_vma_st :
      AT ( 0xffff0000 )   
      { *(.key); } > ram
   ___rutinas_lma_st =  LOADADDR(.rutinas);  
   ___rutinas_size = SIZEOF(.rutinas);  
    
    . = 0x00300000;
   ___kernel_vma_st = .;
   .codigo_kernel32 ___kernel_vma_st :
      AT ( 0xffff0100 )   
      { *(.kernel32); } > ram
   ___kernel_lma_st =  LOADADDR(.codigo_kernel32);  
   ___kernel_size = SIZEOF(.codigo_kernel32);

   __datos_no_iniciali_inicio = 0x003E1000;
   ___bss_vma_st = __datos_no_iniciali_inicio;
   .bss  : { *(.dat_no_inic*); } > ram

    __datos_iniciali_inicio = 0xffff1000;
   .data __datos_iniciali_inicio : 
      AT ( 0xffff1000 )
      { *(.sys_tables); } > rom32
   ___gdt_lma_st = LOADADDR(.data);
   
   __codigo_ini32 = 0xffff1500;
   .codigo_init32 __codigo_ini32 :
      AT ( 0xffff1500 )   
      { *(.init32); } > rom32
      
   __codigo_init16 = 0xffff2000;
   .text __codigo_init16 :
      AT ( 0xffff2000 )   
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
