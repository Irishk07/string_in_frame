.model tiny, C
.code
org 100h

locals @@


BYTES_ON_SYMB	equ 2d
SYMBS_IN_ROW	equ 80d
BYTES_IN_ROW	equ BYTES_ON_SYMB*SYMBS_IN_ROW
CNT_ROWS        equ 25d
MAX_STRING_LEN  equ 76d

NUMBER_ROW_F	equ 11d
NUMBER_ROW_S    equ 13d
ROW_OFFSET_F    equ BYTES_IN_ROW*NUMBER_ROW_F
ROW_OFFSET_S    equ BYTES_IN_ROW*NUMBER_ROW_S

NUMBER_COLUMN_F	equ 16d
NUMBER_COLUMN_S equ 18d

BYTES_OFFSET_F	equ ROW_OFFSET_F+BYTES_ON_SYMB*NUMBER_COLUMN_F
BYTES_OFFSET_S	equ ROW_OFFSET_S+BYTES_ON_SYMB*NUMBER_COLUMN_S

VIDEO_ADDRESS   equ 0b800h
LEN_COMMAND_LINE        equ 80h
FIRST_SYMB_COMMAND_LINE equ 82h

APPEAR          equ 041h                ; F11
DISAPPEAR       equ 058h                ; F12

BUFFERS_SIZE    equ 160d * 6d


Start:

                mov si, FIRST_SYMB_COMMAND_LINE
                xor ax, ax
                mov al, ds:[LEN_COMMAND_LINE]
                mov bx, offset COLOR_S
                mov cx, offset COLOR_F
                mov dx, offset NUMBER_F
                call Read_attributes
                mov bx, offset ADDRESS_F
                call Choose_frame

                ; save old functions address
                mov ax, 3509h
                int 21h
                mov Default_offset_9, bx
                mov bx, es
                mov Default_segment_9, bx

                mov ax, 3508h
                int 21h
                mov Default_offset_8, bx
                mov bx, es
                mov Default_segment_8, bx


                push 0
                pop es
                mov bx, 4 * 09h                         ; offset of cell 09h in interrupt table
                cli                                     ; clear interrupt flag
                mov es:[bx], offset My_interrupt_9      ; offset of my func
                mov ax, cs
                mov es:[bx + 2], ax                     ; segment of my func
                push 0
                pop es
                mov bx, 4 * 08h                         ; offset of cell 09h in interrupt table
                mov es:[bx], offset My_interrupt_8      ; offset of my func
                mov ax, cs
                mov es:[bx + 2], ax                     ; segment of my func
                sti                                     ; set interrupt flag


                ; this code need save in memory (in paragraph = 16 bytes):
                mov ax, 3100h
                mov dx, offset end_my_interrupt
                shr dx, 4
                inc dx
                int 21h



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "My_interrupt_9" - system function, print registers to video_memory, when press F11 ;;;;
;                                                                                                               ;
;; Entry:                                                                                                      ;;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

My_interrupt_9           proc

                push sp ax bx cx dx si di bp ss ds es           ; save, because we change them                

                in al, 60h
                mov dl, al

        @@first_check:
                cmp al, APPEAR                                  
                jne @@second_check
        
        @@save_screen:
                mov cs:[press_flag], 1

                push VIDEO_ADDRESS cs
                pop es ds

                mov si, ROW_OFFSET_F                        
                mov di, offset save_buffer
                mov cx, 80d * 6d                                ; cnt words
                cld
                rep movsw                                       ; repeat cx times: mov es:[di++], ds:[si++]

                CALL_PRINT_REGISTERS
        
                jmp @@finish_of_process

        @@second_check:
                cmp al, DISAPPEAR                               
                jne @@finish_of_process

                mov cs:[press_flag], 0

                push VIDEO_ADDRESS cs
                pop ds es
        
                mov si, offset save_buffer                            
                mov di, ROW_OFFSET_F
                mov cx, 80d * 6d                                ; cnt words
                cld
                rep movsw                                       ; repeat cx times: mov es:[di++], ds:[si++]

        @@finish_of_process:
                ; can continue accept clicks
                in al, 61h
                or al, 80h
                out 61h, al
                and al, not 80h
                out 61h, al

                ; can continue process interrupts
                mov al, 20h
                out 20h, al

                cmp dl, APPEAR
                je @@done

                cmp dl, DISAPPEAR
                je @@done

                jmp @@ful_done

        @@done:
                pop es ds ss bp di si dx cx bx ax            
                add sp, 2d                                      ; because need pop sp

                iret

        @@ful_done:
                pop es ds ss bp di si dx cx bx ax            
                add sp, 2d                                      ; because need pop sp

                db  0eah                                        ; code of command jmp
                Default_offset_9 dw 0
                Default_segment_9 dw 0

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "My_interrupt_8" - system function, updates registers                               ;;;;
;                                                                                                               ;
;; Entry:                                                                                                      ;;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

