/** 
	\file  sys_types.h	
	\version 01.00
   \brief Biblioteca de declaraciones y definiciones relacionadas con el SO.

   \author Christian Nigri <cnigri@frba.utn.edu.ar>
   \date    01/02/2012
*/
#ifndef _SYS_TYPES_H_
   #define _SYS_TYPES_H_

#define SISTEMA IA32
/** \def ON */
#define ON		1				   ///<Encendido
/** \def OFF */
#define OFF		0				   ///<Apagado
/** \def EXITO */
#define EXITO	1				   ///<Valor retornado en caso de una ejecucion exitosa de lo solicitado
/** \def ERROR_DEFECTO */
#define ERROR_DEFECTO      -1 ///<Error debido a que no se puede resolver/ejecutar lo solicitado 
/** \def ERROR_DESCONOCIDO */
#define ERROR_DESCONOCIDO  -2 ///<Error del cual no se conoce su origen

/** \def BYTE */
typedef unsigned char byte;   ///<Tipo byte
/** \def WORD */
typedef unsigned short word;  ///<Tipo word
/** \def DWORD */
typedef unsigned long dword;  ///<Tipo dword
/** \def QWORD */
typedef unsigned long long qword;   ///<Tipo qword
/** \def TICKS_T */
typedef unsigned long long int ticks_t;   ///<Tipo para timer tick

#endif  /*_SYS_TYPES_H_*/
