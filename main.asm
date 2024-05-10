%include "macros.asm"

section .data
    ingresarArchivoMsg db "Ingrese el nombre del archivo: ",0
    opcionInvalidaMsg db "Funcion invalida, utilice --help para obtener ayuda",0ah,0
    helpMsg db 0ah,"Manual de ayuda",0ah
            db "----------------------------------------------------------------------------------------",0ah
            db "--help                               > Mostrar manual de ayuda",0ah
            db "-r <nombreArchivo>                   > Leer un archivo",0ah
            db "-h <nombreArchivo>                   > Lee un archivo en hexadecimal",0ah,
            db "-d <nombreArchivo1> <nombreArchivo2> > Muestra la diferencia entre dos archivos",0ah,0
    errorArchivoMsg db "Error al abrir archivo",0ah,0
    editando db " | Archivo que se esta editando>",0ah,0
    lineaActual db "Linea actual: ",0
    lineNumber db 0
    lineas db 0


section .bss
    nombreArchivo resb 100  ; maximo 100 bytes de nombre
    buffer resb 4096       ; maximo 4096 bytes de archivo
    input resb 1
    anterior resb 4096
    despeus resb 4096
    

section .text
    extern openFile, delReturn, convertToASCII, strLen, WriteString, readStr, cmpStr, readFile, strchr, strLen2
    extern closeFile, printStr, ClearScreen
    global _start

_start:
    pop rax                 ; sacamos cuantos argumentos le pasamos
    
    cmp rax,1               ; si es solo un argumento, le
    je _noArg               ; preguntamos el nombre del archivo

    cmp rax,2               ; si tiene dos argumentos debe tener
    je _function            ; una funcion

    cmp rax,3               ; si tiene 3 argumentos debe
    ; je _function2           ; ser para editar o ver

_end:
    ; Exit
    mov rax, 60             ; syscall number for exit
    xor rdi, rdi            ; return 0 status
    syscall


_noArg:
    ; si no hay argumentos, preguntara por el nombre del archivo
    call ClearScreen

    mov rsi, ingresarArchivoMsg
    call WriteString

    ; obtiene el nombre de archivo
    mov rsi,nombreArchivo
    mov rdx,99
    call readStr

    ; elimina el 0ah del nombre de archivo
    mov rsi,nombreArchivo
    call delReturn
    
    ; vamos a abrir el archivo
    mov rdi,nombreArchivo           ; rdi recibe el nombre de archivo
    mov rdx,400o                    ; user has read permission
    mov rsi,100o                    ; flag o mode?
    call openFile                   ; llamamos a openFile
    push rax                        ; guardamos el fd
    cmp rax,1                       ; vemos si nos
    jb _openError                   ; dio un error
    
    pop rdi                         ; rdi recibe fd
    push rdi                        ; guarda fd
    mov rsi,buffer                  ; se guarda en buffer
    mov rdx,4096                    ; los 4096 bytes (si lo tiene)
    call readFile                   ; del archivo que se va a leer

    pop rdi
    call closeFile                  ; cerramos el archivo

    mov rsi,buffer
    call CountLines
    inc rax
    mov [lineas],rax
    
    mov rsi,buffer
    call ReadLine

    mov rsi,anterior
    call WriteString
    
    jmp _end

_function:
    pop rax                 ; obtiene el nombre del programa
    pop rdi                 ; obtiene el prefijo
    mov rsi,helpPrefix      ; rsi recibe el prefijo de sistema
    call cmpStr             ; comparamos si es igual a "-H"
    cmp rax,1               ; si es igual
    je _displayHelp         ; mostramos el mensaje de ayuda

    jmp _invalidPrefix

_displayHelp:
    mov rsi,helpMsg
    call WriteString
    jmp _end

_invalidPrefix:
    ; imprime que el prefijo es invalido y cierra el programa
    mov rsi,opcionInvalidaMsg
    call WriteString
    jmp _end

_openError:
    mov rsi,errorArchivoMsg
    call WriteString


; ****************** F U N C T I O N S ************************
ReadLine:
    ; rsi: buffer
    ReadLine.while:
        push rsi                ; guardamos el buffer
        push rsi                ; guardamos el buffer

        call strLen2            ; obtenemos el puntero del primer 0ah que se encuentre
        push rax                ; guardamos la cantidad de caracteres

        ; limpiamos el screen
        call ClearScreen
        mov rsi,nombreArchivo
        call WriteString
        mov rsi,editando
        call WriteString

        pop rdx                 ; sacamos la cantidad de caracteres
        pop rsi                 ; sacamos el puntero
        call printStr           ; imprimimos la linea
        
        pop rdi                 ; sacamos el puntero de la linea actual
        mov r10,rdi
        mov sil,0ah             ; buscamos el siguiente
        call strchr             ; salto de linea
        inc rax                 ; aumentamos el puntero a uno
        push rax                ; guardamos el nuevo puntero en la pila

        mov rsi,input           ; preguntamos al usuario que quiere hacer
        mov rdi,0
        mov rax,0
        mov rdx,1
        syscall

        cmp byte[input],0ah
        pop rsi
        je ReadLine.nextLine
        cmp byte[input],"e"
        je ReadLine.editLine
        jmp ReadLine.end

    ReadLine.nextLine:
        ; prints
        jmp ReadLine.while

    ReadLine.editLine:
        mov rsi,buffer
        call GuardarAnterior
        ret

    ReadLine.end:
        ret

GuardarAnterior:
    ; rsi: buffer
    ; r10: condicion de parada
    xor rdx,rdx
    GuardarAnterior.while:
        cmp rsi,r10
        je GuardarAnterior.end
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[anterior+rdx],bl
        inc rsi
        inc rdx
        jmp GuardarAnterior.while
    GuardarAnterior.end:
        ret


CountLines:
; cuenta cuantas lineas (0ah) tiene
    xor rcx,rcx
    CountLines.while:
        cmp byte[rsi],0
        je CountLines.end
        cmp byte[rsi],0ah
        je CountLines.addLine
        inc rsi
        jmp CountLines.while
        CountLines.addLine:
            inc rcx
            inc rsi
            jmp CountLines.while
    CountLines.end:
        mov rax,rcx
        ret


section .data
    helpPrefix db "--help",0
    readPrefix db "-r",0