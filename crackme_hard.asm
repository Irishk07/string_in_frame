.model tiny 
.code
org 100h

locals @@


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
        call Hash

        cmp ax, cs:[correct_password]
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


end Start