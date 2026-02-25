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
COLOR_F		equ 0Ch

BACK_COLOR      equ 005h
BACK_0          equ 0B0h
BACK_1          equ 0B1h
BACK_2          equ 0B2h
BACK_3          equ 0DBh

PSP_LEN_COMMAND_LINE    equ 80h
FIRST_SYMB_COMMAND_LINE equ 82h


Start:          call Main
	        mov ax, 4c00h
	        int 21h 


Main                    proc 

                mov bx, cs
                mov ds, bx
                mov bx, 0b800h
                mov es, bx


                mov si, FIRST_SYMB_COMMAND_LINE ; first symbol in command line
                call Read_attributes


                push ax cx
                cmp ch, -1d
                je @@no_color_of_back
                mov ah, ch
                jmp @@paint_background
        @@no_color_of_back:
                mov ah, BACK_COLOR
        @@paint_background:
                push dx si
                mov di, 0d
                call Paint_Back
                pop si dx cx ax
                

                push cx
                mov ch, 0
                xor di, di
                mov di, cx                      ; save number of frame
                pop cx
                call Check_attributes
                push bx
                push cx

        @@check_len_string:
                xor cx, cx
                mov cl, ds:[PSP_LEN_COMMAND_LINE]	        
	        cmp cl, 0d		        ; cl == 0 or no
                je @@default_params

                dec cl
                sub cl, bl
                cmp di, 0
                jne @@user_params
                sub cl, 9d + 1d                 ; 9 symbs for frame + space   
        @@user_params:
                push ax
                mov ax, cx
                mov ah, 0
                add ax, MAX_STRING_LEN
                push dx
                xor dx, dx
                mov bx, MAX_STRING_LEN
                div bx
                mov bx, ax
                pop dx
                pop ax
                jmp @@print_frame

        @@default_params:
                mov cx, LEN_MY_MESSAGE
                mov bx, 1

        @@print_frame:
                pop si
                push di ax cx dx bx             ; save       

                mov ah, dl
                push si bx cx ax                ; args for func
                call Print_Frame
                add sp, 8d                      ; 4 arguments 

                pop bx dx cx ax di
                pop si
                add si, FIRST_SYMB_COMMAND_LINE
                cmp di, 0
                jne @@start_print_string
                add si, 9d + 1d                 ; 9 symbs for frame + space 
        

        @@start_print_string:
                push ax
                xor ax, ax
                mov al, ds:[PSP_LEN_COMMAND_LINE]	       
	        cmp al, 0d		        ; cl == 0 or no
	        jne @@with_args		        ; if (cl != 0) goto with_args 	

        @@no_args:
                pop ax
		mov si, offset my_message
		mov cx, LEN_MY_MESSAGE
                mov di, BYTES_OFFSET_S

                call Print_My_Message

                mov di, BYTES_OFFSET_F
                jmp @@done    

        @@with_args:
                pop ax
                push dx si ax cx
                call Print_String
                pop dx

        @@done:
	        ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Read_attributes" reads first, second, third and fourth (if there is) attributes    ;;;;
;                                                                                                               ;
;; Entry:       SI - the position from which start to read                                                     ;;
;                                                                                                               ;
;; Exit:        AL - first (-1 if not)                                                                         ;;
;               DL - second (-1 if not)                                                                         ;
;               CH - third (-1 if not)                                                                          ;
;               CL - fourth (-1 if not)                                                                         ;
;               BL - cnt bytes on attributes                                                                    ;
;                                                                                                               ;
;; Expected:    DS = CS                                                                                        ;;
;                                                                                                               ;
;; Destroyed:   SI                                                                                             ;;
;_______________________________________________________________________________________________________________;

Read_attributes         proc

                mov ax, 00FFh
                xor bx, bx
                mov cx, -1d
                mov dx, 00FFh

        @@read_color_of_string:
                push bx
                call Atoi_byte                  ; ax = color of string
                pop bx

                cmp al, -1d
                je @@done

                add si, 2d                      ; si = first symbol of string (skip '*_ '), '*' already skipped
                mov bl, 3d                      ; cnt skip symbols ('__ ')

        @@read_color_of_frame:          
                push ax bx
                call Atoi_byte
                mov dl, al                      ; dl = color of frame
                pop bx ax

                cmp dl, -1d
                je @@done
                
                add si, 2d                      ; si = first symbol of string (skip '*_ '), '*' already skipped
                add bl, 3d                      ; cnt skip symbols ('__ ')

        @@read_color_of_back:             
                push ax bx
                call Atoi_byte
                mov ch, al
                pop bx ax

                cmp ch, -1d
                je @@done

                add si, 2d                      ; si = first symbol of string (skip '*_ '), '*' already skipped
                add bl, 3d                      ; cnt skip symbols ('__ ')        

        @@read_number_of_frame:                  
                push ax
                mov al, ds:[si]
                call Atoi_char
                mov cl, al
                pop ax 

                cmp cl, -1d
                je @@done

                add si, 2d                      ; si = first symbol of string (skip '_ ')
                add bl, 2d                      ; cnt skip symbols ('_ ')

        @@done:
                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Check_attributes" check first, second, third and fourth (if there is) attributes   ;;;;
