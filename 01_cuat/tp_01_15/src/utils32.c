
#include "../inc/sys_types.h"
extern word _cantidad;
extern byte * vectores;

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

__attribute__(( section("init32"))) byte __paginacion(dword lineal, dword fisica, dword base, dword atributos, dword cant)
{
    byte status = ERROR_DEFECTO;
  
    dword indice_td = (lineal & 0xffc00000) >> 20;
    dword indice_tp = (lineal & 0x003ff000) >> 10;
    
    dword *punt_td = 0;

    punt_td = (dword *) (base + indice_td);
    if((*punt_td) == 0)
    {
        cant ++;
        *punt_td = base + (cant*0x1000) + 7;
        cant = __paginacion((dword)(base + (cant*0x1000)), (dword)(base + (cant*0x1000)), base, 7, cant);
    }
    
    dword *punt_tp = 0;
    punt_tp = (dword *) (((*punt_td) & 0xfffff000) + indice_tp);
    *punt_tp = (fisica & 0xfffff000) + atributos;
    
    status = cant;
    return(status);
}

__attribute__(( section(".ISR_HANDLERS"))) dword td3_read(void * buffer, dword num_bytes)
{
    dword i;
    dword j;
    dword k;
    k = 0;
    byte * dst;
    dst = buffer;
    
    if(num_bytes>0)
    {
        for(i=0;i<_cantidad;i++)
        {
                for(j=0;j<8;j++)
                {
                    *dst++ = *vectores++;

                    k++;
                }
                if(k>=num_bytes)    break;
        }
    }

    return(k);
}
