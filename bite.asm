section .data
    lineas db 0

section .bss
    file resb 100
    buffer resb 4096
    anterior resb 4096
    despues resb 4096
    overwrite resb 4096
    input resb 1

section .text
    global _start

_start:
    pop rax             ; obtiene cantidad de argumentos
    
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
    mov rsi,file
    mov rdx,99
    call readInput
    
    mov rsi,file
    call delReturn          ; delete file 0ah

    call openFile
    ; hasta aqui el archivo se abre en modo lectura y guarda todo lo del archivo en el buffer
    
    mov rsi,buffer          ; contamos
    call countLines         ; cuantas lineas
    mov [lineas],rax        ; tiene el archivo

    mov rsi,buffer
    push rsi

ReadLine:
    call clearScreen
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
    
    mov rsi,input
    mov rdx,1
    mov rdi,0
    mov rax,0
    syscall

    cmp byte[input],"e"
    je ReadLine.edit

    cmp byte[input],0ah
    jne ReadLine.end 


    cmp r12,[lineas]
    je ReadLine.reset
    inc r12

    jmp ReadLine

    ReadLine.reset:
        pop rsi
        mov rsi,buffer
        push rsi
        xor r12,r12
        jmp ReadLine

    ReadLine.edit:
        pop rsi
        call guardarDespues
        call guardarAnterior
        jmp ReadLine.end

    ReadLine.end:
        mov rsi,despues
        call writeString
        mov rsi,anterior
        call writeString
        

    jmp _end

_oneArg:

    jmp _end

_function:
    jmp _end


; ************* FUNCTIONS ****************
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
    archivoMsg db "Linea actual del rchivo que se esta editando > ",0
    enter0ah db 0ah,0
    clearTerm db 27,"[H",27,"[2J"
    clearLen equ $ - clearTerm
    helpPrefix db "--help",0
    hexPrefix db "-h",0