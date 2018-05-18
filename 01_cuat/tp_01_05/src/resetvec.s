USE16
EXTERN start16
GLOBAL reset_vector

SECTION .resetvec
reset_vector:
	cli
	cld
	jmp start16
