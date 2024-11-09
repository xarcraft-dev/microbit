;;;
;;; Simple Boot Sector That Prints Characters Using BIOS Interrupts
;;;

org 0x7c00                  ; 'Origin' of Boot Code; Helps Make Sure Addresses Don't Change

;; Set Video Mode
mov ah, 0x00                ; int 0x10 / ah 0x00 = Set Video Mode
mov al, 0x03
int 0x10

;; Change Color / Palette
mov ah, 0x0B
mov bh, 0x00
mov bl, 0x01
int 0x10

;; Teletype Output Strings
mov bx, version             ; Moving Memory Address at 'string' Into BX Register

call print_string           ; Prints String In BX
mov bx, hex_test
call print_string

mov dx, 0x12AB              ; Sample Hex Number
call print_hex

;; End pgn
jmp $                       ; Keep Jumping to Here; Neverending Loop

;; Included Files
include 'print_string.asm'
include 'print_hex.asm'

;; Variables
version: db 0xA, 0xD, '  [Microbit Version 0.1.0-pre2]', 0xA, 0xD, 0
hex_test: db '  Hex Test: ', 0

;; Boot Sector Magic
times 510-($-$$) db 0       ; Pad File With 0s Until 510th Byte

dw 0xaa55                   ; BIOS Magic Number in 511th and 512th Byte