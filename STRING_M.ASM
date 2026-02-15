.model tiny
.code
org 100h


BYTES_ON_SYMB   equ 2d
SYMB_IN_ROW	equ 80d
BYTES_IN_ROW	equ BYTES_ON_SYMB*SYMB_IN_ROW
NUMBER_ROW      equ 5d
NUMBER_STOLB    equ 20d
COLOR           equ 84h


Start:

		mov bx, 0b800h                     ; bx = 0b800h
		mov es, bx                         ; es = 0b800h
		
		mov di, BYTES_IN_ROW*NUMBER_ROW    ; di = 2*80*5
		add di, BYTES_ON_SYMB*NUMBER_STOLB ; di += 2*20

		mov ax, cs
		mov ds, ax 			   ; ds - pointer on code segment
		mov si, offset Data

		mov ah, COLOR                      ; ah = COLOR
		mov cx, LEN_DATA 	

	print_loop:			           ; while (cx != 0)
		lodsb                              ; mov al, ds:[si++]
		stosw				   ; mov es:[di++], ax
		loop print_loop			   ; cx -= 1

		mov ax, 4c00h			   
		int 21h		


Data		db 'I love you!'
LEN_DATA        equ $ - Data


end Start









