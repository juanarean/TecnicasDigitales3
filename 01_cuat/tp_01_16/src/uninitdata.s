SECTION	.dat_no_inic nobits alloc noexec write
GLOBAL tecla
GLOBAL digitos
GLOBAL _tiempo
GLOBAL _sumatoria
GLOBAL _cantidad
GLOBAL _cant_tablas_pag
GLOBAL _pag_nuevas
GLOBAL __PDPT0
GLOBAL __PDPT1
GLOBAL __PDPT2
GLOBAL __PDPT3
GLOBAL __PDPT4
GLOBAL _tiempo_t1
GLOBAL _tiempo_t2
GLOBAL _tiempo_t3
GLOBAL _tiempo_t4

digitos:
    resb 8
    
tecla:
    resb 1
    
_tiempo:
    resb 4
    
_cantidad:
    resb 4
    
_cant_tablas_pag:
    resb 4
    
_pag_nuevas:
    resb 4
    
__PDPT0:
    resb 4
    
__PDPT1:
    resb 4
    
__PDPT2:
    resb 4
    
__PDPT3:
    resb 4
    
__PDPT4:
    resb 4
    
_tiempo_t1:
    resb 4
    
_tiempo_t2:
    resb 4
    
_tiempo_t3:
    resb 4
    
_tiempo_t4:
    resb 4