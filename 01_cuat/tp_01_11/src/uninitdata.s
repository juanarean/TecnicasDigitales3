SECTION	.dat_no_inic nobits alloc noexec write
GLOBAL tecla
GLOBAL digitos
GLOBAL _tiempo
GLOBAL _sumatoria
GLOBAL _cantidad
GLOBAL _cant_tablas_pag

tecla:
    resb 1

digitos:
    resb 4
    
_tiempo:
    resb 4
    
_cantidad:
    resb 4
    
_cant_tablas_pag:
    resb 4
