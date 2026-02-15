.model tiny
.code
org 100h


BYTES_ON_SYMB	equ 2d
SYMBS_IN_ROW	equ 80d
BYTES_IN_ROW	equ BYTES_ON_SYMB*SYMBS_IN_ROW

NUMBER_ROW_F	equ 5d
NUMBER_ROW_S    equ 7d

NUMBER_STOLB_F  equ 2d
NUMBER_STOLB_S  equ 4d

BYTES_OFFSET_F	equ BYTES_IN_ROW*NUMBER_ROW_F+BYTES_ON_SYMB*NUMBER_STOLB_F
BYTES_OFFSET_S	equ BYTES_IN_ROW*NUMBER_ROW_S+BYTES_ON_SYMB*NUMBER_STOLB_S

COLOR_S		equ 0F4h
COLOR_F		equ 0Fh

FRAME_LEFT	equ 0C6h
FRAME_RIGHT	equ 0B5h
FRAME_TOP	equ 0D1h
FRAME_DOWN	equ 0CFh 
FRAME_L_T	equ 0D5h
FRAME_R_T	equ 0B8h
FRAME_L_D	equ 0D4h
FRAME_R_D	equ 0BEh 


Start:

		mov bx, es
		mov ds, bx
		
		mov bx, 0b800h
		mov es, bx

		mov ah, COLOR_S
		mov di, BYTES_OFFSET_S

		mov cl, ds:[80h]	; len of command line (from PSP)
		cmp cl, 0		; cl == 0 or no
		je no_args		; if (cl == 0) goto no_args 	

		mov si, 82h		; first symbol of string 
	
	print_string:
		mov al, ds:[si]		; read symbol of string from PSP
		cmp al, 0Dh		; al == EOS or no
		je done			; if (al == EOS) goto done
		
		mov es:[di], ax		; show symbol+attribute
		
		add di, 2		; di += 2
		inc si			; si++

		jmp print_string		

	done:
		mov cl, ds:[80h]
		dec cl
		jmp print_frame

	no_args:
		mov cx, cs
		mov ds, cx 		

		mov si, offset my_message
		mov cx, LEN_MY_MESSAGE

	print_my_message:		; while (cx != 0)
		lodsb			; mov al, ds:[si++]
		stosw			; mov es:[di++], ax
		loop print_my_message	; cx--
		
		mov cx, LEN_MY_MESSAGE

	print_frame:
		mov di, BYTES_OFFSET_F
		mov ah, COLOR_F

		mov dx, cx		; bx = len of message		
	
		mov al, FRAME_L_T
		mov es:[di], ax		; draw left-top corner
		add di, 2d
		
		add cx, 2d
		mov al, FRAME_TOP
	print_top:		
		mov es:[di], ax		; draw top
		add di, 2d
		loop print_top
		
		mov bx, BYTES_IN_ROW
		mov al, FRAME_R_T
		mov es:[di], ax			; draw right-top corner
		lea di, [bx+BYTES_OFFSET_F]
		add bx, BYTES_IN_ROW	

		mov cx, 3d
	print_columns:	 		; while (cx != 0)
		mov al, FRAME_LEFT	
		mov es:[di], ax		; draw left column
		add di, dx	
		add di, dx
		add di, 3d*2d		; skip message + 2 spaces + left symb
		mov al, FRAME_RIGHT
		mov es:[di], ax		; draw right column
		lea di, [bx+BYTES_OFFSET_F]
		add bx, BYTES_IN_ROW
		loop print_columns

		mov al, FRAME_L_D
		mov es:[di], ax		; draw left-down corner
		add di, 2d
		
		mov cx, dx
		add cx, 2d		; cx = len of ' message '
		mov al, FRAME_DOWN
	print_down:		; while (cx != 0)
		mov es:[di], ax ; draw down
		add di, 2d
		loop print_down	

		mov al, FRAME_R_D
		mov es:[di], ax		; draw right-down corner
		
		mov ax, 4c00h
		int 21h


my_message	db 'You are beautiful, but where is the message?'
LEN_MY_MESSAGE	equ $ - my_message

							
end Start