My_interrupt_8           proc
                cmp cs:[press_flag], 1
                jne @@finish_of_process

                push sp ax bx cx dx si di bp ss ds es           ; save, because we change them                
        
                mov cx, BUFFERS_SIZE - 2
                push VIDEO_ADDRESS
                pop es                                          ; es = 0b800h
                mov di, ROW_OFFSET_F
                mov si, offset draw_buffer
                mov bx, offset save_buffer
        @@compare_buf_vm:
                mov ax, es:[di]
                cmp ax, cs:[si]
                je @@next_compare
                mov cs:[si], ax
                mov cs:[bx], ax
        @@next_compare:
                inc di
                inc si
                inc bx
                loop @@compare_buf_vm

                CALL_PRINT_REGISTERS              

                pop es ds ss bp di si dx cx bx ax            
                add sp, 2d                                      ; because need pop sp

        @@finish_of_process:
                db  0eah                                        ; code of command jmp
                Default_offset_8 dw 0
                Default_segment_8 dw 0

                        endp



;_______________________________________________________________________________________________________________;
;;;;            Macro "CALL_PRINT_REGISTERS" call function Print_Registers and push all arguments            ;;;;
;                                                                                                               ;
;; Entry:                                                                                                      ;;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

CALL_PRINT_REGISTERS    macro code

                push si cx di dx ax bx VIDEO_ADDRESS cs
                pop ds es
                mov cx, 13d
                mov dx, 6d                                      ; save 6 registers, need skip
                call Print_registers
                pop bx ax dx di cx si

                        endm


;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Print_registers" prints values of registers to video-memory                        ;;;;
;                                                                                                               ;
;; Entry:       AX, BX, CX, DX, SI, DI, BP, SS, DS, ES in stack                                                ;;
;               CX - cnt registers                                                                              ;
;               DX - cnt skip words to the top register                                                         ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h                                                                                    ;;
;                                                                                                               ;
;; Destroyed:   SI, CX, DI, AX, BX                                                                             ;;
;_______________________________________________________________________________________________________________;

Print_registers         proc   
                push bp
                mov bp, sp
                mov bx, offset registers + 5d
                shl dx, 1
        @@print_loop:
                mov si, cx
                shl si, 1
                add si, 2d                      ; top of stack is return addres
                add si, dx                      ; skip words in stack (maybe it is saved registers)
                mov ax, ss:[bp + si]
                mov di, bx

                push cx bx dx
                call Itoa_hex
                pop dx bx cx

                add bx, 11d
                loop @@print_loop
                pop bp


                xor cx, cx
                mov cx, LEN_STRING

                push ax
                mov ax, cx
                mov ah, 0
                add ax, MAX_STRING_LEN          ; 80-2-2 (2 = space, 2 = frame)
                xor dx, dx              
                mov bx, MAX_STRING_LEN  
                div bx                          ; ax = (cx + MAX_STRING_LEN - 1) / MAX_STRING_LEN - cnt rows
                mov bx, ax                      ; bx = cnt rows
                pop ax

                push es di ax cx dx bx si
                push cs
                pop es                          ; es = cs
                mov ah, COLOR_F
                mov si, cs:[ADDRESS_F]
                mov di, offset draw_buffer
                call Print_Frame
                pop si bx dx cx ax di

                push si di ax dx
                mov si, offset registers
                mov ah, COLOR_S
                mov di, offset draw_buffer
                call Print_String
                pop dx ax di si es              ; es = 0b800h

                push cx di si
                mov cx, BUFFERS_SIZE
                shr cx, 1                       ; cx = cnt words
                mov di, ROW_OFFSET_F
                mov si, offset draw_buffer
                cld
                rep movsw                       ; repeat cx times: mov es:[di++], ds:[si++]
                pop si di cx

                ret
                        endp


;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Itoa_hex" converts hex number (2 bytes) to chars                                   ;;;;
;                                                                                                               ;
;; Entry:       AX - number                                                                                    ;;                               
;               DI - addres for write                                                                           ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    DS = CS                                                                                        ;;
;                                                                                                               ;
;; Destroyed:   BX, CX, DX                                                                                     ;;
;_______________________________________________________________________________________________________________;

Itoa_hex                proc

                mov bx, ax
                mov cx, 4d
                add di, 3d 

        @@print_one_digit:
                mov dx, bx
                and dx, 000Fh           ; last digit
                call Digit_to_char
                mov ds:[di], al
                dec di
                shr bx, 4d 
                loop @@print_one_digit

                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Digit_to_char" converts one hex digit to a char                                    ;;;;
;                                                                                                               ;
;; Entry:       DL - hex digit                                                                                 ;;
;                                                                                                               ;
;; Exit:        AL - ASCII code                                                                                ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;


