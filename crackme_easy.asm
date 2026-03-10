.model tiny 
.code
org 100h

local @@


Start:
        mov ah, 09h 
        mov dx, offset welcome
        int 21h

        ; read user password
        mov ah, 03fh
        mov bx, 0
        mov cx, 255d
        mov dx, offset user_password
        int 21h

        mov si, offset user_password
        mov di, offset correct_password
        xor cx, cx
        mov cl, cs:[len_of_password]
        dec cx
        mov dx, offset right_password_msg

    @@check_password:
        mov al, cs:[si]
        mov bl, cs:[di]
        cmp al, bl
        jne @@check_end_symbs
        inc si
        inc di
        loop @@check_password

    @@check_end_symbs:
        cmp cl, 0
        jne @@check_flag
        mov al, cs:[si]
        cmp al, 0Dh                 ; CR
        je @@right_answer
        cmp al, 0Ah                 ; LF
        je @@right_answer
        cmp al, 0
        jne @@check_flag

    @@right_answer:
        mov cs:[yes_or_no_flag], 1
        
    @@check_flag:
        cmp cs:[yes_or_no_flag], 0
        jne @@print_verdict
        mov dx, offset wrong_password_msg

    @@print_verdict:
        mov ah, 09h 
        int 21h

        mov ax, 4c00h
        int 21h


welcome             db 'Please, enter the password:', 0Dh, 0Ah, '$'

correct_password    db 'O my god!$'
len_of_password     db $ - correct_password

right_password_msg  db 'Access granted$'
wrong_password_msg  db 'Access denied$'

bububu              db 'Bu $'

user_password       db 16d dup (0)
yes_or_no_flag      db 0

end Start