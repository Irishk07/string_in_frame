.model tiny
.386
.code
org 100h

locals @@


Start:

    @@loop:
        in al, 60h
        cmp al, 01h         ; esc         
        je  @@done

        mov ax, 1111h
        mov bx, 2222h
        mov cx, 3333h
        mov dx, 4444h
        mov si, 5555h
        mov di, 6666h

        jmp @@loop

    @@done:
        mov ax, 4c00h
        int 21h

end Start
