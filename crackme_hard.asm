.model tiny 
.code
org 100h

local @@


Start:
        mov ah, 09h 
        mov dx, offset welcome
        int 21h       

        call Check_password

        cmp ax, 1
        je @@right_passwrod
        mov dx, offset wrong_password_msg
        jmp @@print_verdict

    @@right_passwrod:
        mov dx, offset right_password_msg

    @@print_verdict:
        mov ah, 09h 
        int 21h

        mov ax, 4c00h
        int 21h



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Check_password" check, right or no usering password                                ;;;;
;                                                                                                               ;
;; Entry:                                                                                                      ;;
;                                                                                                               ;
;; Exit:        AX = 1 if right, AX = 0 if wrong                                                               ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:   AX, BX, CX, SI, DI                                                                             ;;
;_______________________________________________________________________________________________________________;

Check_password  proc
        push bp
        mov bp, sp

        ; read user password
        sub sp, 16d
        mov ah, 03fh
        mov bx, 0
        mov cx, 255d
        lea dx, [bp - 16d]
        int 21h

        lea si, [bp - 16d]
        mov di, offset correct_password
        xor cx, cx
        mov cl, cs:[len_of_password]
        dec cx

    @@check_password_loop:
        mov al, cs:[si]
        mov bl, cs:[di]
        cmp al, bl
        jne @@check_end_symbs
        inc si
        inc di
        loop @@check_password_loop

    @@check_end_symbs:
        cmp cl, 0
        jne @@wrong_answer
        mov al, cs:[si]
        cmp al, 0Dh                 ; CR
        je @@right_answer
        cmp al, 0Ah                 ; LF
        je @@right_answer
        cmp al, 0
        jne @@wrong_answer

    @@right_answer:
        mov ax, 1
        jmp @@done

    @@wrong_answer:
        xor ax, ax

    @@done:
        add sp, 16d
        pop bp
        ret

                endp


welcome             db 'Please, enter the password:', 0Dh, 0Ah, '$'

correct_password    db 'O my god!$'
len_of_password     db $ - correct_password

right_password_msg  db 'Access granted$'
wrong_password_msg  db 'Access denied$'


end Start