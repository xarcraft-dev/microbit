; calculator.asm: simple calculator program

call resetTextScreen

mov si, calcMsg
call print_string

; get first number
mov si, firstPrompt
call print_string
call read_number
mov [num1], ax

; get operator
mov si, opPrompt
call print_string
mov ah,0x00
int 0x16
mov [operator], al
; echo character
mov ah,0x0e
int 0x10
mov al,0xA
int 0x10
mov al,0xD
int 0x10

; get second number
mov si, secondPrompt
call print_string
call read_number
mov [num2], ax

; compute result
mov ax, [num1]
mov bl, [operator]
cmp bl,'+'
je add_op
cmp bl,'-'
je sub_op
cmp bl,'*'
je mul_op
cmp bl,'/'
je div_op
jmp invalid_op

add_op:
    add ax, [num2]
    jmp show_result
sub_op:
    sub ax, [num2]
    jmp show_result
mul_op:
    mov bx, [num2]
    mul bx                ; AX=AX*BX
    jmp show_result
div_op:
    mov bx, [num2]
    xor dx, dx
    div bx                ; AX=quotient
    jmp show_result
invalid_op:
    mov si, invalidMsg
    call print_string
    jmp wait_key

show_result:
    mov [result], ax
    mov si, resultMsg
    call print_string
    mov ax, [result]
    call print_dec
    mov al,0xA
    mov ah,0x0e
    int 0x10
    mov al,0xD
    int 0x10

wait_key:
    mov si, exitMsg
    call print_string
    mov ah,0x00
    int 0x16

; return to kernel
mov ax,0x2000
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ss,ax
jmp 0x2000:0x0000

; ====================
; routines
; ====================
read_number:
    xor bx,bx              ; result in BX
read_loop:
    mov ah,0x00
    int 0x16
    cmp al,0x0D
    je end_read
    mov dl,al              ; save char to echo
    sub al,'0'
    cmp al,9
    ja read_loop
    ; BX = BX*10 + AL
    push ax
    mov ax,bx
    shl ax,1               ;*2
    mov cx,bx
    shl cx,3               ;*8
    add ax,cx              ;*10
    pop cx                 ;digit
    add ax,cx
    mov bx,ax
    ; echo char
    mov ah,0x0e
    mov al,dl
    int 0x10
    jmp read_loop
end_read:
    ; newline after enter
    mov ah,0x0e
    mov al,0xA
    int 0x10
    mov al,0xD
    int 0x10
    mov ax,bx
    ret

print_dec:
    pusha
    mov cx,0
    mov bx,10
    cmp ax,0
    jne dec_loop
    mov dl,'0'
    mov ah,0x0e
    int 0x10
    jmp dec_done
dec_loop:
    xor dx,dx
    div bx
    add dl,'0'
    push dx
    inc cx
    cmp ax,0
    jne dec_loop
print_loop:
    pop dx
    mov ah,0x0e
    mov al,dl
    int 0x10
    loop print_loop
dec_done:
    popa
    ret

; ====================
; data
; ====================
calcMsg:        db 0xA,0xD,'  Simple Calculator',0xA,0xD,0
firstPrompt:    db '  Enter first number: ',0
opPrompt:       db '  Operation (+ - * /): ',0
secondPrompt:   db '  Enter second number: ',0
resultMsg:      db '  Result: ',0
invalidMsg:     db '  Invalid operator',0xA,0xD,0
exitMsg:        db '  Press any key to return...',0
num1:           dw 0
num2:           dw 0
result:         dw 0
operator:       db 0

include "utilities/print_string.asm"
include "screen/resetTextScreen.asm"

; pad to 1 sector
 times 512-($-$$) db 0
