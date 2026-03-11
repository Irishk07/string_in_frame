.model tiny
.386
.code
org 100h

locals @@


Start:

        mov ax, 1111h
        mov bx, 2222h
        mov cx, 3333h
        mov dx, 4444h
        mov si, 5555h
        mov di, 6666h
        mov bp, 7777h
        push 8888h
        pop ds
        push 9999h
        pop es
        push 0000h
        pop ss

    @@loop:
        cli
        in al, 60h
        cmp al, 01h         ; esc 
        add sp, 10h  
        mov al, 11h 
        jne @@loop


    @@done:
        mov ax, 4c00h
        int 21h

end Start
