;*********************************************************************
; Libreria de procesos [utils.asm]
; Autor: Binjie Liang
; NASM X86_64
;
; LINKING:
;
; nasm -f elf64 <programFileName>.asm -o <programFileName>.o
; nasm -f elf64 utils.asm -o utils.o
; ld <programFileName>.o -o <programFileName> utils.o
;*********************************************************************

section .data
    clearTerm db 27,"[H",27,"[2J"
    clearLen equ $ - clearTerm

section .text
    GLOBAL strchr, ClearScreen, WriteString, delReturn, cmpStr, printStr, readStr, strLen, strLen2, validNum, power, readNum, convertToASCII, clearASCII, openFile, closeFile, countChar, readFile

ClearScreen:
    mov rax,1
    mov rdi,1
    mov rsi,clearTerm
    mov rdx,clearLen
    syscall
    ret

;*********************************************************************
; void cmpStr()
; 
; Description:
;   Compara si dos strings son iguales
;
; Arguments:
;   rdx: direccion del string
;   rsi: direccion del string
;   r12: cantidad de ciclos
; 
; Returns:
;   rax: 1 si es igual, 0 si no son iguales
;*********************************************************************
cmpStr:
    xor rcx,rcx
    xor rbx,rbx
    cmpStr.while:
        cmp rcx,2           
        je cmpStr.endEqual
        mov bl,byte[rdi+rcx]
        cmp byte[rsi+rcx],bl
        jne cmpStr.endNotEqual
        inc rcx
        jmp cmpStr.while
    cmpStr.endEqual:
        mov rax,1
        ret
    cmpStr.endNotEqual:
        mov rax,0
        ret
;*********************************************************************

;*********************************************************************
; void printStr()
; 
; Description:
;   Imprime un string
;
; Arguments:
;   rdx: cantidad de caracteres que se van a imprimir.
;   rsi: direccion del string.
; 
; Returns:
;   rax: la logitud del string
;*********************************************************************
printStr:
    mov rax,1
    mov rdi,1
    syscall
    ret
;********************************************************************


;*********************************************************************
; void readStr()
; 
; Description:
;   Lee un string
;
; Arguments:
;   rdx: cantidad de caracteres que se van a almacenar.
;   rsi: direccion donde se almacena el string.
; 
; Returns:
;   rax: la logitud del string
;*********************************************************************
readStr:
    mov rax,0
    mov rdi,1
    syscall
    ret
;********************************************************************

;*********************************************************************
; int strLen()
; 
; Description:
;   Retorna la longitud de un string
;
; Arguments:
;   rsi: direccion donde se encuentra el string.
; 
; Returns:
;   rax: la logitud del string
;*********************************************************************
strLen:                        
    xor rcx,rcx                 ; rcx funciona como el contador e indice
strLen.sig:
    cmp byte [rsi + rcx],0      ; por cada byte, compara si ya llego al final
    jz strLen.fin               ; si es asi, termina el programa
    inc rcx                     ; si no, incrementa el contador
    jmp strLen.sig              ; y nos devolvemos de nuevo al ciclo
strLen.fin:
    mov rax,rcx                 ; al final le metemos el len a rax
    ret
;********************************************************************


;*********************************************************************
; int strLen2()
; 
; Description:
;   Retorna la longitud de un string (excluye 0ah)
;
; Arguments:
;   rsi: direccion donde se encuentra el string.
; 
; Returns:
;   rax: la logitud del string
;*********************************************************************
strLen2:                        
    xor rcx,rcx                 ; rcx funciona como el contador e indice
strLen2.sig:
    cmp byte [rsi + rcx],0ah      ; por cada byte, compara si ya llego al final
    jz strLen.fin               ; si es asi, termina el programa
    inc rcx                     ; si no, incrementa el contador
    jmp strLen.sig              ; y nos devolvemos de nuevo al ciclo
strLen2.fin:
    mov rax,rcx                 ; al final le metemos el len a rax
    ret
;********************************************************************

WriteString:
    push rsi
    call strLen
    mov rdx,rax
    pop rsi
    call printStr
    ret


;*********************************************************************
; boolean validNum()
; 
; Description:
;   Verifica si el ingreso de un input de un numero en caracteres ASCII
;   es un numero, es decir, no tiene caracteres que no sean numericos
;
; Arguments:
;   rsi: direccion donde se encuentra el input.
; 
; Returns:
;   rax: retorna 1 si es un numero valido, 0 si no lo es
;*********************************************************************
validNum:
    xor rcx,rcx                 ; rcx funciona como el contador e indice
validNum.sig:
    mov bl,byte [rsi+rcx]
    cmp bl,0ah
    jz validNum.end
    cmp bl,30h
    jl validNum.error
    cmp bl,39h
    jg validNum.error
validNum.continue:
    inc rcx                    
    jmp validNum.sig           
validNum.end:
    mov rax,1                   
    ret
validNum.error:
    mov rax,0
    ret
;*********************************************************************


;*********************************************************************
; int power()
; 
; Description:
;   Devuelve el resultado de un exponente
;
; Arguments:
;   R12: valor de la base
;   RCX: valor del exponente
; 
; Returns:
;   rax: retorna el resultado
power:
    cmp rcx,0
    mov rax,1
    jz power.esCero
power.ciclo:
    cmp rcx,1
    mov rbx,r12
    jz power.end
    mul rbx
    dec rcx
    jmp power.ciclo

power.end:
    mul rbx
    ret
power.esCero:
    ret
;*********************************************************************


