section .data
    lineas db 0

section .bss
    file resb 100
    buffer resb 4096
    anterior resb 4096
    despues resb 4096
    overwrite resb 4096
    text resb 4096
    input resb 1

section .text
    global _start

_start:
    pop rax                         ; obtiene cantidad de argumentos
    
    cmp rax,1
    je _noArg

    cmp rax,2
    je _oneArg

    cmp rax,3
    je _function

_end:
    mov rax,60
    mov rdi,1
    syscall

; ****************************************************************
_noArg:
    mov rsi,file                    ; leemos el nombre
    mov rdx,99                      ; del archivo
    call readInput                  ; maximo 99 caracteres
    
    mov rsi,file
    call delReturn                  ; delete file 0ah

_openFile:
    call openFile                   
    ; hasta aqui el archivo se abre en modo lectura y guarda todo lo del archivo en el buffer
    
    mov rsi,buffer                  ; contamos
    call countLines                 ; cuantas lineas
    mov [lineas],rax                ; tiene el archivo

    mov rsi,buffer                  ; guardamos el puntero
    push rsi                        ; del buffer en la pila

ReadLine:
    ; call clearScreen
    call printArchivo
    pop rsi                         ; obtiene el puntero
    push rsi                        ; guarda el puntero
    call strLen0ah                  ; obtiene la cantidad de caracteres de la linea

    mov rdx,rax                     ; rdx recibe la cantidad de caracteres
    pop rsi                         ; sacamos el puntero
    push rsi                        ; lo guardamos en la pila
    call printf                     ; imprimimos la linea

    pop rsi                         ; sacamos el puntero
    call strchr                     ; obtenemos el siguiente puntero/linea
    push rax                        ; lo guardamos en la pila

    mov rsi,editarLinea
    call writeString

    mov rsi,overwrite
    mov rdx,4095
    call readInput
    
    mov rsi,input                   ; vemos que desea hacer el usuario
    mov rdx,1
    call readInput

    cmp byte[input],"e"
    je ReadLine.save

    cmp byte[input],0ah
    jne ReadLine.end 


    cmp r12,[lineas]
    je ReadLine.reset
    inc r12

    jmp ReadLine

    ReadLine.reset:                 ; si llego al final de lineas, vuelva al inicio
        pop rsi
        mov rsi,buffer
        push rsi
        xor r12,r12
        jmp ReadLine

    ReadLine.save:                  ; si es para editar
        pop rsi                     ; sacamos la direccion del puntero que habiamos guardado
        call guardarDespues         ; primero guardamos lo que hay despues de la linea seleccionada
        call guardarAnterior        ; luego guardamos lo anterior a la linea
        call fwrite
        ; agregar codigo para abrir archivo y escribir lo nuevo

        jmp _openFile                ; volveriamos al inicio, abrimos el archivo nuevamente e iniciar el loop
              
        

    ReadLine.end:
        mov rsi,anterior            ; imprime lo anterior
        call writeString
        mov rsi,despues             ; imprime lo despues
        call writeString

        mov rsi,overwrite
        call writeString

        jmp _end

_oneArg:

    jmp _end

_function:
    jmp _end


; ************* FUNCTIONS ****************
fwrite:
        mov rsi,anterior
        mov rdi,text
    fwrite.while.anterior:
        ; store antes, overwrite y despues en text
        cmp byte[rsi],0
        je anterior.end
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[rdi],bl
        inc rdi
        inc rsi
        jmp fwrite.while.anterior
    
        mov rsi,anterior
        mov rdi,text
    anterior.end:
        mov rsi,overwrite
    fwrite.while.overwrite:
        ; store antes, overwrite y despues en text
        cmp byte[rsi],0
        je overwrite.end
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[rdi],bl
        inc rdi
        inc rsi
        jmp fwrite.while.overwrite
    overwrite.end:
        mov rsi,despues
    fwrite.while.despues:
        ; store antes, overwrite y despues en text
        cmp byte[rsi],0
        je despues.end
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[rdi],bl
        inc rdi
        inc rsi
        jmp fwrite.while.despues
    despues.end:
        mov rax,2
        mov rdi,file
        mov rsi,066o
        mov rsi,1
        syscall
        push rax
        push rax


        mov rsi,text
        call strLen
        push rax

        pop rdx
        pop rdi
        mov rsi,text
        mov rax,1
        syscall

        pop rax
        call fclose

        ret

delReturn:
    ; rsi: buffer
    push rbp
    delReturn.while:
        cmp byte[rsi],0
        je delReturn.end
        cmp byte[rsi],0ah
        je delReturn.del
        inc rsi
        jmp delReturn.while
    delReturn.del:
        mov byte[rsi],0
        jmp delReturn.end
    delReturn.end:
        pop rbp
        ret

