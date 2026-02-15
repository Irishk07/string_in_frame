.model tiny
.code
org 100h


BYTES_ON_SYMB   equ 2d
SYMB_IN_ROW     equ 80d
BYTES_IN_ROW    equ BYTES_ON_SYMB*SYMB_IN_ROW
NUMBER_ROW      equ 5d 
COLOR           equ 8403h

Start:

 	   mov bx, 0b800h		   ; bx = 0b800h
	   mov es, bx		           ; es = 0b800h
	   mov bx, BYTES_IN_ROW*NUMBER_ROW ; bx = 2*80*5
		
	   mov cx, SYMB_IN_ROW         ; cx = 80d

     video_loop:		       ; while cx != 0
	   mov es:[bx], COLOR          ; [bx] = 8403h
	   add bx, BYTES_ON_SYMB       ; bx += 2
	   loop video_loop

	   mov ax, 4c00h
	   int 21h


end Start