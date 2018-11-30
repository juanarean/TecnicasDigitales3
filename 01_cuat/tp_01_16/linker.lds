/* DEFINICION DE PILAS Y MAS*/
   __STACK_START_16 = 0x9000;                                     /*SS=0x9000*/
   __STACK_END_16 = 0xffff;         
   __STACK_START_32 = 0x1fffb000;
   __STACK_END_32 = 0x1fffbfff;
   __STACK_SIZE_32 = ((__STACK_END_32 - __STACK_START_32) / 4);   /*32b word*/
    __HANDLER_HIGH = 0X0000;    /*BASE HANDLERS*/
    __PDPT = 0x00110000;    /* BASE TABLAS DE PAGINACION */
    __STACK_START_T_PL3 = 0x00613000;
    __STACK_END_T_PL3 = 0x00613fff;
    __STACK_START_T_PL0 = 0x00614000;
    __STACK_END_T_PL0 = 0x00614fff;

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
   
    . = 0x00500000;
   ___kernel_vma_st = .;
   .codigo_kernel32 ___kernel_vma_st :
      AT ( ___tablas_lma + ___tablas_size )   
      { *(.kernel32); } > ram
   ___kernel_lma_st =  LOADADDR(.codigo_kernel32);  
   ___kernel_size = SIZEOF(.codigo_kernel32);
 
   __tabla_digitos = 0x00511000;
   ___td_vma_st = __tabla_digitos;
   .td __tabla_digitos : { *(.tabla_digitos*); } > ram 
   __digitos_lma = LOADADDR(.td);
   __digitos_size = SIZEOF(.td);
 
   __datos_no_iniciali_inicio = 0x005E0000;
   ___bss_vma_st = __datos_no_iniciali_inicio;
   .bss __datos_no_iniciali_inicio : { *(.dat_no_inic*); } > ram   
     
    . = 0x00610000;
   ___tarea0_vma_st = .;
   .codigo_tarea0 ___tarea0_vma_st :
      AT ( ___kernel_lma_st + ___kernel_size )   
      { *(.tarea0); } > ram
   ___tarea0_lma_st =  LOADADDR(.codigo_tarea0);  
   ___tarea0_size = SIZEOF(.codigo_tarea0);
   
   __datos_no_iniciali_tarea0 = 0x00611000;
   ___bss_tarea0_vma = __datos_no_iniciali_tarea0;
   .bss_t0 __datos_no_iniciali_tarea0 : { *(.tarea0_bss*); } > ram

   __datos_tarea0 = 0x00612000;
   ___datos_tarea0_vma = __datos_tarea0;
   .bata_t0 __datos_tarea0 : { *(.tarea0_datos*); } > ram
  
   . = 0x00610000;
   ___tarea1_vma_st = .;
   .codigo_tarea1 ___tarea1_vma_st :
      AT ( ___tarea0_lma_st + ___tarea0_size )   
      { *(.tarea1); } > ram
   ___tarea1_lma_st =  LOADADDR(.codigo_tarea1);  
   ___tarea1_size = SIZEOF(.codigo_tarea1);
   
   __datos_no_iniciali_tarea1 = 0x00611000;
   ___bss_tarea1_vma = __datos_no_iniciali_tarea1;
   .bss_t1 __datos_no_iniciali_tarea1 : { *(.tarea1_bss*); } > ram
   
   __datos_tarea1 = 0x00612000;
   ___datos_tarea1_vma = __datos_tarea1;
   .bata_t1 __datos_tarea1 : { *(.tarea1_datos*); } > ram
   
   . = 0x00610000;
   ___tarea2_vma_st = .;
   .codigo_tarea2 ___tarea2_vma_st :
      AT ( ___tarea1_lma_st + ___tarea1_size )   
      { *(.tarea2); } > ram
   ___tarea2_lma_st =  LOADADDR(.codigo_tarea2);  
   ___tarea2_size = SIZEOF(.codigo_tarea2);
   
   __datos_no_iniciali_tarea2 = 0x00611000;
   ___bss_tarea2_vma = __datos_no_iniciali_tarea2;
   .bss_t2 __datos_no_iniciali_tarea2 : { *(.tarea2_bss*); } > ram
   
   __datos_tarea2 = 0x00612000;
   ___datos_tarea2_vma = __datos_tarea2;
   .bata_t2 __datos_tarea2 : { *(.tarea2_datos*); } > ram
   
   . = 0x00610000;
   ___tarea3_vma_st = .;
   .codigo_tarea3 ___tarea3_vma_st :
      AT ( ___tarea2_lma_st + ___tarea2_size )   
      { *(.tarea3); } > ram
   ___tarea3_lma_st =  LOADADDR(.codigo_tarea3);  
   ___tarea3_size = SIZEOF(.codigo_tarea3);
   
   __datos_no_iniciali_tarea3 = 0x00611000;
   ___bss_tarea3_vma = __datos_no_iniciali_tarea3;
   .bss_t3 __datos_no_iniciali_tarea3 : { *(.tarea3_bss*); } > ram
   
   __datos_tarea3 = 0x00612000;
   ___datos_tarea3_vma = __datos_tarea3;
   .bata_t3 __datos_tarea3 : { *(.tarea3_datos*); } > ram
   
   . = 0x00610000;
   ___tarea4_vma_st = .;
   .codigo_tarea4 ___tarea4_vma_st :
      AT ( ___tarea3_lma_st + ___tarea3_size )   
      { *(.tarea4); } > ram
   ___tarea4_lma_st =  LOADADDR(.codigo_tarea4);  
   ___tarea4_size = SIZEOF(.codigo_tarea4);
   
   __datos_no_iniciali_tarea4 = 0x00611000;
   ___bss_tarea4_vma = __datos_no_iniciali_tarea4;
   .bss_t4 __datos_no_iniciali_tarea4 : { *(.tarea4_bss*); } > ram
   
   __datos_tarea4 = 0x00612000;
   ___datos_tarea4_vma = __datos_tarea4;
   .bata_t4 __datos_tarea4 : { *(.tarea4_datos*); } > ram
 
   __codigo_ini32 = 0xffffd100;
   .codigo_init32 __codigo_ini32 :
      AT ( 0xffffd100 )   
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