writeString:
    ; rsi: buffer
    push rbp
    push rsi
    call strLen
    mov rdx,rax
    pop rsi
    mov rax,1
    mov rdi,1
    syscall
    pop rbp
    ret

strLen:
    ;rsi: buffer
    push rbp
    xor rcx,rcx
    strLen.while:
        cmp byte[rsi],0
        je strLen.end
        inc rsi
        inc rcx
        jmp strLen.while
    strLen.end:
        mov rax,rcx
        pop rbp
        ret

readInput:
    ; rsi: buffer
    ; rdx: size
    push rbp
    mov rax,0
    mov rdi,0
    syscall
    pop rbp
    ret

fopen:
    ; rdi: filename
    push rbp
    mov rax,2
    mov rsi,400o
    mov rdx,100o
    syscall
    pop rbp
    ret

fread:
    ;rdi: fd
    ;rsi: buffer
    push rbp
    mov rax,0
    mov rdx,4095
    syscall
    pop rbp
    ret

fclose:
    ;rdi: fd
    push rbp
    mov rax,3
    syscall
    pop rbp
    ret

strchr:
    ; sil: caracter a buscar (en este caso 0ah)
    ; rsi: buffer
    push rbp
    strchr.while:
        cmp byte[rsi],0ah
        je strchr.end 
        cmp byte[rsi],0
        je strchr.end
        inc rsi 
        jmp strchr.while
    strchr.end:
        mov rax,rsi
        inc rax
        pop rbp
        ret

strLen0ah:
    ; rsi: buffer
    push rbp
    xor rcx,rcx
    strLen0ah.while:
        cmp byte[rsi],0ah
        je strLen0ah.end 
        cmp byte[rsi],0
        je strLen0ah.end
        inc rsi 
        inc rcx
        jmp strLen0ah.while
    strLen0ah.end:
        mov rax,rcx
        pop rbp
        ret

printf:
    ;rdx: size
    ;rsi: buffer
    push rbp
    mov rax,1
    mov rdi,1
    syscall
    pop rbp
    ret

countLines:
    push rbp
    xor rcx,rcx
    countLines.while:
        cmp byte[rsi],0ah
        je countLines.addLine
        cmp byte[rsi],0
        je countLines.end
        inc rsi
        jmp countLines.while
    countLines.addLine:
        inc rcx
        inc rsi
        jmp countLines.while
    countLines.end:
        mov rax,rcx
        inc rax
        pop rbp
        ret

clearScreen:
    mov rsi,clearTerm
    mov rdx,clearLen
    mov rax,1
    mov rdi,1
    syscall
    ret

openFile:
    push rbp
    mov rdi,file            ; rdi recibe el
    call fopen              ; puntero del nombre de archivo
    push rax                ; save fd

    mov rdi, rax            ; lee el archivo
    mov rsi,buffer          ; para guardarlo
    call fread              ; en el buffer

    pop rdi                 ; cerramos
    call fclose             ; el archivo

    pop rbp
    ret

printArchivo:
    mov rsi, archivoMsg
    call writeString
    mov rsi,file
    call strLen
    mov rdx,rax
    mov rsi,file
    call printf
    mov rsi,enter0ah
    call writeString
    ret

guardarDespues:
    ; rsi: puntero
    push rbp
    xor rcx,rcx
    guardarDespues.while:
        cmp byte[rsi],0
        je guardarDespues.end
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[despues+rcx],bl
        inc rcx
        inc rsi
        jmp guardarDespues.while
    guardarDespues.end:
        mov rax,rcx
        pop rbp
        ret
        
guardarAnterior:
    ; r12 : receives number of lines
    push r12
    dec r12
    xor rcx,rcx
    mov rsi,buffer
    xor rdx,rdx
    guardarAnterior.while:
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[anterior+rdx],bl
        inc rdx

        cmp byte[rsi],0ah
        je guardarAnterior.cmp
        inc rsi
        jmp guardarAnterior.while
    guardarAnterior.cmp:
        cmp rcx,r12
        je guardarAnterior.end
        inc rcx
        inc rsi
        jmp guardarAnterior.while
    guardarAnterior.end:
        pop r12
        ret



section .rodata
    editarLinea db 0ah,"Editar linea: ",0
    archivoMsg db "Linea actual del archivo que se esta editando > ",0
    enter0ah db 0ah,0
    clearTerm db 27,"[H",27,"[2J"
    clearLen equ $ - clearTerm
    helpPrefix db "--help",0
    hexPrefix db "-h",0