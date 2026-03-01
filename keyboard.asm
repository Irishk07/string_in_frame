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

COLOR_S		equ 04Fh
COLOR_F		equ 0Ch

APPEAR          equ 057h                ; F11
DISAPPEAR       equ 058h                ; F12

BUFFERS_SIZE    equ 160d * 6d


Start:
                ; save old function address
                mov ax, 3509h
                int 21h
                mov Default_offset_9, bx
                mov bx, es
                mov Default_segment_9, bx

                ;mov ax, 3508h
                ;int 21h
                ;mov Default_offset_8, bx
                ;mov bx, es
                ;mov Default_segment_8, bx
;

                push 0
                pop es
                mov bx, 4 * 09h                         ; offset of cell 09h in interrupt table

                cli                                     ; clear interrupt flag

                mov es:[bx], offset My_interrupt_9      ; offset of my func
                mov ax, cs
                mov es:[bx + 2], ax                     ; segment of my func

                sti                                     ; set interrupt flag

                ;int 09h

                ; this code need save in memory (in paragraph = 16 bytes):
                mov ax, 3100h
                mov dx, offset end_my_interrupt
                shr dx, 4
                inc dx
                int 21h



My_interrupt_9           proc

                push sp ax bx cx dx si di bp ss ds es           ; save, because we change them                

                in al, 60h
                mov dl, al

        @@first_check:
                cmp al, APPEAR                                  
                jne @@second_check
        
        @@save_screen:
                push 0b800h cs
                pop es ds

                mov si, ROW_OFFSET_F                        
                mov di, offset save_buffer
                mov cx, 80d * 6d                                ; cnt words
                cld
                rep movsw                                       ; repeat cx times: mov es:[di++], ds:[si++]

                push si cx di dx ax bx 0b800h cs
                pop ds es
                mov cx, 13d
                mov dx, 6d                                      ; save 5 registers, need skip
                call Print_registers
                pop bx ax dx di cx si
        
                jmp @@finish_of_process

        @@second_check:
                cmp al, DISAPPEAR                               
                jne @@finish_of_process

                push 0b800h cs
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
                mov si, offset frame
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



registers       db 'cs = 0000, ip = 0000, sp = 0000, ax = 0000, bx = 0000, cx = 0000, dx = 0000, si = 0000, di = 0000, bp = 0000, ss = 0000, ds = 0000, es = 0000', 0Dh

LEN_STRING      equ $ - registers

frame           db 0D5h, 0CDh, 0B8h, 0C6h, 02Eh, 0B5h, 0D4h, 0CDh, 0BEh

save_buffer     db BUFFERS_SIZE dup (0)

draw_buffer     db BUFFERS_SIZE dup (0)

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