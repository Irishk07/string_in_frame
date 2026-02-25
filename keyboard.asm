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

PRESS           equ 057h                ; F11
RELEASE         equ 0D7h                ; F11


Start:
                ; save old function address
                mov ax, 3509h
                int 21h
                mov Default_offset, bx
                mov bx, es
                mov Default_segment, bx

                push 0
                pop es
                mov bx, 4 * 09h                         ; offset of cell 09h in iterapt table

                cli                                     ; clear interapt flag

                mov es:[bx], offset My_interapt_9       ; offset of my func
                mov ax, cs
                mov es:[bx + 2], ax                     ; segment of my func

                sti                                     ; set interapt flag

                ; this code need save in memory (in paragraph = 16 bytes):
                mov ax, 3100h
                mov dx, offset end_my_interapt
                shr dx, 4
                inc dx
                int 21h



My_interapt_9           proc

                push sp ax bx cx dx si di bp ss ds es           ; save, because we change them                

                in al, 60h
                mov dl, al

        @@first_check:
                cmp al, PRESS                                   ; press F11
                jne @@second_check
        
        @@save_screen:
                push 0b800h cs
                pop es ds

                mov si, ROW_OFFSET_F                        
                mov di, offset screen_buffer
                mov cx, 80d * 6d                                ; cnt words
                cld
                rep movsw                                       ; repeat cx times: mov es:[di++], ds:[si++]

                push si cx di ax bx 0b800h cs
                pop ds es
                mov cx, 13d
                mov dx, 5d                                      ; save 5 registers, need skip
                call Print_registers
                pop bx ax di cx si
        
                jmp @@finish_of_process

        @@second_check:
                cmp al, RELEASE                                 ; release F11
                jne @@finish_of_process

                push 0b800h cs
                pop ds es
        
                mov si, offset screen_buffer                            
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

                ; can continue process iterapts
                mov al, 20h
                out 20h, al

                pop es ds ss bp di si dx cx bx ax            
                add sp, 2d                                      ; because need pop sp

                db  0eah                                        ; code of command jmp
                Default_offset dw 0
                Default_segment dw 0

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
;; Expected:    DS = CS                                                                                        ;;
;               ES = 0b800h                                                                                     ;
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
                mov ax, ds:[bp + si]
                shr si, 1
                lea di, [bx]

                push cx bx dx
                call Itoa_hex
                pop dx bx cx

                add bx, 11d
                loop @@print_loop
                pop bp


                xor cx, cx
                mov cx, LEN_STRING

                ; cnt rows
                push ax
                mov ax, cx
                mov ah, 0
                add ax, MAX_STRING_LEN          ; 80-2-2 (2 = space, 2 = frame)
                xor dx, dx              
                mov bx, MAX_STRING_LEN  
                div bx                          ; ax = (cx + MAX_STRING_LEN - 1) / MAX_STRING_LEN - cnt rows
                mov bx, ax
                pop ax

                push di ax cx dx bx
                push offset frame
                push bx
                push cx
                push COLOR_F
                call Print_Frame
                add sp, 8d
                pop bx dx cx ax di

                push si di ax dx
                push offset registers
                push COLOR_S
                push cx
                call Print_String
                pop dx ax di si

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
                mov [di], al
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
;                                              <Pascal>                                                         ;
;;;;            Function "Print_String" prints string to video-memory                                        ;;;;
;                                                                                                               ;
;; Entry:       (SI) - the position of string from which string is printing                                    ;;
;               (AL) - color of string + back_ground                                                            ;
;               (CL) - len of printing string                                                                   ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;               DS = CS                                                                                         ;
;                                                                                                               ;
;                                                                                                               ;
;; Destroyed:   SI, DI, AX, DX                                                                                 ;;
;_______________________________________________________________________________________________________________;

Print_String            proc
                push bp
                mov bp, sp
			
		mov si, [bp + 8d]
                mov cx, [bp + 4d]

                mov ax, cx
                mov ah, 0
                add ax, MAX_STRING_LEN  ; 80-2-2 (2 = space, 2 = frame)
                xor dx, dx              
                mov bx, MAX_STRING_LEN  
                div bx                  ; ax = (cx + MAX_STRING_LEN - 1) / MAX_STRING_LEN - cnt rows
                mov bx, ax

                mov ax, [bp + 6d]
		mov ah, al

                push cx bx

                mov di, ROW_OFFSET_S + 2d*2d

        @@print_loop_all:
                cmp bx, 1
                ja @@print_all_row

                mov bx, ax
                mov ax, cx

                shr cx, 1d                      ; cx >> 1 - cx /= 2
                mov ax, 40d
                sub ax, cx                      ; ax = 40 - cx
                shl ax, 1                       ; ax = ax * 2
                add ax, di

                mov di, ax
                sub di, 2d*2d
                mov ax, bx

        @@print_loop:
                mov al, ds:[si]		; read symbol of string from PSP
                cmp al, 0Dh		; al == EOS or no
                je @@done       	; if (al == EOS) goto done
                
                mov es:[di], ax		; show symbol+attribute
                
                add di, 2		; di += 2
                inc si			; si++

                jmp @@print_loop


        @@print_all_row:
                push cx
                mov cx, MAX_STRING_LEN

        @@print_row:
                mov al, ds:[si]         ; read symbol of string from PSP
                mov es:[di], ax		; show symbol+attribute
                
                add di, 2d		; di += 2
                inc si	

                loop @@print_row

                pop cx
                sub cx, MAX_STRING_LEN
                dec bx
                add di, 4d*2d
                jmp @@print_loop_all

                        
        @@done:
                pop bx cx
                pop bp

		ret 6

                        endp



;_______________________________________________________________________________________________________________;
;                                          <CDECL>                                                              ;
;;;;            Function "Print_Frame" prints a frame around the string to video-memory                      ;;;;
;                                                                                                               ;
;; Entry:       (AH) - color of frame + back_groud                                                              ;
;               (CX) - len of string                                                                            ;
;               (BX) - cnt rows                                                                                 ;
;               (SI) - position from which start symbols for frame                                              ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;               DS = CS                                                                                         ;
;                                                                                                               ;
;; Destroyed:   DI, AX, CX, DX, BX                                                                             ;; 
;_______________________________________________________________________________________________________________;

Print_Frame             proc    color_of_frame, len_of_string, cnt_of_rows, start_pos

                mov ax, color_of_frame
                mov ah, al
                mov cx, len_of_string
                mov bx, cnt_of_rows
                mov si, start_pos

                cmp bx, 1d
                je @@small_frame
                
                mov di, ROW_OFFSET_F
                mov cx, SYMBS_IN_ROW-2d
                jmp @@print_frame

        @@small_frame:
                push ax
                mov di, cx
                shr cx, 1d                      ; cx >> 1
                mov ax, 38d
                sub ax, cx                      ; ax = 38 - cx
                shl ax, 1d                      ; ax = ax * 2
                add ax, ROW_OFFSET_F
                
                mov cx, di
                add cx, 2d
                mov di, ax
                pop ax


        @@print_frame:
                mov dx, di

                mov al, [si]
                stosw                           ; mov es:[di++], ax

                push cx
        @@print_top:
                mov al, [si + 1d]
                stosw
                loop @@print_top
                pop cx

                mov al, [si + 2d]
                stosw

                add dx, BYTES_IN_ROW
                mov di, dx
                add bx, 2d
                push cx                         ; in stack cnt symbs
                mov cx, bx                      ; cx = bx = cnt rows
        @@print_center:
                mov al, [si + 3d]       
                stosw                          

                pop bx                          ; bx = cnt symb
                push cx                         ; in stack cnt rows
                mov cx, bx                      ; cx = cnt symb
        @@print_middle:
                mov al, [si + 4d]
                stosw
                loop @@print_middle
                
                mov al, [si + 5d]
                mov es:[di], ax
                
                add dx, BYTES_IN_ROW
                mov di, dx
                pop cx                          ; cx = cnt rows
                push bx                         ; in stack cnt symb
                loop @@print_center
                
                pop cx
                mov al, [si + 6d]
                stosw                           ; mov es:[di++], ax
        @@print_down:
                mov al, [si + 7d]
                stosw
                loop @@print_down

                mov al, [si + 8d]
                stosw
                
                ret

                        endp



registers       db 'cs = 0000, ip = 0000, sp = 0000, ax = 0000, bx = 0000, cx = 0000, dx = 0000, si = 0000, di = 0000, bp = 0000, ss = 0000, ds = 0000, es = 0000', 0Dh

LEN_STRING      equ $ - registers

frame           db 0D5h, 0CDh, 0B8h, 0C6h, 02Eh, 0B5h, 0D4h, 0CDh, 0BEh

screen_buffer   db 160d * 6d dup (0)

end_my_interapt:


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