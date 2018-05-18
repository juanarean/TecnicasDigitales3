/**/
   __STACK_START_16 = 0x9000;                                     /*SS=0x9000*/
   __STACK_END_16 = 0xffff;         
   __STACK_START_32 = 0x1fffb000;
   __STACK_END_32 = 0x1fffbfff;
   __STACK_SIZE_32 = ((__STACK_END_32 - __STACK_START_32) / 4);   /*32b word*/
   
   DESTINO_1 = 0x00000000;
   DESTINO_2 = 0x00300000;
   DESTINO_3 = 0x00500000;
   

MEMORY
{
   ram (!x) : ORIGIN = 0x00000000, LENGTH = 4294901760 /*2^32(4G)-2^16(64k)*/
   rom16 (rx)  : ORIGIN = 0xffff0000, LENGTH = 0xffff
}
SECTIONS
{
    . = 0xffff0000;
   __codigo_ini16 = 0xffff0000;
   .codigo_init16 __codigo_ini16 :
      AT ( 0xffff0000 )   
      { *(.init16); } > rom16


   . = 0xfffffff0;
   .codigo_reset 0xfffffff0 :
      AT ( 0xfffffff0 )
      { *(.resetvec); } > rom16

   .fill_rom16 :
      { FILL(0x90);
        . = ORIGIN(rom16) + LENGTH(rom16)-1;
        BYTE(0x90);
      } > rom16

   .end_rom16 0xffffffff:
      AT ( 0xffffffff )
      { 
        BYTE(0x90);
      }
}
