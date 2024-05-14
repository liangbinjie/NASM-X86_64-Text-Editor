section .data
    lineas db 0
    lineas2 db 0

section .bss
    file resb 100
    file2 resb 100
    buffer resb 4096
    anterior resb 4096
    despues resb 4096
    overwrite resb 4096
    text resb 4096
    input resb 1
    char resb 3
    buffer2 resb 4096
    diffBuffer resb 4096
    linea1 resb 4096
    linea2 resb 4096

section .text
    global _start

_start:
    pop rax                         ; obtiene cantidad de argumentos
    
    cmp rax,1
    mov r15,rax
    je _noArg

    cmp rax,2
    jge _oneArg

_end:
    mov rax,60
    mov rdi,1
    syscall

; ****************************************************************
_noArg:
    mov rsi,fileInput               ; imprimos mensaje
    call writeString                ; para que ingrese nombre archivo

    mov rsi,file                    ; leemos el nombre
    mov rdx,99                      ; del archivo
    call readInput                  ; maximo 99 caracteres
    
    mov rsi,file
    call delReturn                  ; delete file 0ah

_openFile:
    xor r12,r12                     ; limpiamos la linea actual
    mov rsi,buffer                  ; limpiamos
    call cleanBuffer                ; el buffer
    mov rsi,text                    ; limpiamos el
    call cleanBuffer                ; buffer de text

    call openFile                   ; abrimos el archivo
    ; hasta aqui el archivo se abre en modo lectura y guarda todo lo del archivo en el buffer
    
    mov rsi,buffer                  ; contamos
    call countLines                 ; cuantas lineas
    mov [lineas],rax                ; tiene el archivo

    mov rsi,buffer                  ; guardamos el puntero
    push rsi                        ; del buffer en la pila

ReadLine:
    call clearScreen                ; limpiamos la pantalla
    call printArchivo               ; imprimos msg de cual archivo estamos trabajando
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

    mov rsi,overwrite               ; limpiamos
    call cleanBuffer                ; el buffer overwrite

    mov rsi,editarLinea             ; imprimir
    call writeString                ; editar Linea msg

    mov rsi,overwrite               ; leer la
    mov rdx,4095                    ; nueva linea
    call readInput                  ; que se va a editar
    
    mov rsi,input                   ; vemos que desea hacer el usuario
    mov rdx,1                       ; si guardar
    call readInput                  ; o salir

    cmp byte[input],"s"             ; "s" para guardar
    je ReadLine.save
    
    cmp byte[input],0ah             ; diferente a "0ah" para salir
    jne ReadLine.end 

    cmp r12,[lineas]                ; comparamos si llegamos al final de
    je ReadLine.reset               ; lineas, para resetear el contador
    inc r12                         ; si no, aumentamos la linea actual

    jmp ReadLine                    ; regresamos a readLine si no hay reset

    ReadLine.reset:                 ; si llego al final de lineas, vuelva al inicio
        pop rsi                     ; saco el puntero que habia guardado
        mov rsi,buffer              ; le pongo de nuevo el puntero de buffer
        push rsi                    ; lo guardo en la pila
        xor r12,r12                 ; limpio linea actual
        jmp ReadLine                ; volvemos a readLine

    ReadLine.save:                  ; editamos el archivo

        mov rsi,despues             ; limpiamos
        call cleanBuffer            ; los buffers
        mov rsi,anterior            ; anterior
        call cleanBuffer            ; y despues


        pop rsi                     ; sacamos la direccion del puntero que habiamos guardado
        call guardarDespues         ; primero guardamos lo que hay despues de la linea seleccionada
        call guardarAnterior        ; luego guardamos lo anterior a la linea
        call fwrite                 ; guardamos lo nuevo al archivo

        jmp _openFile               ; volveriamos al inicio, abrimos el archivo nuevamente e iniciar el loop
              
    ReadLine.end:
        jmp _end

_oneArg:
    pop rax                         ; obtiene el nombre del programa
    pop rdi                         ; obtiene el prefijo
    mov rsi,helpPrefix              ; rsi recibe el prefijo de sistema
    call cmpStr                     ; comparamos si es igual a "-H"
    cmp rax,1                       ; si es igual
    je _displayHelp                 ; mostramos el mensaje de ayuda

    cmp r15,2                       ; si no se ingreso nombre de archivo
    je _invalidPrefix                         ; termina el programa

    mov rsi,readPrefix              ; si es para leer
    call cmpStr             
    cmp rax,1   
    je _displayFile                 ; imprimos el contenido

    mov rsi,editPrefix              ; si es para editar
    call cmpStr             
    cmp rax,1
    je _editFile                    ; solo vamos de vuelta

    mov rsi,hexPrefix               ; si es para editar
    call cmpStr             
    cmp rax,1
    je _viewHex                     ; solo vamos de vuelta

    cmp r15,4
    jne _invalidPrefix

    mov rsi,diffPrefix              ; ver la diferencia
    call cmpStr                     ; entre dos archivos
    cmp rax,1                       ;
    je _viewDiff                    ;

    jmp _invalidPrefix

_viewDiff:
    pop rdi
    mov rsi,file2
    call storeSecondFilename

    mov rdi,file2
    call fopen
    push rax


    mov rdi,rax
    mov rsi,buffer2
    call fread

    mov rsi,buffer2                  ; contamos
    call countLines                 ; cuantas lineas
    mov [lineas2],rax                ; tiene el archivo

    pop rdi
    call fclose

    pop rsi
    call readFilenameCmdLine
    call openFile

    mov rsi,buffer                  ; contamos
    call countLines                 ; cuantas lineas
    mov [lineas2],rax                ; tiene el archivo

    mov r9,[lineas]
    mov r8,[lineas2]
    cmp r8,r9
    jge continue
    mov r9,r8
continue:
    mov [lineas],r9
    ; mov rsi,buffer
    ; push rsi
    ; *******************************
_viewDiffLine:
    ; call clearScreen                ; limpiamos la pantalla
    ; pop rsi                         ; obtiene el puntero
    ; push rsi                        ; guarda el puntero
    ; call strLen0ah                  ; obtiene la cantidad de caracteres de la linea

    ; mov rdx,rax                     ; rdx recibe la cantidad de caracteres
    ; pop rsi                         ; sacamos el puntero
    ; push rsi                        ; lo guardamos en la pila
    ; call printf                     ; imprimimos la linea

    ; pop rsi                         ; sacamos el puntero
    ; call strchr                     ; obtenemos el siguiente puntero/linea
    ; push rax                        ; lo guardamos en la pila
    
    ; mov rsi,input                   ; vemos que desea hacer el usuario
    ; mov rdx,1                       ; si guardar
    ; call readInput                  ; o salir
    
    ; cmp byte[input],0ah             ; diferente a "0ah" para salir
    ; jne _viewDiffLine.end 


    ; cmp r12,[lineas]                ; comparamos si llegamos al final de
    ; je _viewDiffLine.end          ; lineas, para resetear el contador
    ; inc r12                         ; si no, aumentamos la linea actual

    ; jmp _viewDiffLine                    ; regresamos a readLine si no hay reset
    xor rcx,rcx
    xor rbx,rbx
    mov rsi,buffer
    mov rdi,buffer2
    viewDiff.while:
        mov bl,byte[rsi]
        mov bh,byte[rdi]
        inc rsi
        inc rdi
        cmp bl,0
        je _viewDiffLine.end

        cmp bh,0
        je _viewDiffLine.end

        cmp bl,bh
        jne addDiff
        jmp viewDiff.while

    addDiff:
        mov byte[diffBuffer+rcx],bl
        inc rcx
        jmp viewDiff.while

    _viewDiffLine.end:
        mov rsi,diffBuffer
        call writeString
        jmp _end

_viewHex:
    pop rsi
    call readFilenameCmdLine

    call openFile

    call clearScreen

    mov rdi,buffer
    call viewHex
    jmp _end

_editFile:
    pop rsi
    call readFilenameCmdLine
    jmp _openFile

_displayFile:
    pop rsi
    call readFilenameCmdLine

    call openFile

    ; call clearScreen

    mov rsi,buffer
    call writeString
    jmp _end

_displayHelp:
    mov rsi,helpMsg
    call writeString
    jmp _end

_invalidPrefix:
    ; imprime que el prefijo es invalido y cierra el programa
    mov rsi,opcionInvalidaMsg
    call writeString
    jmp _end



; ************* FUNCTIONS ****************
cleanBuffer:
    ; rsi: buffer
    cleanBuffer.while:
        cmp byte[rsi],0
        je cleanBuffer.end
        mov byte[rsi],0
        inc rsi
        jmp cleanBuffer.while
    cleanBuffer.end:
        ret

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
        inc rax
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
    mov rdx,102o
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
    ; Imprime un mensaje de en cual archivo esta trabajando el usuario
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
        inc rsi
        inc rcx
        jmp guardarDespues.while
    guardarDespues.end:
        mov rax,rcx
        pop rbp
        ret
        
guardarAnterior:
    ; r12 : receives number of lines
    push r12
    cmp r12,0
    je guardarAnterior.end
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

readFileName:
    ; rsi: fileName
    ; rdx: filename length
    xor rcx,rcx
    readFileName.while:
        cmp rcx,rdx
        je readFileName.end
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[file+rcx],bl
        inc rcx
        inc rsi
        jmp readFileName.while
    readFileName.end:
        ret

readFilenameCmdLine:
    push rsi
    call strLen

    mov rdx,rax
    pop rsi
    call readFileName

    ret

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

viewHex:
    ; rdi: buffer
    viewHex.while:
        cmp byte[rdi],0
        je viewHex.end
        mov rsi,char
        mov r11,[rdi]
        mov r12,16
        mov rcx,1
        call convertToASCII
        inc rdi

        push rdi
        mov rsi,char
        call writeString
        pop rdi

        jmp viewHex.while
    viewHex.end:
        ret

storeSecondFilename:
    ; rsi: second file buffer
    ; rdi: first filename
    storeSecondFilename.while:
        cmp byte[rdi],0
        je storeSecondFilename.end
        xor rbx,rbx
        mov bl,byte[rdi]
        mov byte[rsi],bl
        inc rdi
        inc rsi
        jmp storeSecondFilename.while
    storeSecondFilename.end:
        mov rsi,file
        call cleanBuffer
        ret
    

section .rodata
    opcionInvalidaMsg db "Funcion invalida, utilice --help para obtener ayuda",0ah,0
    helpMsg db 0ah,"Manual de ayuda",0ah
            db "----------------------------------------------------------------------------------------",0ah
            db "--help                               > Muestra el manual de ayuda",0ah
            db "-r <nombreArchivo>                   > Lee un archivo",0ah
            db "-e <nombreArchivo>                   > Edita un archivo",0ah
            db "-h <nombreArchivo>                   > Lee un archivo en hexadecimal",0ah,
            db "-d <nombreArchivo1> <nombreArchivo2> > Muestra la diferencia entre dos archivos",0ah,0
    errorArchivoMsg db "Error al abrir archivo",0ah,0
    fileInput db "Ingrese el nombre de archivo: ",0
    editarLinea db 0ah,"Editar linea: ",0
    archivoMsg db "Linea actual del archivo que se esta editando > ",0
    enter0ah db 0ah,0
    clearTerm db 27,"[H",27,"[2J"
    clearLen equ $ - clearTerm
    helpPrefix db "--help",0
    readPrefix db "-r",0
    editPrefix db "-e",0
    hexPrefix db "-h",0
    diffPrefix db "-d",0
