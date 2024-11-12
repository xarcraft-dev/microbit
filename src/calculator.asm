call resetTextScreen

mov si, testMsg
call print_string

mov ah, 0x00
int 0x16

mov ax, 0x2000
mov es, ax
xor bx, bx              ; ES:BX -> 0x2000:0x0000

mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
jmp 0x2000:0x0000       ; Far Jump Back To Kernel

;; Included Files
include "utilities/print_string.asm"
include "screen/resetTextScreen.asm"

testMsg:        db 'Program Loaded!', 0

times 512-($-$$) db 0   ; Pad Out To 1 Sector