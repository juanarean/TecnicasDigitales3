SECTION	.dat_no_inic nobits alloc noexec write
GLOBAL tecla
GLOBAL digitos
GLOBAL _tiempo
GLOBAL _sumatoria
GLOBAL _cantidad
GLOBAL _cant_tablas_pag
GLOBAL _pag_nuevas

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
    
_pag_nuevas:
    resb 4
