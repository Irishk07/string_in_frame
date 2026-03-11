.model tiny 
.code
org 100h

locals @@


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
        call Hash

        mov dx, offset right_password_msg
        cmp ax, cs:[correct_password]
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



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Hash" count hash of string                                                         ;;;;
;                                                                                                               ;
;; Entry:       SI - address of string                                                                         ;;
;                                                                                                               ;
;; Exit:        AX = hash of string                                                                            ;;
;                                                                                                               ;
;; Expected:    DS = CS                                                                                        ;;
;                                                                                                               ;
;; Destroyed:   AX, SI, BX                                                                                     ;;
;_______________________________________________________________________________________________________________;

Hash        proc
        xor ax, ax
        
    @@count_hash:
        mov bl, ds:[si]         
        
        cmp bl, 0Dh
        je @@done
        cmp bl, 0Ah
        je @@done
        cmp bl, 0
        je @@done
        cmp bl, '$'
        je @@done
        
        push bx
        mov bx, ax           
        shl ax, 5            
        sub ax, bx           ; hash * 32 - hash = hash * 31
        pop bx
        xor bh, bh
        add ax, bx           ; hash = hash * 31 + ds:[si]

        inc si        
        jmp @@count_hash
        
    @@done:
        ret

            endp


welcome             db 'Please, enter the password:', 0Dh, 0Ah, '$'

correct_password    dw 0EA48h

right_password_msg  db 'Access granted$'
wrong_password_msg  db 'Access denied$'

user_password       db 16d dup (0)
yes_or_no_flag      db 0

end Start