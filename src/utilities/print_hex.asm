;;;
;;; Prints Hexadecimal Values Using Register DX and 'print_string.asm'
;;;
;;; ASCII '0' - '9' = hex 0x30 - 0x39
;;; ASCII 'A' - 'F' = hex 0x41 - 0x46
;;; ASCII 'a' - 'f' = hex 0x61 - 0x66
;;;

print_hex:
    pusha                       ; Save All Registers To The Stack
    mov cx, 0                   ; Initialize Loop Counter

hex_loop:
    cmp cx, 4                   ; Compare Loop Counter With 4
    je end_hexloop              ; Jump If Equal To 'end_hexloop'

    ;; Convert DX Hex Values To ASCII
    mov ax, dx
    and ax, 0x000F              ; Turn First 3 Hex To 0, Keep Final Digit To Convert
    add al, 0x30                ; Get ASCII Number Or Letter Value
    cmp al, 0x39                ; Is Hex Value 0-9 (<= 0x39) or A-F (> 0x39)
    jle move_into_BX
    add al, 0x7                 ; To Get ASCII 'A'-'F'

move_into_BX:
    ;; Move ASCII Char Into BX String
    mov bx, hexString + 5       ; Base Address Of 'hexString' + Length Of String
    sub bx, cx                  ; Subtract Loop Counter
    mov [bx], al
    ror dx, 4                   ; Rotate Right By 4 Bits;
                                ; 0x12AB -> 0xB12A -> 0xAB12 -> 0x2AB1 -> 0x12AB
    add cx, 1                   ; Increment Counter
    jmp hex_loop                ; Loop For Next Hex Digit In BX

end_hexloop:
    mov bx, hexString
    call print_string

    popa                        ; Restore All Registers From The Stack
    ret                         ; Return To Caller

;; Data
hexString: db '0x0000', 0