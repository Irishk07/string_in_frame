.model tiny
.code
org 100h


BYTES_ON_SYMB       equ 2d
SYMB_IN_ROW         equ 80d
BYTES_IN_ROW        equ BYTES_ON_SYMB*SYMB_IN_ROW
CNT_ROWS            equ 20d
NUM_STOLB           equ 20d
NUM_ROW             equ 5d
COLOR	            equ 8403h


Start:

		mov bx, 0b800h 		          ; bx = 0b800h
		mov es, bx		          ; es = 0b800h
		mov bx, NUM_STOLB*BYTES_ON_SYMB   ; bx = 20*2
		add bx, NUM_ROW*BYTES_IN_ROW      ; bx += 5*160

		mov cx, CNT_ROWS                  ; cx = 10
	
	video_loop:		   		  ; while cx != 0
		mov es:[bx], COLOR 		  ; [bx] = 8403h
		add bx, BYTES_ON_SYMB*SYMB_IN_ROW ; bx += 2*80
		loop video_loop

		mov ax, 4c00h
		int 21h

end Start 