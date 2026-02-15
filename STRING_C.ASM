.model tiny
.code
org 100h


BYTES_ON_SYMB	equ 2d
SYMBS_IN_ROW	equ 80d
BYTES_IN_ROW    equ BYTES_ON_SYMB*SYMBS_IN_ROW
NUMBER_ROW	equ 5d
NUMBER_STOLB    equ 20d
COLOR		equ 84h
OFFSET_BYTES	equ BYTES_IN_ROW*NUMBER_ROW+BYTES_ON_SYMB*NUMBER_STOLB


Start:
		mov bx, es
		mov ds, bx              ; begin of PSP

		mov bx, 0b800h
		mov es, bx
		mov di, OFFSET_BYTES
		mov ah, COLOR

		mov cl, ds:[80h]	; len of command line
		cmp cl, 0		; cl == 0 or no
		je no_args		;
		
		mov si, 82h 		; arguments in PSP
		
	print_loop:
		mov al, ds:[si]		; read args from PSP
		cmp al, 0Dh		; end or no?
		je done			; if end: go done
		mov es:[di], ax
		add di, 2		; di += 2
		inc si			; si++
		jmp print_loop

	done: 
		mov ax, 4c00h
		int 21h

	no_args:
		mov cx, cs
		mov ds, cx

		mov si, offset my_message
		mov cx, LEN_DATA
		
	my_print_loop:
		lodsb			; mov al, ds:[si++]
		stosw			; mov es:[di++], ax
		loop my_print_loop
		
		mov ax, 4c00h
		int 21h


my_message	db 'You beautiful, but where message?'		
LEN_DATA	equ $ - my_message


end Start
		







		





end Start