Digit_to_char           proc

                cmp dl, 9d
                ja @@alpha
                add dl, '0'
                jmp @@done

        @@alpha:
                add dl, 'A' - 10d

        @@done:
                mov al, dl
                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Print_String" prints string to buffer                                              ;;;;
;                                                                                                               ;
;; Entry:       SI - the position of string from which string is printing                                      ;;
;               AH - color of string + back_ground                                                              ;
;               CL - len of printing string                                                                     ;
;               DI - address of buffer                                                                          ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = CS                                                                                        ;;
;                                                                                                               ;
;                                                                                                               ;
;; Destroyed:   SI, DI, AX, DX                                                                                 ;;
;_______________________________________________________________________________________________________________;

                rep movsw                       ; repeat cx times: mov es:[di++], ds:[si++]

Print_String            proc
                push ax
                mov ax, cx
                mov ah, 0
                add ax, MAX_STRING_LEN  ; 80-2-2 (2 = space, 2 = frame)
                xor dx, dx              
                mov bx, MAX_STRING_LEN  
                div bx                  ; ax = (cx + MAX_STRING_LEN - 1) / MAX_STRING_LEN - cnt rows
                mov bx, ax              ; bx = cnt rows
                pop ax

                push cx bx
                add di, ROW_OFFSET_S - ROW_OFFSET_F + 2d*2d

        @@print_loop_all:
                cmp bx, 1
                ja @@print_all_row

                mov bx, ax
                mov ax, cx

                shr cx, 1d              ; cx >> 1 - cx /= 2
                mov ax, 40d
                sub ax, cx              ; ax = 40 - cx
                shl ax, 1               ; ax = ax * 2
                add di, ax
                sub di, 2d*2d
                mov ax, bx

        @@print_loop:
                mov al, ds:[si]		; read symbol of string
                cmp al, 0Dh		; al == EOS or no
                je @@done       	; if (al == EOS) goto done
                stosw
                inc si			; si++
                jmp @@print_loop


        @@print_all_row:
                push cx
                mov cx, MAX_STRING_LEN
        @@print_row:
                mov al, ds:[si]         ; read symbol of string from PSP
                stosw                   ; mov es:[di++], ax
                inc si	
                loop @@print_row

                pop cx
                sub cx, MAX_STRING_LEN
                dec bx
                add di, 4d*2d
                jmp @@print_loop_all
                        
        @@done:
                pop bx cx
		ret

                        endp



;_______________________________________________________________________________________________________________;
;;;;            Macro "PRINT_ONE_ROW" prints one row of frame to video-memory                                ;;;;
;                                                                                                               ;
;; Entry:       CX - len of middle of string                                                                   ;;
;               DI - position, where the left symb should be                                                    ;
;               SI - position of left symb for frame                                                            ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;                                                                                                               ;
;; Destroyed:   DI, AX                                                                                         ;; 
;_______________________________________________________________________________________________________________;

PRINT_ONE_ROW           macro code
                mov al, ds:[si]
                stosw                   ; mov es:[di++], ax

                push cx
                mov al, ds:[si + 1d]
                rep stosw               ; stosw cx times
                pop cx

                mov al, ds:[si + 2d]
                stosw
                        endm



;_______________________________________________________________________________________________________________;
;                                          <STD call>                                                           ;
;;;;            Function "Print_Frame" print frame to buffer                                                 ;;;;
;                                                                                                               ;
;; Entry:       AH - color of frame + back_groud                                                               ;;
;               BX - cnt rows                                                                                   ;
;               SI - position from which start symbols for frame                                                ;
;               DI - address of buffer                                                                          ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    DS = ES = CS                                                                                   ;;
;                                                                                                               ;
;; Destroyed:   DI, AX, CX, DX, BX, SI                                                                         ;; 
;_______________________________________________________________________________________________________________;

Print_Frame             proc
                ; print frame in draw_buffer
                mov cx, SYMBS_IN_ROW-2d

                PRINT_ONE_ROW

                add si, 3d
                add bx, 2d
        @@print_center:
                PRINT_ONE_ROW
                dec bx
                cmp bx, 0
                jne @@print_center
                
                add si, 3d
                PRINT_ONE_ROW
                
                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Read_attributes" reads first, second and third (if there is) attributes            ;;;;
;                                                                                                               ;
;; Entry:       SI - the position from which start to read                                                     ;;
;               AL - len of command line                                                                        ;
;               BX - address for first                                                                          ;
;               CX - address for second                                                                         ;
;               DX - address for third                                                                          ;
;                                                                                                               ;
;; Exit:        Values of attributes on addresses (or default if not)                                          ;;
;                                                                                                               ;
;; Expected:    DS = CS                                                                                        ;;
;                                                                                                               ;
;; Destroyed:   SI                                                                                             ;;
;_______________________________________________________________________________________________________________;

