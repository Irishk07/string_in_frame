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

COLOR_S		equ 0F4h
COLOR_F		equ 0Fh

FRAME_LEFT	equ 0C6h
FRAME_RIGHT	equ 0B5h
FRAME_TOP	equ 0CDh
FRAME_DOWN	equ 0CDh 
FRAME_L_T	equ 0D5h
FRAME_R_T	equ 0B8h
FRAME_L_D	equ 0D4h
FRAME_R_D	equ 0BEh 

BACK_COLOR      equ 005h
BACK_0          equ 0B0h
BACK_1          equ 0B1h
BACK_2          equ 0B2h
BACK_3          equ 0DBh


Start:          call Main
	        mov ax, 4c00h
	        int 21h 


Main                    proc 

                mov bx, cs
                mov ds, bx

                mov bx, 0b800h
                mov es, bx


                mov ah, BACK_COLOR
                mov di, 0d
                call Paint_Back

        
        @@read_first_attribute:
                mov bx, 0
                mov si, 82h                     ; first symbol of command line

                push bx
                call Atoi_byte                  ; ax = color of string
                pop bx

                cmp al, -1d
                je @@no_first_attribute

                add si, 2d                      ; si = first symbol of string (skip '*_ '), '*' already skipped
                mov bl, 3d                      ; cnt skip symbols ('__ ')

        @@read_second_attribute:
                push ax
                push bx

                call Atoi_byte

                pop bx
                mov dx, ax                      ; dx = color of frame
                pop ax

                cmp dl, -1d
                je @@no_second_attribute
                
                add si, 2d                      ; si = first symbol of string (skip '*_ '), '*' already skipped
                add bl, 3d                      ; cnt skip symbols ('__ ')
                                       
                jmp @@check_len_string

        @@no_first_attribute:
                mov al, COLOR_S 
                mov dl, COLOR_F
                mov si, 82h
                jmp @@check_len_string

        @@no_second_attribute:
                mov dl, COLOR_F 
                mov si, 82h
                add si, bx                     ; cnt skip symbols
                jmp @@check_len_string

        
        @@check_len_string:
                mov cl, ds:[80h]	        ; len of command line (from PSP)
	        cmp cl, 0d		        ; cl == 0 or no
	        jne @@with_args		        ; if (cl != 0) goto with_args 	

        @@no_args:
		mov si, offset my_message
		mov cx, LEN_MY_MESSAGE
                mov di, BYTES_OFFSET_S

                push si
                push di
                push ax
                push cx
                call Print_My_Message

                mov di, BYTES_OFFSET_F
                jmp @@print_frame
    

        @@with_args:
                dec cl                          ; skip first space
                sub cl, bl                      ; skip symbols

                push dx
                push cx
                push ax
                push si
                call Print_String
                add sp, 6d                      ; 3 arguments
                pop dx

                jmp @@print_frame
                
        
        @@print_frame:
                mov ah, dl
                call Print_Frame

	        ret

                        endp




;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Atoi_byte" converts a byte (with two symbols) to a number                          ;;;;
;                                                                                                               ;
;; Entry:       SI - the position of the byte                                                                  ;;
;                                                                                                               ;
;; Exit:        AL - number (if OK), in error Al = -1                                                          ;;
;                                                                                                               ;
;; Expected:    DS = CS                                                                                         ;
;                                                                                                               ;
;; Destroyed:   BX, SI                                                                                         ;;
;_______________________________________________________________________________________________________________;

Atoi_byte               proc
                mov al, ds:[si]

                call Read_hex_number
                cmp al, -1
                je @@error

                mov bl, al
                shl bl, 4               ; bl = al *16

                inc si
                mov al, ds:[si]

                call Read_hex_number
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
;;;;            Function "Read_hex_number" converts symbol to a number  (hex)                                ;;;;
;                                                                                                               ;
;; Entry:       AL - symbol                                                                                    ;;
;                                                                                                               ;
;; Exit:        AL - number (if OK), in error Al = -1                                                          ;;
;                                                                                                               ;
;; Expected:                                                                                                    ;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

Read_hex_number         proc

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



;_______________________________________________________________________________________________________________;
;                                              <CDECL>                                                          ;
;;;;            Function "Print_String" prints string to video-memory from commang line                      ;;;;
;                                                                                                               ;
;; Entry:       (SI) - the position of string from which string is printing                                    ;;
;               (AL) - color of string + back_groud                                                             ;
;               (CL) - len of printing string                                                                   ;
;                                                                                                               ;
;; Exit:        BX - cnt rows                                                                                  ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;               DS = CS                                                                                         ;
;                                                                                                               ;
;                                                                                                               ;
;; Destroyed:   SI, DI, AX, DX                                                                                 ;;
;_______________________________________________________________________________________________________________;

Print_String            proc        pointer_on_string, color, len_of_string
			
		mov si, pointer_on_string
                mov cx, len_of_string

                mov ax, cx
                add ax, MAX_STRING_LEN  ; 80-2-2-1 (2 = space, 2 = frame)
                xor dx, dx              
                mov bx, MAX_STRING_LEN  
                div bx                  ; ax = (cx + MAX_STRING_LEN - 1) / MAX_STRING_LEN - cnt rows
                mov bx, ax

                mov ax, color
		mov ah, al

                push cx
                push bx

                mov di, ROW_OFFSET_S + 2d*2d

        @@print_loop_all:
                cmp bx, 1
                ja @@print_all_row

                mov bx, ax
                mov ax, cx

                shr cx, 1d                      ; cx >> 1
                mov ax, 40d
                sub ax, cx                      ; ax = 40 - cx
                mov cx, BYTES_ON_SYMB           ; cx = 2
                push dx
                mul cx                          ; ax = ax * cx
                pop dx
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
                pop bx
                pop cx

		ret

                        endp



;_______________________________________________________________________________________________________________;
;                                          <Pascal>                                                             ;
;;;;            Function "Print_My_Message" prints default string (my_message) to video-memory               ;;;;
;                                                                                                               ;
;; Entry:       (SI) - the position of string from which string is printing                                    ;;
;               (DI) - the position of segment video-memory from which we start printing into the video memory  ;     
;               (AL) - color of string + back_groud                                                             ;
;               (CX) - len of printing string                                                                   ;
;                                                                                                               ;
;; Exit:        CX - len of printing string                                                                    ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;               DS = CS                                                                                         ;
;                                                                                                               ;
;; Destroyed:   SI, DI, AX                                                                                     ;; 
;_______________________________________________________________________________________________________________;

Print_My_Message        proc

                push bp
                mov bp, sp

                mov si, [bp + 10d]      ; pointer_on_string
                mov di, [bp + 8d]       ; pointer_on_vm
                mov ax, [bp + 6d]       ; color
                mov ah, al
                mov cx, [bp + 4d]       ; len_of_string

        @@print_loop:		        ; while (cx != 0)
		lodsb			; mov al, ds:[si++]
		stosw			; mov es:[di++], ax
		loop @@print_loop       ; cx--
		
                mov cx, [bp + 4d]

                pop bp
                ret 8

                        endp



;_______________________________________________________________________________________________________________;
;                                          <STD call>                                                           ;
;;;;            Function "Print_Frame" prints a frame around the string to video-memory                      ;;;;
;                                                                                                               ;
;; Entry:       AH - color of frame + back_groud                                                                ;
;               CX - len of string                                                                              ;
;               BX - cnt rows                                                                                   ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;               DS = CS                                                                                         ;
;                                                                                                               ;
;; Destroyed:   DI, AX, CX, DX, BX, SI                                                                         ;; 
;_______________________________________________________________________________________________________________;

Print_Frame             proc

                cmp bx, 1
                ja @@big_frame 


                mov di, cx
                shr cx, 1d                      ; cx >> 1
                mov ax, 38d
                sub ax, cx                      ; ax = 38 - cx
                mov cx, BYTES_ON_SYMB           ; cx = 2
                mul cx                          ; ax = ax * cx = ax * 2
                add ax, ROW_OFFSET_F
                
                mov cx, di
                mov di, ax

                mov si, di
                mov dx, cx


		mov al, FRAME_L_T
		mov es:[di], ax		        ; draw left-top corner
		add di, 2d
		

		add cx, 2d
		mov al, FRAME_TOP

	@@print_top:		
		mov es:[di], ax		        ; draw top
		add di, 2d
		loop @@print_top
		

		mov bx, BYTES_IN_ROW
		mov al, FRAME_R_T
		mov es:[di], ax			; draw right-top corner
		lea di, [bx + si]
		add bx, BYTES_IN_ROW	


		mov cx, 3d

	@@print_columns:	                ; while (cx != 0)
		mov al, FRAME_LEFT	
		mov es:[di], ax		        ; draw left column
		add di, dx	
		add di, dx
		add di, 3d*2d		        ; skip message + 2 spaces + left symb
		mov al, FRAME_RIGHT
		mov es:[di], ax		        ; draw right column
		lea di, [bx + si]
		add bx, BYTES_IN_ROW
		loop @@print_columns


		mov al, FRAME_L_D
		mov es:[di], ax		        ; draw left-down corner
		add di, 2d
		

		mov cx, dx
		add cx, 2d		        ; cx = len of ' message '
		mov al, FRAME_DOWN

	@@print_down:		                ; while (cx != 0)
		mov es:[di], ax                 ; draw down
		add di, 2d
		loop @@print_down


		mov al, FRAME_R_D
		mov es:[di], ax		        ; draw right-down corner

                jmp @@done


        @@big_frame:
                call Print_Big_Frame


        @@done:
                ret

        

                        endp



;_______________________________________________________________________________________________________________;
;                                          <STD call>                                                           ;
;;;;            Function "Print_Big_Frame" prints a big frame around the string to video-memory              ;;;;
;                                                                                                               ;
;; Entry:       AH - color of frame + back_groud                                                                ;
;               BX - cnt rows                                                                                   ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;               DS = CS                                                                                         ;
;                                                                                                               ;
;; Destroyed:   DI, AX, CX, DX, BX, SI                                                                         ;; 
;_______________________________________________________________________________________________________________;

Print_Big_Frame         proc

                mov di, ROW_OFFSET_F
                mov si, di

                mov dx, bx


		mov al, FRAME_L_T
		mov es:[di], ax		        ; draw left-top corner
		add di, 2d

                mov cx, SYMBS_IN_ROW-2d       ; cx = 78d
		mov al, FRAME_TOP

	@@print_top:		
		mov es:[di], ax		        ; draw top
		add di, 2d
		loop @@print_top
		

		mov bx, BYTES_IN_ROW
		mov al, FRAME_R_T
		mov es:[di], ax			; draw right-top corner
		lea di, [bx + si]
		add bx, BYTES_IN_ROW	


		mov cx, dx
                add cx, 2

	@@print_columns:	                ; while (cx != 0)
		mov al, FRAME_LEFT	
		mov es:[di], ax		        ; draw left column
		add di, BYTES_IN_ROW - 1d*2d    ; di += 79d
		mov al, FRAME_RIGHT
		mov es:[di], ax		        ; draw right column
		lea di, [bx + si]
		add bx, BYTES_IN_ROW
		loop @@print_columns


		mov al, FRAME_L_D
		mov es:[di], ax		        ; draw left-down corner
		add di, 2d
		

		mov cx, SYMBS_IN_ROW-2d        ; cx = 78d
		mov al, FRAME_DOWN

	@@print_down:		                ; while (cx != 0)
		mov es:[di], ax                 ; draw down
		add di, 2d
		loop @@print_down


		mov al, FRAME_R_D
		mov es:[di], ax		        ; draw right-down corner

                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                          <STD call>                                                           ;
;;;;            Function "Paint_Back" paints the background (4 blocks 6*80)                                  ;;;;
;                                                                                                               ;
;; Entry:       DI - the position of segment video-memory from which we start printing into the video memory    ;
;               AH - color of back                                                                              ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;                                                                                                               ;
;; Destroyed:   DI, AX, CX, DX, SI                                                                             ;; 
;_______________________________________________________________________________________________________________;

Paint_Back              proc

                mov al, BACK_0
                mov cx, 7d * SYMBS_IN_ROW       ; cx = 80*7
                mov si, cx
                sub si, SYMBS_IN_ROW            ; si = 80*6
                mov dx, 4d                      ; dx - cnt blocks


        @@print_loop:

        @@print_one_back:
                mov es:[di], ax		        
		add di, 2d

                loop @@print_one_back

                dec dx
                cmp dx, 0d
                je @@done

                mov cx, si                      ; cx = 2*80*6
                jmp @@choose_back_1

        @@choose_back_1:
                cmp dx, 3d
                jne @@choose_back_2
                mov al, BACK_1
                jmp @@print_loop

        @@choose_back_2:
                cmp dx, 2d
                jne @@choose_back_3
                mov al, BACK_2
                jmp @@print_loop

        @@choose_back_3:
                mov al, BACK_3
                jmp @@print_loop


        @@done:
                ret  

                        endp


my_message	db 'You are beautiful, but where is the message?'
LEN_MY_MESSAGE	equ $ - my_message


end 		Start