;*********************************************************************
; int readNum()
; 
; Description:
;   Lee un numero en ASCII y lo devuelve en decimal
;
; Arguments:
;   RSI: direccion del numero
;   RCX: debe estar en 0
;   RDX: recibe el largo del numero (sin contar el 0ah)
;   R12: recibe la base del exponente (a)^x -> a
;   R11: Limpiar antes de la llamada
;   R10: recibe el largo del numero
; 
; Returns:
;   rax: retorna el resultado
readNum:   
    cmp rcx, r10                      ; comparamos si el ciclo es igual al largo del numero
    jz readNum.endWhile             ; si es igual termina el proceso
    dec rdx                         ; si no, entonces -> ; rdx sera el indice del numero,
    xor rbx,rbx
    mov bl,byte [rsi+rdx]           ; como va de atras hacia adelante bl recibe el numero
    sub bl,30h                      ; le substraemos 30h
    push rdx                        ; debido a que la llamada a un proceso nos pierde algunos datos
    push rbx                        ; guardamos
    push rcx                        ; los datos en la pila
    call power                      ; rcx tiene el valor del exponente
    pop rcx                         ; a sus registros
    pop rbx                         ; correspondientes
    mul rbx                         ; multiplicamos el resultado de la potencia de 10 con el numero
    mov rbx, r11                    ; obtenemos el valor de r11
    add rax,rbx                     ; se lo sumamos a rax
    mov r11, rax                    ; movemos el resultado a su r11
    inc cl                         ; incrementamos el contador
    pop rdx                         ; retornamos los datos de la pila
    jmp readNum                     ; volvemos al while
readNum.endWhile:
    ret
;*********************************************************************


;*********************************************************************
; void convertToASCII()
; 
; Description:
;   Lee un numero en decimal y lo convierte en String
;
; Arguments:
;   RSI: direccion de donde se almacenara el string
;   R11: recibe el numero decimal
;   R12: recibe la base a la que se quiere convertir
;   RCX: recibe la cantidad de caracteres que almacenara 
; 
; Returns:
;   rax: 0
convertToASCII:   
    cmp rax,0
    je convertToASCII.end

    mov rax,r11             ; RAX: es el dividendo
    mov rdx,0               ; RDX: guarda el residuo
    mov rbx,r12             ; RBX: es el divisor
    div rbx                 ; RAX guardara el cociente
    cmp dl,0ah              ; si el residuo es mayor que 10
    jge convertToASCII.hex  ; usamos el sistema hex
    jmp convertToASCII.nhex ; si no, decimal
    convertToASCII.hex:             
        add dl,37h              ; le sumamos 37h
        jmp convertToASCII.continue 
    convertToASCII.nhex:    
        add dl,30h              ; le sumamos 30h
    convertToASCII.continue:
        mov [rsi+rcx],dl        ; lo metemos en la direccion
        dec rcx                 ; va de atras hacia adelante
        mov r11,rax             ; movemos el cociente a r11
        jmp convertToASCII

convertToASCII.end:
    ret
;*********************************************************************

;*********************************************************************
; void clearASCII()
; 
; Description:
;   Llena de ceros una memoria
;
; Arguments:
;   RSI: direccion de donde se almacenara el string
;   RCX: recibe la cantidad de caracteres que almacenara 
; 
; Returns:
;   
clearASCII:
    xor rdx,rdx
clearASCII.while:
    cmp rdx,rcx
    je clearASCII.end
    mov [rsi+rdx],byte 0
    inc rdx
    jmp clearASCII.while
clearASCII.end:
    ret
;*********************************************************************

;*********************************************************************
; void openFile()
; 
; Description:
;   Lee un archivo y devuelve el file decriptor
;
; Arguments:
;   rdi: filepath
; 
; Returns:
;   rax: file decriptor
openFile:
    ; mov rsi,102o                    ; O_RDWR
    ; mov rdx,700o
    mov rax,2                       ; sys_open
    syscall
    ret       ; return file decriptor
;*********************************************************************

;*********************************************************************
; void closeFile()
; 
; Description:
;   Cierra el archivo
;
; Arguments:
;   rdi: file descriptor
; 
; Returns:
;   
closeFile:
    mov rax,3
    syscall
    ret
;*********************************************************************

;*********************************************************************
; void readFile()
; 
; Description:
;   Lee un archivo y lo guarda en un buffer
;
; Arguments:
;   rdi: file descriptor
;   rsi: buffer
;   rdx: size
; 
; Returns:
;   
readFile:
    mov rax,0
    syscall
    ret
;*********************************************************************

;*********************************************************************
; void countChar()
; 
; Description:
;   Lee un string y devuelve la cantidad de caracteres que tiene
;
; Arguments:
;   rsi: string/buffer
;   rax: clear
;   rcx: clear
; 
; Returns:
;   rax: amount of characters
;   
countChar:

countChar.while:
    mov bx, word [rsi+rcx]
    cmp bl,0
    je countChar.end
    mov r14,80h
    and r14,rbx
    ror r14,7
    cmp r14,1
    je countChar.notAscii
    inc rcx
    inc rax
    jmp countChar.while
countChar.notAscii:
    add rcx,2
    inc rax
    jmp countChar.while
countChar.end:
    ret
;*********************************************************************

; Elimina 0ah de un string
delReturn:
    xor rcx,rcx
    delReturn.while:
    cmp byte[rsi+rcx],0
    je delReturn.end
    cmp byte[rsi+rcx],0ah
    je delReturn.del
    inc rcx
    jmp delReturn.while

    delReturn.del:
    mov byte[rsi+rcx],0
    inc rcx
    jmp delReturn.while

    delReturn.end:
    ret


strchr:
; strchr -> localiza un caracter en un string
    ; rdi: buffer
    ; sil: char
    strchr.loop:
        cmp byte[rdi],sil
        je strchr.end

        cmp byte[rdi],0
        je strchr.end

        inc rdi

        jmp strchr.loop

    strchr.end:
        mov rax,rdi
        ret


section .data