;                                                                                                               ;
;; Entry:       AL - first attribute                                                                           ;;
;               DL - second attribute                                                                           ;
;               CH - third attribute                                                                            ;
;               CL - fourth attribute                                                                           ;    
;                                                                                                               ;
;; Exit:        CX - addres of frame, SI - first symbol of string in command line                              ;;
;                                                                                                               ;
;; Expected:    DS = CS                                                                                        ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

Check_attributes        proc

                cmp al, -1d                     
                je @@no_color_of_string
                cmp dl, -1d                     
                je @@no_color_of_frame
                cmp ch, -1d                     
                je @@no_color_of_background
                cmp cl, -1d                     
                je @@no_number_of_frame
                call Choose_frame
                jmp @@done

        @@no_color_of_string:
                mov al, COLOR_S 
                mov dl, COLOR_F
                mov cx, offset frame_3
                mov si, 82h
                jmp @@done

        @@no_color_of_frame:
                mov dl, COLOR_F 
                mov cx, offset frame_3
                mov si, 82h
                add si, bx                      ; cnt skip symbols
                jmp @@done

        @@no_color_of_background:
        @@no_number_of_frame:
                mov cx, offset frame_3
                mov si, 82h
                add si, bx                      ; cnt skip symbols
                jmp @@done

        @@done:
                ret

                        endp



;_______________________________________________________________________________________________________________;
;                                              <STD call>                                                       ;
;;;;            Function "Choose_frame" mov cx addres of choosing frame                                       ;;;;
;                                                                                                               ;
;; Entry:       CL - number of frame                                                                           ;;
;                                                                                                               ;
;; Exit:        CX - addres of frame                                                                           ;;
;                                                                                                               ;
;; Expected:                                                                                                   ;;
;                                                                                                               ;
;; Destroyed:                                                                                                  ;;
;_______________________________________________________________________________________________________________;

Choose_frame             proc

                cmp cl, 0
                je @@Choose_frame_user
                cmp cl, 3d
                ja @@default_frame

                mov ch, 0
                dec cl
                push ax
                mov al, cl
                shl cl, 3d
                add cl, al                              ; (cl - 1) * 9
                pop ax
                add cx, offset frame_1
                jmp @@done

        @@Choose_frame_user:
                cmp cl, 0
                jne @@default_frame
                mov cx, si
                jmp @@done

        @@default_frame:
                mov cx, offset frame_3

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



;_______________________________________________________________________________________________________________;
;                                              <Pascal>                                                         ;
;;;;            Function "Print_String" prints string to video-memory from command line                      ;;;;
;                                                                                                               ;
;; Entry:       (SI) - the position of string from which string is printing                                    ;;
;               (AL) - color of string + back_ground                                                            ;
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


; // TODO: remake
;_______________________________________________________________________________________________________________;
;                                          <STD call>                                                           ;
;;;;            Function "Print_My_Message" prints default string (my_message) to video-memory               ;;;;
;                                                                                                               ;
;; Entry:       SI - the position of string from which string is printing                                      ;;
;               DI - the position of segment video-memory from which we start printing into the video memory    ;     
;               AL - color of string + back_groud                                                               ;
;               CX - len of printing string                                                                     ;
;                                                                                                               ;
;; Exit:                                                                                                       ;;
;                                                                                                               ;
;; Expected:    ES = 0b800h (segment of video-memory)                                                          ;;
;               DS = CS                                                                                         ;
;                                                                                                               ;
;; Destroyed:   SI, DI, AX, CX                                                                                 ;; 
;_______________________________________________________________________________________________________________;

Print_My_Message        proc
                mov ah, al

        @@print_loop:		        ; while (cx != 0)
		lodsb			; mov al, ds:[si++]
		stosw			; mov es:[di++], ax
		loop @@print_loop       ; cx--
		

                ret

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

Print_Frame             proc    color_of_frame, len_string, cnt_of_rows, start_pos

                mov ax, color_of_frame
                mov cx, len_string
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
        @@print_top: ; TODO macro
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
;; Destroyed:   DI, AX, CX, SI                                                                                 ;; 
;_______________________________________________________________________________________________________________;

PRINT_ONE_BACK          macro code
        LOCAL   print_one_back

        print_one_back:
                mov es:[di], ax		        
		add di, 2d

                loop print_one_back

                mov cx, si 
                        endm

Paint_Back              proc

                mov cx, 7d * SYMBS_IN_ROW       ; cx = 80*7
                mov si, cx
                sub si, SYMBS_IN_ROW            ; si = 80*6

                mov al, BACK_0
                PRINT_ONE_BACK

       
                mov al, BACK_1
                PRINT_ONE_BACK

                mov al, BACK_2
                PRINT_ONE_BACK

                mov al, BACK_3
                PRINT_ONE_BACK

                ret  

                        endp


my_message	db 'You are beautiful, but where is the message?'
LEN_MY_MESSAGE	equ $ - my_message

frame_1         db 0D5h, 0CDh, 0B8h, 0C6h, 02Eh, 0B5h, 0D4h, 0CDh, 0BEh
frame_2         db 0DAh, 0C4h, 0BFh, 0B3h, 02Eh, 0B3h, 0C0h, 0C4h, 0D9h
frame_3         db 003h, 003h, 003h, 004h, 003h, 004h, 003h, 003h, 003h


end 		Start