; usage: %include "fileName.macro"

%macro endProg 0
    mov rax,60
    mov rdi,1
    syscall
%endmacro

;*********************************************************************
; Macro printM
; 
; Description:
;   Imprime un string
;
; Parametros:
;   $1: RSI <- direccion del string
;   $2: RDX <- lontitud del string
;*********************************************************************
%macro printM 2
    mov rax,1,
    mov rdi,1
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro
;*********************************************************************


;*********************************************************************
; Macro readM
; 
; Description:
;   Lee un string
;
; Parametros:
;   $1: RSI <- direccion de almacenamiento
;   $2: RDX <- cantidad que se va a leer
;*********************************************************************
%macro readM 2
    mov rax,0,
    mov rdi,1
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro
