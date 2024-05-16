section .data
    lineas db 0
    fileSize dq 0

section .bss
    file resb 100                   ; buffer para almacenar el nombre de archivo1
    file2 resb 100                  ; buffer para almacenar el nombre de archivo2
    buffer resb 4096                ; buffer para almacenar el contenido de archivo
    anterior resb 4096              ; buffer para almacenar el contenido anterior a la linea actual
    despues resb 4096               ; buffer para almacenar el contenido despues de la linea actual
    overwrite resb 4096             ; buffer para almacenar la linea actual
    text resb 4096                  ; buffer para almacenar el contenido nuevo
    input resb 1                    
    char resb 3                     ; buffer para imprimir caracter hexadecimal
    buffer2 resb 4096               ; buffer para almacenar el contenido del archivo2
    diffBuffer resb 4096            ; buffer para almacenar la diferencia entre archivos
    linea1 resb 4096                ; buffer para la linea actual del buffer1
    linea2 resb 4096                ; buffer para la linea actual del buffer2
    num resb 21

section .text
    global _start

_start:
    pop rax                         ; obtiene cantidad de argumentos
    
    cmp rax,1                       ; aqui vemos si ingreso
    mov r15,rax                     ; un parametro de funcion
    je _noArg                       ; si no, vamos a preguntarle el nombre de archivo

    cmp rax,2                       ; Si ingreso parametros de funcion
    jge _oneArg                     ; en la consola, vamos a ver cual opcion

_unSupported:
    mov rsi,unSupportMsg
    call writeString

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
    pop rdi                         ; sacamos del stack el nombre del archivo1
    mov rsi,file2                   ; se lo asignamos a la memoria file2
    call storeSecondFilename        ; y guardamos el nombre en la memoria

    mov rdi,file2                   ; abrimos el 
    call fopen                      ; archivo
    push rax                        ; metemos el fd al stack

    mov rdi,rax                     ; utilizando el fd
    mov rsi,buffer2                 ; leemos los datos
    call fread                      ; del archivo y lo guardamos en el buffer2

    pop rdi                         ; sacamos el fd de la pila
    call fclose                     ; cerramos el archivo

    pop rsi                         ; sacamos el nombre del segundo archivo
    call readFilenameCmdLine        ; utilizamos la funcion para asignarle el nombre a file
    call openFile                   ; abrimos el archivo y lo guardamos en buffer

    mov rsi,buffer                  ; guardamos
    mov rdi,buffer2                 ; rsi y rdi
    push rsi                        ; en el stack para
    push rdi                        ; ver la diferencia entre ambos buffers
_viewDiffLine:
    mov rsi,diffBuffer              ; limpiamos el buffer
    call cleanBuffer                ; de diferencia

    mov rsi,linea1                  ; limpiamos el buffer
    call cleanBuffer                ; linea1

    mov rsi,linea2                  ; limpiamos el buffer
    call cleanBuffer                ; linea2
    pop rdi                         ; sacamos el puntero de la buffer2
    call storeLine1                 ; guardamos la linea actual del buffer2
    ;rax tiene el siguiente puntero del buffer2
    mov rdi,rax                     ; guardamos el nuevo puntero de la siguiente linea en rdi
    
    pop rsi                         ; sacamos el puntero del buffer1
    push rdi                        ; guardamos RDI (siguiente puntero de buffer2)
    call storeLine2                 ; y almacenamos la linea actual del buffer1
    ;rax tiene el siguietne puntero del buffer1
    mov rsi,rax                     ; movemos el siguiente puntero de la linea a rsi
    
    push rsi                        ; guardamos RSI (siguiente puntero de buffer1)
    
    call compareLines               ; comparamos ambas lineas

    mov rsi,diffBuffer              ; imprimos
    call writeString                ; la diferencia

    mov rsi,input                   ; obtenemos el input del usuario
    mov rdx,1
    call readInput

    cmp byte[input],0ah             ; si es diferente a ENTER
    jne _end                        ; termina el programa

    jmp _viewDiffLine

_viewHex:
    pop rsi                         ; sacamos el nombre de archivo
    call readFilenameCmdLine        ; mediante la funcion

    call openFile                   ; abrimos el archivo y lo almacenamos al buffer

    call clearScreen                ; limpiamos la pantalla

    mov rdi,buffer                  ; utilizando el buffer
    call viewHex                    ; leemos en formato hexadecimal cada byte
    jmp _end

_editFile:
    pop rsi                         ; sacamos el nombre de archivo
    call readFilenameCmdLine        ; leemos el nombre de archivo
    jmp _openFile                   ; y saltamos hacia arriba

_displayFile:
    pop rsi                         ; sacamos el nombre de archivo
    call readFilenameCmdLine        ; leemos el nombre de archivo

    call openFile                   ; abrimos el archivo

    call clearScreen                ; limpiamos
    
    mov rsi,buffer                  ; mostramos el contenido del buffer
    call writeString
    jmp _end

_displayHelp:
    mov rsi,helpMsg                 ; mostramos el manual
    call writeString                ; de usuario/ayuda
    jmp _end

_invalidPrefix:
    ; imprime que el prefijo es invalido y cierra el programa
    mov rsi,opcionInvalidaMsg
    call writeString
    jmp _end

; ************* FUNCTIONS ****************    
compareLines:
    ; funcion que compara la linea actual del archivo 2
    ; respecto a la linea actual del archivo 1
    mov rsi,linea1
    mov rdi,linea2
    xor rcx,rcx
    compareLines.while:
        mov bl,byte[rsi]
        mov bh,byte[rdi]
        inc rdi
        inc rsi
        cmp bl,0
        je compareLines.end
        cmp bh,0
        je compareLines.end
        cmp bh,bl
        jne compareLines.addChar

        jmp compareLines.while
    compareLines.addChar:
        mov byte[diffBuffer+rcx],bl     ; agregamos lo que tiene diferente en el archivo 2 al buffer
        inc rcx
        jmp compareLines.while
    compareLines.end:
        ret

storeLine1:
    ; funcion que almacena la linea actual del buffer 1
    ; rdi: buffer1
    mov rsi,linea1
    call cleanBuffer
    xor rcx,rcx
    storeLine1.while:
        cmp byte[rdi],0ah
        je storeLine1.end
        cmp byte[rdi],0
        je storeLine1.end
        xor rbx,rbx
        mov bl,byte[rdi]
        mov byte[linea1+rcx],bl
        inc rcx
        inc rdi
        jmp storeLine1.while
    storeLine1.end:
        inc rdi
        mov rax,rdi
        ret                 ; retorna el siguiente puntero del buffer2
        
storeLine2:
    ; funcion que almacena la linea actual del buffer2
    ; rsi: buffer2
    push rsi
    mov rsi,linea2
    call cleanBuffer
    pop rsi
    xor rcx,rcx
    storeLine2.while:
        cmp byte[rsi],0ah
        je storeLine2.end
        cmp byte[rsi],0
        je storeLine2.end
        xor rbx,rbx
        mov bl,byte[rsi]
        mov byte[linea2+rcx],bl
        inc rcx
        inc rsi
        jmp storeLine2.while
    storeLine2.end:
        inc rsi
        mov rax,rsi
        ret                 ; retorna el siguiente puntero del buffer2

cleanBuffer:
    ; funcion que limpia un buffer recibido desde el rsi
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
    ; esta funcion guarda la linea actual, mas lo anterior y despues de la linea
    ; en el buffer text
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
    ; funcion cuyo proposito es eliminar el 0ah del nombre de archivo
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
    ; imprime un string utilizando strlen.
    ; no es necesario indicar cuantos caracteres sera
    ; simplemente recibe un string en rsi
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
    ; obtiene el largo de un string, hasta llegar a 0 (null terminator)
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
    ; lee un input. recibe en rsi el lugar donde se almacena
    ; y en rdx la cantidad de datos que almacenara
    ; rsi: buffer
    ; rdx: size
    push rbp
    mov rax,0
    mov rdi,0
    syscall
    pop rbp
    ret

fopen:
    ; funcion cuyo proposito es abrir el archivo
    ; rdi: filename
    push rbp
    mov rax,2
    mov rsi,400o
    mov rdx,102o
    syscall
    pop rbp
    ret

fread:
    ; funcion que lee un archivo
    ;rdi: fd
    ;rsi: buffer donde almacenara el contenido leido
    push rbp
    mov rax,0
    mov rdx,4095
    syscall
    pop rbp
    ret

fclose:
    ; cierra un archivo
    ;rdi: fd
    push rbp
    mov rax,3
    syscall
    pop rbp
    ret

strchr:
    ; funcion cuyo proposito es devolver el puntero de un caracter especifico
    ; para esta funcion la modificamos a exclusivamente 0ah o 0
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
    ; funcion que retorna el largo de un string cuando encuentre un 0ah
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
    ; funcion para imprimir un string
    ; con largo definido
    ;rdx: size
    ;rsi: buffer
    push rbp
    mov rax,1
    mov rdi,1
    syscall
    pop rbp
    ret

countLines:
    ; funcion para contar las lineas que tiene el archivo
    ; rsi: buffer
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
    ; funcion para limpiar la pantalla
    mov rsi,clearTerm
    mov rdx,clearLen
    mov rax,1
    mov rdi,1
    syscall
    ret

openFile:
    ; funcion general para abrir archivo, hacer lectura y cerrar
    push rbp
    mov rdi,file            ; rdi recibe el
    call fopen              ; puntero del nombre de archivo
    push rax                ; save fd
    push rax

    ; mov rdi,rax             ; vemos
    ; mov rax,8               ; el tamano
    ; mov rsi,0               ; del archivo
    ; mov rdx,2               ;
    ; syscall

    ; mov [fileSize],rax

    pop rdi                 ; lee el archivo
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
    ; guardamos el contenido despues de la linea actual
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
    ; funcion para guardar el contenido anterior a la linea actual
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
    ; compara strings entre rdi y rsi
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
    ; lee desde rsi el nombre de un archivo para guardarlo
    ; en memoria file. Tiene que saber la longitud
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
    ; usando la funcion readFileName, leemos y guardamos el
    ; nombre de archivo obtenido de la consola
    ; rsi recibe el nombre
    push rsi
    call strLen

    mov rdx,rax
    pop rsi
    call readFileName

    ret

power:
    ; funcion de exponente
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
    ; funcion itoa
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
    ; funcion que imprime byte en byte el valor hexadecimal
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
    ; funcion que guarda el nombre del segundo archivo
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
    unSupportMsg db "Tamano de archivo no soportado",0ah,0
    opcionInvalidaMsg db "Funcion invalida, utilice --help para obtener ayuda",0ah,0
    helpMsg db 0ah,"Manual de ayuda",0ah
            db "----------------------------------------------------------------------------------------",0ah
            db "--help                               > Muestra el manual de ayuda",0ah
            db "-r <nombreArchivo>                   > Lee un archivo",0ah
            db "-e <nombreArchivo>                   > Edita un archivo",0ah
            db "-h <nombreArchivo>                   > Lee un archivo en hexadecimal",0ah,
            db "-d <nombreArchivo1> <nombreArchivo2> > Muestra linea por linea la diferencia que tiene el archivo 2 respecto al archivo 1",0ah,0
    errorArchivoMsg db "Error al abrir archivo",0ah,0
    fileInput db "Ingrese el nombre de archivo que desea abrir para editar: ",0
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
