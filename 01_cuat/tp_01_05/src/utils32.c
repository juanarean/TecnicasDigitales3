
#include "../inc/sys_types.h"

__attribute__(( section(".init32"))) byte __fast_memcpy(const dword *src, dword *dst, dword length)
{

   byte status = ERROR_DEFECTO;

   if(length > 0)
   {
      
      while(length)
      {
         length--;
         *dst = *src;
         dst++;
         src++;
      }
      status = EXITO;   
   }

   return(status);
}