Read_attributes         proc

                cmp al, 0
                je @@done

                dec ax
        @@read_color_of_string:
                push ax bx
                call Atoi_byte                  ; ax = color of string
                pop bx

                cmp al, -1d
                je @@done

                add si, 2d
                mov cs:[bx], al

                pop ax
                sub ax, 2d
                cmp al, 0
                je @@done
        @@read_color_of_frame:          
                push ax bx
                call Atoi_byte
                pop bx  

                cmp al, -1d
                je @@done

                add si, 2d
                mov bx, cx
                mov cs:[bx], al

                pop ax
                sub ax, 2d
                cmp al, 0
                je @@done
        @@read_number_of_frame:                  
                mov al, ds:[si]
                call Atoi_char

                cmp al, -1d
                je @@done

                add si, 2d
                mov bx, dx
                mov cs:[bx], al

        @@done:
                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Choose_frame" print addres of choosing frame                                       ;;;;
;                                                                                                               ;
;; Entry:       BX - addres for frame                                                                          ;;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

Choose_frame             proc

                cmp cs:[NUMBER_F], 0
                je @@Choose_frame_user
                cmp cs:[NUMBER_F], 3
                ja @@done

                mov ch, 0
                mov cl, cs:[NUMBER_F]
                dec cl
                push ax
                mov al, cl
                shl cl, 3d
                add cl, al                              ; (cl - 1) * 9
                pop ax
                add cx, offset frame_1
                mov cs:[bx], cx
                jmp @@done

        @@Choose_frame_user:
                mov cs:[bx], si

        @@done:
                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Atoi_byte" converts two chars to a number                                          ;;;;
;                                                                                                               ;
;; Entry:       SI - the position of the chars                                                                 ;;
;                                                                                                               ;
;; Exit:        AL - number (if OK), in error Al = -1                                                          ;; TODO podumat'
;                                                                                                               ;
;; Expected:    DS = CS                                                                                        ;;
;                                                                                                               ;
;; Destroyed:   BX, SI                                                                                         ;;
;_______________________________________________________________________________________________________________;

Atoi_byte               proc
                mov al, ds:[si]

                call Atoi_char
                cmp al, -1
                je @@error

                mov bl, al
                shl bl, 4               ; bl = al *16

                inc si
                mov al, ds:[si]

                call Atoi_char
                cmp al, -1
                je @@error

                add al, bl              ; al = bl + al (first * 16) + second
                ret

        @@error:
                mov al, -1
                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Atoi_char" converts symbol to a number  (hex)                                ;;;;
;                                                                                                               ;
;; Entry:       AL - symbol                                                                                    ;;
;                                                                                                               ;
;; Exit:        AL - number (if OK), in error Al = -1                                                          ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

Atoi_char                proc

        @@check_number:
                cmp al, '0'
                jb @@check_upper_alpha
                cmp al, '9'
                ja @@check_upper_alpha

                sub al, '0'
                ret

        @@check_upper_alpha:
                cmp al, 'A'
                jb @@check_lower_alpha
                cmp al, 'F'
                ja @@check_lower_alpha

                sub al, 'A'
                add al, 10d
                ret

        @@check_lower_alpha:
                cmp al, 'a'
                jb @@error
                cmp al, 'f'
                ja @@error

                sub al, 'a'
                add al, 10d
                ret

        @@error:
                mov al, -1d
                ret

                        endp



COLOR_S		db 04Fh

COLOR_F		db 0Ch

NUMBER_F        db 1

ADDRESS_F       dw offset frame_1

frame_1         db 0D5h, 0CDh, 0B8h, 0C6h, 02Eh, 0B5h, 0D4h, 0CDh, 0BEh

frame_2         db 0DAh, 0C4h, 0BFh, 0B3h, 02Eh, 0B3h, 0C0h, 0C4h, 0D9h

frame_3         db 003h, 003h, 003h, 004h, 003h, 004h, 003h, 003h, 003h

registers       db 'cs = 0000, ip = 0000, sp = 0000, ax = 0000, bx = 0000, cx = 0000, dx = 0000, si = 0000, di = 0000, bp = 0000, ss = 0000, ds = 0000, es = 0000', 0Dh

LEN_STRING      equ $ - registers

save_buffer     db BUFFERS_SIZE dup (0)

draw_buffer     db BUFFERS_SIZE dup (0)

press_flag      db 0

end_my_interrupt:


end Start





;_______________________________________________________
; Start:  
;         push 0b800h
;         pop es
;         mov bx, (80d * 5 + 40d) * 2
;         mov ah, 4eh
; 
;     print_symb:
;         in al, 60h
;         mov es:[bx], ax
;         cmp al, 1           ; cmp with esc
;         jne print_symb
; 
; end Start
;______________________________________________________