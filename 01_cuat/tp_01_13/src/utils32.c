
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

__attribute__(( section("init32"))) byte __paginacion(dword lineal, dword fisica, dword base, dword cant)
{
    byte status = ERROR_DEFECTO;
  
    dword indice_td = (lineal & 0xffc00000) >> 20;
    dword indice_tp = (lineal & 0x003ff000) >> 10;
    
    dword *punt_td = 0;

    punt_td = (dword *) (base + indice_td);
    if((*punt_td) == 0)
    {
        cant ++;
        *punt_td = base + (cant*0x1000) + 3;
        cant = __paginacion((dword)(*punt_td)-3, (dword)(*punt_td)-3, base, cant);
    }
    
    dword *punt_tp = 0;
    punt_tp = (dword *) (((*punt_td) & 0xfffff000) + indice_tp);
    *punt_tp = (fisica & 0xfffff000) + 3;
    
    status = cant;
    return(status);
}

